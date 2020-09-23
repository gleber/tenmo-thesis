--
-- PostgreSQL database dump
--

-- Dumped from database version 12.4
-- Dumped by pg_dump version 12.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: pgrouting; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgrouting WITH SCHEMA public;


--
-- Name: get_shortest_path(text, text); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_shortest_path(start text, destination text) RETURNS TABLE(depth integer, path text[], verbs text[])
    LANGUAGE plpgsql
    AS $$
  BEGIN
  RETURN QUERY
  WITH RECURSIVE search_step(id, link, verb, depth, route, verbs, cycle) AS (
    SELECT r.source, r.target, r.verb, 1,
           ARRAY[r.source],
           ARRAY[r.verb]::text[],
           false
      FROM graph r where r.source=start

     UNION ALL

    SELECT r.source, r.target, r.verb, sp.depth+1,
           sp.route || r.source,
           sp.verbs || r.verb,
           r.source = ANY(route)
      FROM graph r, search_step sp
     WHERE r.source = sp.link AND NOT cycle
  )
  SELECT sp.depth, (sp.route || destination) AS route, array_append(sp.verbs, '<destination>') as verbs
  FROM search_step AS sp
  WHERE link = destination AND NOT cycle AND NOT (destination = ANY(sp.route))
  ORDER BY depth ASC;

  END;
  $$;


ALTER FUNCTION public.get_shortest_path(start text, destination text) OWNER TO tenmo;

--
-- Name: migrate(text); Type: PROCEDURE; Schema: public; Owner: gleber
--

CREATE PROCEDURE public.migrate(migration text)
    LANGUAGE plpgsql
    AS $$
	declare
		step numeric := nextval('migration_steps');
	begin
		if exists(select 1 from migrations where id = step) then
			raise notice 'migrations: skipping step %', step;
		else
			raise notice 'migrations: running step %', step;
			execute migration;
			insert into migrations (id) values (step);
		end if;
	end;
$$;


ALTER PROCEDURE public.migrate(migration text) OWNER TO gleber;

--
-- Name: notify_events_changes(); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.notify_events_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
  PERFORM pg_notify(
    'events_changed',
    json_build_object(
      'operation', TG_OP,
      'record', row_to_json(NEW)
    )::text
  );
  RETURN NEW;
  END;
  $$;


ALTER FUNCTION public.notify_events_changes() OWNER TO tenmo;

--
-- Name: populate_graph(); Type: PROCEDURE; Schema: public; Owner: tenmo
--

CREATE PROCEDURE public.populate_graph()
    LANGUAGE sql
    AS $$

  insert into graph (source, verb, target)
  select incarnation_id, 'read_by', execution_id from operations where op_type = 'r'
  union all
  select execution_id, 'reads', incarnation_id from operations where op_type = 'r'
  union all
  select execution_id, 'writes', incarnation_id from operations where op_type = 'w'
  union all
  select incarnation_id, 'written_by', execution_id from operations where op_type = 'w'
  on conflict do nothing;

  insert into graph (source, verb, target)
  select execution_id, 'child_of', parent_id  from executions where parent_id is not null
  union all
  select parent_id, 'parent_of', execution_id  from executions where parent_id is not null
  union all
  select execution_id, 'created_by', creator_id  from executions where creator_id is not null
  union all
  select creator_id, 'creator_of', execution_id  from executions where creator_id is not null
  on conflict do nothing;

  insert into graph (source, verb, target)
  select incarnation_id, 'instance_of', entity_id from incarnations where entity_id is not null
  union all
  select entity_id, 'entity_of', incarnation_id from incarnations where entity_id is not null
  -- union all
  -- select incarnation_id, 'part_of', parent_id from incarnations where parent_id is not null
  -- union all
  -- select parent_id, 'divides_into', incarnation_id from incarnations where entity_id is not null
  on conflict do nothing;

  $$;


ALTER PROCEDURE public.populate_graph() OWNER TO tenmo;

--
-- Name: update_modified_column(); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.update_modified_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    NEW.modified = now();
    RETURN NEW;
  END;
  $$;


ALTER FUNCTION public.update_modified_column() OWNER TO tenmo;

SET default_table_access_method = heap;

--
-- Name: annotations; Type: TABLE; Schema: public; Owner: tenmo
--

CREATE TABLE public.annotations (
    annotation_id text NOT NULL,
    stored_at timestamp with time zone DEFAULT now() NOT NULL,
    execution_id text,
    ts timestamp with time zone NOT NULL,
    payload jsonb NOT NULL
);


ALTER TABLE public.annotations OWNER TO tenmo;

--
-- Name: entities; Type: TABLE; Schema: public; Owner: tenmo
--

CREATE TABLE public.entities (
    entity_id text NOT NULL,
    stored_at timestamp with time zone DEFAULT now() NOT NULL,
    description text
);


ALTER TABLE public.entities OWNER TO tenmo;

--
-- Name: events; Type: TABLE; Schema: public; Owner: tenmo
--

CREATE TABLE public.events (
    ulid character(26) NOT NULL,
    status character(1) DEFAULT 'i'::bpchar NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    stored_at timestamp with time zone DEFAULT now() NOT NULL,
    modified timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone NOT NULL,
    event_type text NOT NULL,
    payload jsonb NOT NULL
);


ALTER TABLE public.events OWNER TO tenmo;

--
-- Name: executions; Type: TABLE; Schema: public; Owner: tenmo
--

CREATE TABLE public.executions (
    execution_id text NOT NULL,
    stored_at timestamp with time zone DEFAULT now() NOT NULL,
    begin_timestamp timestamp with time zone NOT NULL,
    parent_id text,
    creator_id text,
    process_id text,
    description text DEFAULT ''::text,
    end_timestamp timestamp with time zone
);


ALTER TABLE public.executions OWNER TO tenmo;

--
-- Name: graph; Type: TABLE; Schema: public; Owner: tenmo
--

CREATE TABLE public.graph (
    source text NOT NULL,
    verb text NOT NULL,
    target text NOT NULL,
    tags text[] DEFAULT ARRAY[]::text[]
);


ALTER TABLE public.graph OWNER TO tenmo;

--
-- Name: incarnations; Type: TABLE; Schema: public; Owner: tenmo
--

CREATE TABLE public.incarnations (
    incarnation_id text NOT NULL,
    stored_at timestamp with time zone DEFAULT now() NOT NULL,
    entity_id text,
    creator_id text,
    description text DEFAULT ''::text
);


ALTER TABLE public.incarnations OWNER TO tenmo;

--
-- Name: interactions; Type: TABLE; Schema: public; Owner: tenmo
--

CREATE TABLE public.interactions (
    interaction_id text NOT NULL,
    stored_at timestamp with time zone DEFAULT now() NOT NULL,
    ts timestamp with time zone NOT NULL,
    participant_a text,
    participant_b text
);


ALTER TABLE public.interactions OWNER TO tenmo;

--
-- Name: messages; Type: TABLE; Schema: public; Owner: tenmo
--

CREATE TABLE public.messages (
    message_id text NOT NULL,
    stored_at timestamp with time zone DEFAULT now() NOT NULL,
    interaction_id text NOT NULL,
    ts timestamp with time zone NOT NULL,
    sender text NOT NULL,
    target text NOT NULL,
    incarnations text[] DEFAULT ARRAY[]::text[],
    payload jsonb DEFAULT '{}'::jsonb
);


ALTER TABLE public.messages OWNER TO tenmo;

--
-- Name: migrations; Type: TABLE; Schema: public; Owner: tenmo
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.migrations OWNER TO tenmo;

--
-- Name: operations; Type: TABLE; Schema: public; Owner: tenmo
--

CREATE TABLE public.operations (
    operation_id text NOT NULL,
    stored_at timestamp with time zone DEFAULT now() NOT NULL,
    ts timestamp with time zone NOT NULL,
    execution_id text,
    op_type character(1),
    entity_id text NOT NULL,
    incarnation_id text NOT NULL,
    entity_description text DEFAULT ''::text,
    incarnation_description text DEFAULT ''::text
);


ALTER TABLE public.operations OWNER TO tenmo;

--
-- Name: processes; Type: TABLE; Schema: public; Owner: tenmo
--

CREATE TABLE public.processes (
    process_id text NOT NULL,
    stored_at timestamp with time zone DEFAULT now() NOT NULL,
    description text
);


ALTER TABLE public.processes OWNER TO tenmo;

--
-- Data for Name: annotations; Type: TABLE DATA; Schema: public; Owner: tenmo
--



--
-- Data for Name: entities; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', '2020-09-17 16:17:46.356275+00', 'NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', '2020-09-17 16:17:46.374887+00', 'NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', '2020-09-17 16:17:46.46625+00', 'NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', '2020-09-17 16:17:46.476673+00', 'NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', '2020-09-17 16:17:46.510908+00', 'NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', '2020-09-17 16:17:46.52804+00', 'NSO /run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top') ON CONFLICT DO NOTHING;


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.events VALUES ('01EJEDQ17GF9KM0T75HT7ZDJM5', 'p', 1, '2020-09-17 16:17:46.306097+00', '2020-09-17 16:17:46.374887+00', '2020-09-17 16:00:23.356609+00', 'EventOperation', '{"type": "w", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv", "timestamp": "2020-09-17T16:00:23.356609", "event_ulid": "01EJEDQ17GF9KM0T75HT7ZDJM5", "execution_id": "30447023161349", "operation_id": "30447023161349-01EJEDQ17GF9KM0T75HT7ZDJM5", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ17770SACZ29ZYX3STMK', 'p', 1, '2020-09-17 16:17:46.266627+00', '2020-09-17 16:17:46.280928+00', '2020-09-17 16:00:23.355366+00', 'EventExecutionBegins', '{"parent_id": null, "timestamp": "2020-09-17T16:00:23.355366", "creator_id": null, "event_ulid": "01EJEDQ17770SACZ29ZYX3STMK", "process_id": null, "description": "_main", "execution_id": "30447023161344"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ178D5VMBXR42X600AJ7', 'p', 1, '2020-09-17 16:17:46.27418+00', '2020-09-17 16:17:46.289269+00', '2020-09-17 16:00:23.355465+00', 'EventExecutionBegins', '{"parent_id": "30447023161344", "timestamp": "2020-09-17T16:00:23.355465", "creator_id": null, "event_ulid": "01EJEDQ178D5VMBXR42X600AJ7", "process_id": null, "description": "evaluating file ''/home/gleber/code/nix/inst/share/nix/corepkgs/derivation.nix''", "execution_id": "30447023161345"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ178MR7X96G0JGQK8BAZ', 'p', 1, '2020-09-17 16:17:46.278125+00', '2020-09-17 16:17:46.297981+00', '2020-09-17 16:00:23.355501+00', 'EventExecutionEnds', '{"timestamp": "2020-09-17T16:00:23.355501", "event_ulid": "01EJEDQ178MR7X96G0JGQK8BAZ", "execution_id": "30447023161345"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ178F8T8Q9R417HKTY6Q', 'p', 1, '2020-09-17 16:17:46.28362+00', '2020-09-17 16:17:46.310258+00', '2020-09-17 16:00:23.355557+00', 'EventExecutionBegins', '{"parent_id": "30447023161346", "timestamp": "2020-09-17T16:00:23.355557", "creator_id": null, "event_ulid": "01EJEDQ178F8T8Q9R417HKTY6Q", "process_id": null, "description": "evaluating file ''/home/gleber/code/nix/tests/config.nix''", "execution_id": "30447023161347"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ178TP2P6JZ1Z2MGR85P', 'p', 1, '2020-09-17 16:17:46.281289+00', '2020-09-17 16:17:46.304624+00', '2020-09-17 16:00:23.355529+00', 'EventExecutionBegins', '{"parent_id": "30447023161344", "timestamp": "2020-09-17T16:00:23.355529", "creator_id": null, "event_ulid": "01EJEDQ178TP2P6JZ1Z2MGR85P", "process_id": null, "description": "_main.eval", "execution_id": "30447023161346"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ17GEEY2CW7KP25J7853', 'p', 2, '2020-09-17 16:17:46.308119+00', '2020-09-18 11:22:05.183659+00', '2020-09-17 16:00:23.35664+00', 'EventExecutionEnds', '{"timestamp": "2020-09-17T16:00:23.356640", "event_ulid": "01EJEDQ17GEEY2CW7KP25J7853", "execution_id": "30447023161349"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ179CPAVKB28J6E0A1SG', 'p', 1, '2020-09-17 16:17:46.286629+00', '2020-09-17 16:17:46.320291+00', '2020-09-17 16:00:23.355588+00', 'EventExecutionEnds', '{"timestamp": "2020-09-17T16:00:23.355588", "event_ulid": "01EJEDQ179CPAVKB28J6E0A1SG", "execution_id": "30447023161347"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ179R3T7YYQFMTYGCCVT', 'p', 1, '2020-09-17 16:17:46.28984+00', '2020-09-17 16:17:46.32539+00', '2020-09-17 16:00:23.355621+00', 'EventExecutionEnds', '{"timestamp": "2020-09-17T16:00:23.355621", "event_ulid": "01EJEDQ179R3T7YYQFMTYGCCVT", "execution_id": "30447023161346"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ17GTEHJ27KWX1PK47TM', 'p', 1, '2020-09-17 16:17:46.310275+00', '2020-09-17 16:17:46.337295+00', '2020-09-17 16:00:23.356671+00', 'EventExecutionBegins', '{"parent_id": "30447023161348", "timestamp": "2020-09-17T16:00:23.356671", "creator_id": null, "event_ulid": "01EJEDQ17GTEHJ27KWX1PK47TM", "process_id": null, "description": "building 1 paths", "execution_id": "30447023161351"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ1795ZPZ06MVVVND9A6K', 'p', 1, '2020-09-17 16:17:46.295432+00', '2020-09-17 16:17:46.342727+00', '2020-09-17 16:00:23.355682+00', 'EventExecutionBegins', '{"parent_id": "30447023161348", "timestamp": "2020-09-17T16:00:23.355682", "creator_id": null, "event_ulid": "01EJEDQ1795ZPZ06MVVVND9A6K", "process_id": null, "description": "derivation ''dependencies-top'' being evaled", "execution_id": "30447023161349"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ17BNWCFKCB769241CWZ', 'p', 1, '2020-09-17 16:17:46.298603+00', '2020-09-17 16:17:46.349566+00', '2020-09-17 16:00:23.355993+00', 'EventExecutionBegins', '{"parent_id": "30447023161349", "timestamp": "2020-09-17T16:00:23.355993", "creator_id": null, "event_ulid": "01EJEDQ17BNWCFKCB769241CWZ", "process_id": null, "description": "derivation ''dependencies-input-0'' being evaled", "execution_id": "30447023161350"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ17E3QNTDEHNYGHN0DNT', 'p', 1, '2020-09-17 16:17:46.30467+00', '2020-09-17 16:17:46.363762+00', '2020-09-17 16:00:23.356392+00', 'EventExecutionEnds', '{"timestamp": "2020-09-17T16:00:23.356392", "event_ulid": "01EJEDQ17E3QNTDEHNYGHN0DNT", "execution_id": "30447023161350"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ17HBGW4S4D9E1MFVNKF', 'p', 1, '2020-09-17 16:17:46.316557+00', '2020-09-17 16:17:46.401285+00', '2020-09-17 16:00:23.356906+00', 'EventExecutionBegins', '{"parent_id": "30447023161351", "timestamp": "2020-09-17T16:00:23.356906", "creator_id": null, "event_ulid": "01EJEDQ17HBGW4S4D9E1MFVNKF", "process_id": null, "description": "", "execution_id": "30447023161353"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ17G7KCFKWMWN804J95B', 'p', 1, '2020-09-17 16:17:46.312047+00', '2020-09-17 16:17:46.384397+00', '2020-09-17 16:00:23.356702+00', 'EventExecutionBegins', '{"parent_id": "30447023161351", "timestamp": "2020-09-17T16:00:23.356702", "creator_id": null, "event_ulid": "01EJEDQ17G7KCFKWMWN804J95B", "process_id": null, "description": "querying info about missing paths", "execution_id": "30447023161352"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ17GA5SY76E8JPPGFENW', 'p', 1, '2020-09-17 16:17:46.314233+00', '2020-09-17 16:17:46.392742+00', '2020-09-17 16:00:23.356764+00', 'EventExecutionEnds', '{"timestamp": "2020-09-17T16:00:23.356764", "event_ulid": "01EJEDQ17GA5SY76E8JPPGFENW", "execution_id": "30447023161352"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ17J5H0BW71R3S6FRCW5', 'p', 1, '2020-09-17 16:17:46.323209+00', '2020-09-17 16:17:46.428133+00', '2020-09-17 16:00:23.356999+00', 'EventExecutionBegins', '{"parent_id": "30447023161351", "timestamp": "2020-09-17T16:00:23.356999", "creator_id": null, "event_ulid": "01EJEDQ17J5H0BW71R3S6FRCW5", "process_id": null, "description": "querying info about missing paths", "execution_id": "30447023161356"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ17JPKDH2J8T87K8FEZ3', 'p', 1, '2020-09-17 16:17:46.32046+00', '2020-09-17 16:17:46.418986+00', '2020-09-17 16:00:23.356969+00', 'EventExecutionBegins', '{"parent_id": "30447023161351", "timestamp": "2020-09-17T16:00:23.356969", "creator_id": null, "event_ulid": "01EJEDQ17JPKDH2J8T87K8FEZ3", "process_id": null, "description": "", "execution_id": "30447023161355"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ17HXFJ84XKGVFT1CV9R', 'p', 1, '2020-09-17 16:17:46.31818+00', '2020-09-17 16:17:46.410228+00', '2020-09-17 16:00:23.356937+00', 'EventExecutionBegins', '{"parent_id": "30447023161351", "timestamp": "2020-09-17T16:00:23.356937", "creator_id": null, "event_ulid": "01EJEDQ17HXFJ84XKGVFT1CV9R", "process_id": null, "description": "", "execution_id": "30447023161354"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ1798MAWWX28NMHGFQ4Y', 'p', 1, '2020-09-17 16:17:46.292043+00', '2020-09-17 16:17:46.331296+00', '2020-09-17 16:00:23.355654+00', 'EventExecutionBegins', '{"parent_id": "30447023161344", "timestamp": "2020-09-17T16:00:23.355654", "creator_id": null, "event_ulid": "01EJEDQ1798MAWWX28NMHGFQ4Y", "process_id": null, "description": "preparing build of 1 derivations", "execution_id": "30447023161348"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ17JB3VQHGAXESE9RSCA', 'p', 1, '2020-09-17 16:17:46.32572+00', '2020-09-17 16:17:46.436978+00', '2020-09-17 16:00:23.357061+00', 'EventExecutionEnds', '{"timestamp": "2020-09-17T16:00:23.357061", "event_ulid": "01EJEDQ17JB3VQHGAXESE9RSCA", "execution_id": "30447023161356"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ183H6EY0FDBJBFEPT9W', 'p', 1, '2020-09-17 16:17:46.33119+00', '2020-09-17 16:17:46.454244+00', '2020-09-17 16:00:23.359694+00', 'EventOperation', '{"type": "r", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv", "timestamp": "2020-09-17T16:00:23.359694", "event_ulid": "01EJEDQ183H6EY0FDBJBFEPT9W", "execution_id": "30447023161357", "operation_id": "30447023161357-01EJEDQ183H6EY0FDBJBFEPT9W", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ183HKFZSQ9JBG7G0TNZ', 'p', 1, '2020-09-17 16:17:46.332701+00', '2020-09-17 16:17:46.46625+00', '2020-09-17 16:00:23.359725+00', 'EventOperation', '{"type": "r", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh", "timestamp": "2020-09-17T16:00:23.359725", "event_ulid": "01EJEDQ183HKFZSQ9JBG7G0TNZ", "execution_id": "30447023161357", "operation_id": "30447023161357-01EJEDQ183HKFZSQ9JBG7G0TNZ", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ186SGK00NV91JS5K61Q', 'p', 1, '2020-09-17 16:17:46.334939+00', '2020-09-17 16:17:46.476673+00', '2020-09-17 16:00:23.360144+00', 'EventOperation', '{"type": "w", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0", "timestamp": "2020-09-17T16:00:23.360144", "event_ulid": "01EJEDQ186SGK00NV91JS5K61Q", "execution_id": "30447023161357", "operation_id": "30447023161357-01EJEDQ186SGK00NV91JS5K61Q", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ188B7BEQDG77FGJ23TC', 'p', 1, '2020-09-17 16:17:46.338064+00', '2020-09-17 16:17:46.486552+00', '2020-09-17 16:00:23.360457+00', 'EventExecutionEnds', '{"timestamp": "2020-09-17T16:00:23.360457", "event_ulid": "01EJEDQ188B7BEQDG77FGJ23TC", "execution_id": "30447023161357"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ18DM47YX2CEG8TSTZ1D', 'p', 1, '2020-09-17 16:17:46.340503+00', '2020-09-17 16:17:46.495221+00', '2020-09-17 16:00:23.36133+00', 'EventExecutionBegins', '{"parent_id": "30447023161351", "timestamp": "2020-09-17T16:00:23.361330", "creator_id": null, "event_ulid": "01EJEDQ18DM47YX2CEG8TSTZ1D", "process_id": null, "description": "building ''/run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv''", "execution_id": "30447023161358"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ18DHBC9MBVDAB49KCN1', 'p', 1, '2020-09-17 16:17:46.342934+00', '2020-09-17 16:17:46.503211+00', '2020-09-17 16:00:23.361361+00', 'EventOperation', '{"type": "r", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv", "timestamp": "2020-09-17T16:00:23.361361", "event_ulid": "01EJEDQ18DHBC9MBVDAB49KCN1", "execution_id": "30447023161358", "operation_id": "30447023161358-01EJEDQ18DHBC9MBVDAB49KCN1", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ18E2QD3RADBXSRRWPAF', 'p', 1, '2020-09-17 16:17:46.344756+00', '2020-09-17 16:17:46.510908+00', '2020-09-17 16:00:23.361392+00', 'EventOperation', '{"type": "r", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh", "timestamp": "2020-09-17T16:00:23.361392", "event_ulid": "01EJEDQ18E2QD3RADBXSRRWPAF", "execution_id": "30447023161358", "operation_id": "30447023161358-01EJEDQ18E2QD3RADBXSRRWPAF", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ18E3J4FWDXY5YZT1HMN', 'p', 1, '2020-09-17 16:17:46.346975+00', '2020-09-17 16:17:46.519462+00', '2020-09-17 16:00:23.361423+00', 'EventOperation', '{"type": "r", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0", "timestamp": "2020-09-17T16:00:23.361423", "event_ulid": "01EJEDQ18E3J4FWDXY5YZT1HMN", "execution_id": "30447023161358", "operation_id": "30447023161358-01EJEDQ18E3J4FWDXY5YZT1HMN", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ18HWCR4FGFTMAG3SZJB', 'p', 1, '2020-09-17 16:17:46.34944+00', '2020-09-17 16:17:46.52804+00', '2020-09-17 16:00:23.361919+00', 'EventOperation', '{"type": "w", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top", "timestamp": "2020-09-17T16:00:23.361919", "event_ulid": "01EJEDQ18HWCR4FGFTMAG3SZJB", "execution_id": "30447023161358", "operation_id": "30447023161358-01EJEDQ18HWCR4FGFTMAG3SZJB", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ18JFTWCX75JQBFV17EF', 'p', 1, '2020-09-17 16:17:46.35142+00', '2020-09-17 16:17:46.5372+00', '2020-09-17 16:00:23.362164+00', 'EventExecutionEnds', '{"timestamp": "2020-09-17T16:00:23.362164", "event_ulid": "01EJEDQ18JFTWCX75JQBFV17EF", "execution_id": "30447023161358"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ17ERN2G3D7THC4X6DE3', 'p', 1, '2020-09-17 16:17:46.302167+00', '2020-09-17 16:17:46.356275+00', '2020-09-17 16:00:23.356361+00', 'EventOperation', '{"type": "w", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv", "timestamp": "2020-09-17T16:00:23.356361", "event_ulid": "01EJEDQ17ERN2G3D7THC4X6DE3", "execution_id": "30447023161350", "operation_id": "30447023161350-01EJEDQ17ERN2G3D7THC4X6DE3", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ183CBH459MMR5J7NHDR', 'p', 1, '2020-09-17 16:17:46.328713+00', '2020-09-17 16:17:46.445579+00', '2020-09-17 16:00:23.359662+00', 'EventExecutionBegins', '{"parent_id": "30447023161351", "timestamp": "2020-09-17T16:00:23.359662", "creator_id": null, "event_ulid": "01EJEDQ183CBH459MMR5J7NHDR", "process_id": null, "description": "building ''/run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv''", "execution_id": "30447023161357"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ18KWR6N3019H1CKT49F', 'p', 1, '2020-09-17 16:17:46.353802+00', '2020-09-17 16:17:46.545091+00', '2020-09-17 16:00:23.362226+00', 'EventExecutionEnds', '{"timestamp": "2020-09-17T16:00:23.362226", "event_ulid": "01EJEDQ18KWR6N3019H1CKT49F", "execution_id": "30447023161355"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ18KA2SG1YAQKZCMZSKZ', 'p', 1, '2020-09-17 16:17:46.356121+00', '2020-09-17 16:17:46.553334+00', '2020-09-17 16:00:23.362257+00', 'EventExecutionEnds', '{"timestamp": "2020-09-17T16:00:23.362257", "event_ulid": "01EJEDQ18KA2SG1YAQKZCMZSKZ", "execution_id": "30447023161354"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ18KWK5H75RY54TMVYNK', 'p', 1, '2020-09-17 16:17:46.357609+00', '2020-09-17 16:17:46.561069+00', '2020-09-17 16:00:23.362291+00', 'EventExecutionEnds', '{"timestamp": "2020-09-17T16:00:23.362291", "event_ulid": "01EJEDQ18KWK5H75RY54TMVYNK", "execution_id": "30447023161353"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ18KY7XZHJF5Q2XHRKAH', 'p', 1, '2020-09-17 16:17:46.3596+00', '2020-09-17 16:17:46.569279+00', '2020-09-17 16:00:23.362323+00', 'EventExecutionEnds', '{"timestamp": "2020-09-17T16:00:23.362323", "event_ulid": "01EJEDQ18KY7XZHJF5Q2XHRKAH", "execution_id": "30447023161351"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ18KB6CH02SXHPDQ3G9R', 'p', 1, '2020-09-17 16:17:46.361624+00', '2020-09-17 16:17:46.577248+00', '2020-09-17 16:00:23.362385+00', 'EventExecutionEnds', '{"timestamp": "2020-09-17T16:00:23.362385", "event_ulid": "01EJEDQ18KB6CH02SXHPDQ3G9R", "execution_id": "30447023161348"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJEDQ18MC8C4KC5D7P6ZCE3V', 'p', 1, '2020-09-17 16:17:46.365735+00', '2020-09-17 16:17:46.585307+00', '2020-09-17 16:00:23.362416+00', 'EventExecutionEnds', '{"timestamp": "2020-09-17T16:00:23.362416", "event_ulid": "01EJEDQ18MC8C4KC5D7P6ZCE3V", "execution_id": "30447023161344"}') ON CONFLICT DO NOTHING;


--
-- Data for Name: executions; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.executions VALUES ('30447023161345', '2020-09-17 16:17:46.289269+00', '2020-09-17 16:00:23.355465+00', '30447023161344', NULL, NULL, 'evaluating file ''/home/gleber/code/nix/inst/share/nix/corepkgs/derivation.nix''', '2020-09-17 16:00:23.355501+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('30447023161347', '2020-09-17 16:17:46.310258+00', '2020-09-17 16:00:23.355557+00', '30447023161346', NULL, NULL, 'evaluating file ''/home/gleber/code/nix/tests/config.nix''', '2020-09-17 16:00:23.355588+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('30447023161346', '2020-09-17 16:17:46.304624+00', '2020-09-17 16:00:23.355529+00', '30447023161344', NULL, NULL, '_main.eval', '2020-09-17 16:00:23.355621+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('30447023161350', '2020-09-17 16:17:46.349566+00', '2020-09-17 16:00:23.355993+00', '30447023161349', NULL, NULL, 'derivation ''dependencies-input-0'' being evaled', '2020-09-17 16:00:23.356392+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('30447023161352', '2020-09-17 16:17:46.384397+00', '2020-09-17 16:00:23.356702+00', '30447023161351', NULL, NULL, 'querying info about missing paths', '2020-09-17 16:00:23.356764+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('30447023161356', '2020-09-17 16:17:46.428133+00', '2020-09-17 16:00:23.356999+00', '30447023161351', NULL, NULL, 'querying info about missing paths', '2020-09-17 16:00:23.357061+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('30447023161357', '2020-09-17 16:17:46.445579+00', '2020-09-17 16:00:23.359662+00', '30447023161351', NULL, NULL, 'building ''/run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv''', '2020-09-17 16:00:23.360457+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('30447023161358', '2020-09-17 16:17:46.495221+00', '2020-09-17 16:00:23.36133+00', '30447023161351', NULL, NULL, 'building ''/run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv''', '2020-09-17 16:00:23.362164+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('30447023161355', '2020-09-17 16:17:46.418986+00', '2020-09-17 16:00:23.356969+00', '30447023161351', NULL, NULL, '', '2020-09-17 16:00:23.362226+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('30447023161354', '2020-09-17 16:17:46.410228+00', '2020-09-17 16:00:23.356937+00', '30447023161351', NULL, NULL, '', '2020-09-17 16:00:23.362257+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('30447023161353', '2020-09-17 16:17:46.401285+00', '2020-09-17 16:00:23.356906+00', '30447023161351', NULL, NULL, '', '2020-09-17 16:00:23.362291+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('30447023161351', '2020-09-17 16:17:46.337295+00', '2020-09-17 16:00:23.356671+00', '30447023161348', NULL, NULL, 'building 1 paths', '2020-09-17 16:00:23.362323+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('30447023161348', '2020-09-17 16:17:46.331296+00', '2020-09-17 16:00:23.355654+00', '30447023161344', NULL, NULL, 'preparing build of 1 derivations', '2020-09-17 16:00:23.362385+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('30447023161344', '2020-09-17 16:17:46.280928+00', '2020-09-17 16:00:23.355366+00', NULL, NULL, NULL, '_main', '2020-09-17 16:00:23.362416+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('30447023161349', '2020-09-17 16:17:46.342727+00', '2020-09-17 16:00:23.355682+00', '30447023161348', NULL, NULL, 'derivation ''dependencies-top'' being evaled', '2020-09-17 16:00:23.35664+00') ON CONFLICT DO NOTHING;


--
-- Data for Name: graph; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', 'read_by', '30447023161357', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', 'read_by', '30447023161357', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', 'read_by', '30447023161358', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'read_by', '30447023161358', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', 'read_by', '30447023161358', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161357', 'reads', 'i:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161357', 'reads', 'i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161358', 'reads', 'i:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161358', 'reads', 'i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161358', 'reads', 'i:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161350', 'writes', 'i:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161349', 'writes', 'i:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161357', 'writes', 'i:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161358', 'writes', 'i:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', 'written_by', '30447023161350', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', 'written_by', '30447023161349', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', 'written_by', '30447023161357', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', 'written_by', '30447023161358', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161345', 'child_of', '30447023161344', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161347', 'child_of', '30447023161346', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161346', 'child_of', '30447023161344', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161349', 'child_of', '30447023161348', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161350', 'child_of', '30447023161349', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161352', 'child_of', '30447023161351', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161356', 'child_of', '30447023161351', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161357', 'child_of', '30447023161351', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161358', 'child_of', '30447023161351', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161355', 'child_of', '30447023161351', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161354', 'child_of', '30447023161351', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161353', 'child_of', '30447023161351', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161351', 'child_of', '30447023161348', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161348', 'child_of', '30447023161344', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161344', 'parent_of', '30447023161345', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161346', 'parent_of', '30447023161347', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161344', 'parent_of', '30447023161346', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161348', 'parent_of', '30447023161349', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161349', 'parent_of', '30447023161350', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161351', 'parent_of', '30447023161352', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161351', 'parent_of', '30447023161356', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161351', 'parent_of', '30447023161357', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161351', 'parent_of', '30447023161358', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161351', 'parent_of', '30447023161355', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161351', 'parent_of', '30447023161354', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161351', 'parent_of', '30447023161353', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161348', 'parent_of', '30447023161351', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('30447023161344', 'parent_of', '30447023161348', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', 'instance_of', 'e:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', 'instance_of', 'e:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', 'instance_of', 'e:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'instance_of', 'e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', 'instance_of', 'e:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', 'instance_of', 'e:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('e:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', 'entity_of', 'i:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('e:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', 'entity_of', 'i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('e:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', 'entity_of', 'i:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'entity_of', 'i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('e:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', 'entity_of', 'i:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('e:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', 'entity_of', 'i:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', '{}') ON CONFLICT DO NOTHING;


--
-- Data for Name: incarnations; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', '2020-09-17 16:17:46.356275+00', 'e:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', '30447023161350', 'NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', '2020-09-17 16:17:46.46625+00', 'e:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', NULL, 'NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', '2020-09-17 16:17:46.374887+00', 'e:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', '30447023161349', 'NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', '2020-09-17 16:17:46.510908+00', 'e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', NULL, 'NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', '2020-09-17 16:17:46.476673+00', 'e:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', '30447023161357', 'NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', '2020-09-17 16:17:46.52804+00', 'e:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', '30447023161358', 'NSO /run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top') ON CONFLICT DO NOTHING;


--
-- Data for Name: interactions; Type: TABLE DATA; Schema: public; Owner: tenmo
--



--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: tenmo
--



--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.migrations VALUES (1, '2020-09-17 16:16:34.406454+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (2, '2020-09-17 16:16:34.415483+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (3, '2020-09-17 16:16:34.461704+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (4, '2020-09-17 16:16:34.465494+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (5, '2020-09-17 16:16:57.441564+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (6, '2020-09-18 11:15:08.290808+00') ON CONFLICT DO NOTHING;


--
-- Data for Name: operations; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.operations VALUES ('01EJEDQ17ERN2G3D7THC4X6DE3', '2020-09-17 16:17:46.356275+00', '2020-09-17 16:00:23.356361+00', '30447023161350', 'w', 'e:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', 'i:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', 'NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', 'NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJEDQ17GF9KM0T75HT7ZDJM5', '2020-09-17 16:17:46.374887+00', '2020-09-17 16:00:23.356609+00', '30447023161349', 'w', 'e:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', 'i:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', 'NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', 'NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJEDQ183H6EY0FDBJBFEPT9W', '2020-09-17 16:17:46.454244+00', '2020-09-17 16:00:23.359694+00', '30447023161357', 'r', 'e:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', 'i:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', 'NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', 'NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJEDQ183HKFZSQ9JBG7G0TNZ', '2020-09-17 16:17:46.46625+00', '2020-09-17 16:00:23.359725+00', '30447023161357', 'r', 'e:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', 'i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', 'NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', 'NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJEDQ186SGK00NV91JS5K61Q', '2020-09-17 16:17:46.476673+00', '2020-09-17 16:00:23.360144+00', '30447023161357', 'w', 'e:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', 'i:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', 'NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', 'NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJEDQ18DHBC9MBVDAB49KCN1', '2020-09-17 16:17:46.503211+00', '2020-09-17 16:00:23.361361+00', '30447023161358', 'r', 'e:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', 'i:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', 'NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', 'NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJEDQ18E2QD3RADBXSRRWPAF', '2020-09-17 16:17:46.510908+00', '2020-09-17 16:00:23.361392+00', '30447023161358', 'r', 'e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJEDQ18E3J4FWDXY5YZT1HMN', '2020-09-17 16:17:46.519462+00', '2020-09-17 16:00:23.361423+00', '30447023161358', 'r', 'e:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', 'i:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', 'NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', 'NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJEDQ18HWCR4FGFTMAG3SZJB', '2020-09-17 16:17:46.52804+00', '2020-09-17 16:00:23.361919+00', '30447023161358', 'w', 'e:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', 'i:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', 'NSO /run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', 'NSO /run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top') ON CONFLICT DO NOTHING;


--
-- Data for Name: processes; Type: TABLE DATA; Schema: public; Owner: tenmo
--



--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: gleber
--



--
-- Name: annotations annotations_pkey; Type: CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.annotations
    ADD CONSTRAINT annotations_pkey PRIMARY KEY (annotation_id);


--
-- Name: entities entities_pkey; Type: CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.entities
    ADD CONSTRAINT entities_pkey PRIMARY KEY (entity_id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (ulid);


--
-- Name: executions executions_pkey; Type: CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.executions
    ADD CONSTRAINT executions_pkey PRIMARY KEY (execution_id);


--
-- Name: graph graph_pkey; Type: CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.graph
    ADD CONSTRAINT graph_pkey PRIMARY KEY (source, target, verb);


--
-- Name: incarnations incarnations_pkey; Type: CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.incarnations
    ADD CONSTRAINT incarnations_pkey PRIMARY KEY (incarnation_id);


--
-- Name: interactions interactions_pkey; Type: CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.interactions
    ADD CONSTRAINT interactions_pkey PRIMARY KEY (interaction_id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (message_id);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: operations operations_pkey; Type: CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.operations
    ADD CONSTRAINT operations_pkey PRIMARY KEY (operation_id);


--
-- Name: processes processes_pkey; Type: CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.processes
    ADD CONSTRAINT processes_pkey PRIMARY KEY (process_id);


--
-- Name: events events_changed; Type: TRIGGER; Schema: public; Owner: tenmo
--

CREATE TRIGGER events_changed AFTER INSERT OR UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.notify_events_changes();


--
-- Name: events update_events_modtime; Type: TRIGGER; Schema: public; Owner: tenmo
--

CREATE TRIGGER update_events_modtime BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.update_modified_column();


--
-- Name: annotations annotations_execution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.annotations
    ADD CONSTRAINT annotations_execution_id_fkey FOREIGN KEY (execution_id) REFERENCES public.executions(execution_id);


--
-- Name: executions executions_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.executions
    ADD CONSTRAINT executions_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.executions(execution_id);


--
-- Name: executions executions_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.executions
    ADD CONSTRAINT executions_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.executions(execution_id);


--
-- Name: executions executions_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.executions
    ADD CONSTRAINT executions_process_id_fkey FOREIGN KEY (process_id) REFERENCES public.processes(process_id);


--
-- Name: incarnations incarnations_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.incarnations
    ADD CONSTRAINT incarnations_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.executions(execution_id);


--
-- Name: incarnations incarnations_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.incarnations
    ADD CONSTRAINT incarnations_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.entities(entity_id);


--
-- Name: interactions interactions_participant_a_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.interactions
    ADD CONSTRAINT interactions_participant_a_fkey FOREIGN KEY (participant_a) REFERENCES public.executions(execution_id);


--
-- Name: interactions interactions_participant_b_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.interactions
    ADD CONSTRAINT interactions_participant_b_fkey FOREIGN KEY (participant_b) REFERENCES public.executions(execution_id);


--
-- Name: messages messages_interaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_interaction_id_fkey FOREIGN KEY (interaction_id) REFERENCES public.interactions(interaction_id);


--
-- Name: messages messages_sender_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_fkey FOREIGN KEY (sender) REFERENCES public.executions(execution_id);


--
-- Name: messages messages_target_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_target_fkey FOREIGN KEY (target) REFERENCES public.executions(execution_id);


--
-- Name: operations operations_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.operations
    ADD CONSTRAINT operations_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.entities(entity_id);


--
-- Name: operations operations_execution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.operations
    ADD CONSTRAINT operations_execution_id_fkey FOREIGN KEY (execution_id) REFERENCES public.executions(execution_id);


--
-- Name: operations operations_incarnation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.operations
    ADD CONSTRAINT operations_incarnation_id_fkey FOREIGN KEY (incarnation_id) REFERENCES public.incarnations(incarnation_id);


--
-- PostgreSQL database dump complete
--

