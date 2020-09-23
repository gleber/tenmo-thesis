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
-- Name: triple; Type: TYPE; Schema: public; Owner: tenmo
--

CREATE TYPE public.triple AS (
	source text,
	verb text,
	target text
);


ALTER TYPE public.triple OWNER TO tenmo;

--
-- Name: get_all_paths_from(text); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_all_paths_from(start text) RETURNS TABLE(depth integer, verbs text[], path text[])
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
  SELECT sp.depth, array_append(sp.verbs, '<end>') AS verbs, sp.route || sp.link AS path
  FROM search_step AS sp
  WHERE NOT cycle
  ORDER BY depth ASC;

  END;
  $$;


ALTER FUNCTION public.get_all_paths_from(start text) OWNER TO tenmo;

--
-- Name: get_all_paths_from_by_verbs(text, text[]); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_all_paths_from_by_verbs(start text, filter_verbs text[]) RETURNS TABLE(depth integer, verbs text[], path text[])
    LANGUAGE plpgsql
    AS $$
  BEGIN
  RETURN QUERY

  WITH RECURSIVE search_step(id, link, verb, depth, route, verbs, cycle) AS (
    SELECT r.source, r.target, r.verb, 1,
           ARRAY[r.source],
           ARRAY[r.verb]::text[],
           false
      FROM graph r where r.source=start and r.verb = ANY(filter_verbs)

     UNION ALL

    SELECT r.source, r.target, r.verb, sp.depth+1,
           sp.route || r.source,
           sp.verbs || r.verb,
           r.source = ANY(route)
      FROM graph r, search_step sp
     WHERE r.source = sp.link AND NOT cycle and r.verb = ANY(filter_verbs)
  )
  SELECT sp.depth, array_append(sp.verbs, '<end>') AS verbs, sp.route || sp.link AS path
  FROM search_step AS sp
  WHERE NOT cycle
  ORDER BY depth ASC;

  END;
  $$;


ALTER FUNCTION public.get_all_paths_from_by_verbs(start text, filter_verbs text[]) OWNER TO tenmo;

--
-- Name: get_closure_from(text); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_closure_from(start text) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
  begin
  return query
  select t.depth, t.path[array_upper(t.path,1)] from get_all_paths_from(start) as t;
  end;
  $$;


ALTER FUNCTION public.get_closure_from(start text) OWNER TO tenmo;

--
-- Name: get_closure_from_by_verbs(text, text[]); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_closure_from_by_verbs(start text, crawl_verbs text[]) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
  BEGIN
  RETURN QUERY
  select t.depth, t.path[array_upper(t.path,1)] from get_all_paths_from_by_verbs(start, crawl_verbs) as t;
  END;
  $$;


ALTER FUNCTION public.get_closure_from_by_verbs(start text, crawl_verbs text[]) OWNER TO tenmo;

--
-- Name: get_closure_from_by_verbs_filtered(text, text[], text[]); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_closure_from_by_verbs_filtered(start text, crawl_verbs text[], filter_verbs text[]) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
  BEGIN
  RETURN QUERY
  select t.depth, t.path[array_upper(t.path,1)] from get_all_paths_from_by_verbs(start, crawl_verbs) as t where t.verbs[array_upper(t.verbs,1)-1] = ANY(filter_verbs);
  END;
  $$;


ALTER FUNCTION public.get_closure_from_by_verbs_filtered(start text, crawl_verbs text[], filter_verbs text[]) OWNER TO tenmo;

--
-- Name: get_closure_from_filtered(text, text[]); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_closure_from_filtered(start text, filter_verbs text[]) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
  begin
  return query
  select t.depth, t.path[array_upper(t.path,1)] from get_all_paths_from(start) as t where t.verbs[array_upper(t.verbs,1)-1] = ANY(filter_verbs);
  end;
  $$;


ALTER FUNCTION public.get_closure_from_filtered(start text, filter_verbs text[]) OWNER TO tenmo;

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
  union all
  select incarnation_id, 'part_of', parent_id from incarnations where parent_id is not null
  union all
  select parent_id, 'divides_into', incarnation_id from incarnations where parent_id is not null
  on conflict do nothing;

  insert into graph (source, verb, target)
  select sender, 'sent_to', target from messages
  union all
  select target, 'received_from', sender from messages
  on conflict do nothing;

  insert into graph (source, verb, target)
  select ((unnest(ARRAY[(incarnation_id, 'after', prev_incarnation_id)::triple, (prev_incarnation_id, 'before', incarnation_id)::triple]))).* from (
    select tt.entity_id, tt.incarnation_id, LAG(tt.incarnation_id, 1) OVER (partition by entity_id order by incarnation_id) prev_incarnation_id from (
      select entity_id, unnest(array_agg(t.incarnation_id order by t.incarnation_id)) as incarnation_id from incarnations t group by entity_id having array_length(array_agg(t.incarnation_id order by t.incarnation_id), 1) > 1) as tt)
      as ttt
      where ttt.prev_incarnation_id is not null
      ON CONFLICT DO NOTHING;

  $$;


ALTER PROCEDURE public.populate_graph() OWNER TO tenmo;

--
-- Name: provenance_set(text); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.provenance_set(start text) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
 BEGIN
 RETURN QUERY
 select * from get_closure_from_by_verbs_filtered(start, ARRAY['written_by','reads']::text[], '{reads}'::text[]) as t where t.depth <= 2;
 END;
 $$;


ALTER FUNCTION public.provenance_set(start text) OWNER TO tenmo;

--
-- Name: provenance_set_indirect(text); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.provenance_set_indirect(start text) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
 BEGIN
 RETURN QUERY
 select * from get_closure_from_by_verbs_filtered(start, ARRAY['written_by','reads']::text[], '{reads}'::text[]) as t;
 END;
 $$;


ALTER FUNCTION public.provenance_set_indirect(start text) OWNER TO tenmo;

--
-- Name: trace(text); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.trace(start text) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
  BEGIN
  RETURN QUERY
  select * from get_closure_from_by_verbs(start, ARRAY['child_of']::text[]) as t;
  END;
  $$;


ALTER FUNCTION public.trace(start text) OWNER TO tenmo;

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
    description text DEFAULT ''::text,
    parent_id text
);


ALTER TABLE public.incarnations OWNER TO tenmo;

--
-- Name: interactions; Type: TABLE; Schema: public; Owner: tenmo
--

CREATE TABLE public.interactions (
    interaction_id text NOT NULL,
    stored_at timestamp with time zone DEFAULT now() NOT NULL,
    ts timestamp with time zone NOT NULL,
    initiator_participant text,
    responder_participant text,
    description text DEFAULT ''::text
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
    incarnations_ids text[] DEFAULT ARRAY[]::text[],
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

INSERT INTO public.entities VALUES ('src', '2020-09-19 21:34:57.869683+00', './src/*') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('repo', '2020-09-19 21:36:32.702626+00', 'repo') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('tmp-store-3', '2020-09-19 21:55:51.346914+00', 'temp #2 src checkout') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('tmp-store-1', '2020-09-19 21:55:31.056307+00', 'temp #1 src checkout') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('tmp-src-1', '2020-09-19 22:14:20.316788+00', 'temp #1 ./src/*') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('tmp-src-3', '2020-09-19 22:20:23.848646+00', 'temp #2 ./src/*') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('tmp-bin-1', '2020-09-19 22:22:02.887697+00', 'temp #1 binary') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('tmp-bin-3', '2020-09-19 22:22:32.769806+00', 'temp #2 binary') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('bin', '2020-09-19 22:25:10.054704+00', 'deployed binary') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('app', '2020-09-19 22:29:05.352353+00', 'stopped app') ON CONFLICT DO NOTHING;


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.events VALUES ('gcap1                     ', 'p', 1, '2020-09-19 21:34:57.859518+00', '2020-09-19 21:34:57.869683+00', '2020-09-19 21:34:57.859518+00', 'EventOperation', '{"type": "r", "entity_id": "src", "timestamp": "2020-09-19 23:34:42.65589+00", "event_ulid": "gcap1", "execution_id": "git-commit-and-push-1", "operation_id": "gcap1", "incarnation_id": "src-1", "entity_description": "./src/*", "incarnation_description": "./src/* #1"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('gcap2                     ', 'p', 1, '2020-09-19 21:35:29.139298+00', '2020-09-19 21:35:29.151998+00', '2020-09-19 21:35:29.139298+00', 'EventOperation', '{"type": "r", "entity_id": "src", "timestamp": "2020-09-19 23:34:42.65589+00", "event_ulid": "gcap2", "execution_id": "git-commit-and-push-2", "operation_id": "gcap2", "incarnation_id": "src-2", "entity_description": "./src/*", "incarnation_description": "./src/* #2"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dgcap3                    ', 'p', 1, '2020-09-19 21:42:41.142973+00', '2020-09-19 21:42:41.152077+00', '2020-09-19 21:42:41.142973+00', 'EventOperation', '{"type": "r", "entity_id": "repo", "timestamp": "2020-09-19 23:42:42.65589+00", "event_ulid": "dgcap3", "execution_id": "deployment-3", "operation_id": "dgcap3", "incarnation_id": "repo-3", "entity_description": "", "incarnation_description": ""}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('gcap1-1                   ', 'p', 1, '2020-09-19 21:36:32.696394+00', '2020-09-19 21:36:32.702626+00', '2020-09-19 21:36:32.696394+00', 'EventOperation', '{"type": "w", "entity_id": "repo", "timestamp": "2020-09-19 23:34:42.65589+00", "event_ulid": "gcap1-1", "execution_id": "git-commit-and-push-1", "operation_id": "gcap1-1", "incarnation_id": "repo-1", "entity_description": "repo", "incarnation_description": "repo #1"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('gcap2-1                   ', 'p', 1, '2020-09-19 21:36:50.478507+00', '2020-09-19 21:36:50.485863+00', '2020-09-19 21:36:50.478507+00', 'EventOperation', '{"type": "w", "entity_id": "repo", "timestamp": "2020-09-19 23:34:42.65589+00", "event_ulid": "gcap2-1", "execution_id": "git-commit-and-push-2", "operation_id": "gcap2-1", "incarnation_id": "repo-2", "entity_description": "repo", "incarnation_description": "repo #2"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('gcap3-1                   ', 'p', 1, '2020-09-19 21:38:56.011458+00', '2020-09-19 21:38:56.019265+00', '2020-09-19 21:38:56.011458+00', 'EventOperation', '{"type": "w", "entity_id": "repo", "timestamp": "2020-09-19 23:34:42.65589+00", "event_ulid": "gcap3-1", "execution_id": "git-commit-and-push-3", "operation_id": "gcap3-1", "incarnation_id": "repo-3", "entity_description": "repo", "incarnation_description": "repo #3"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dgcap1                    ', 'p', 1, '2020-09-19 21:42:59.575676+00', '2020-09-19 21:42:59.58418+00', '2020-09-19 21:42:59.575676+00', 'EventOperation', '{"type": "r", "entity_id": "repo", "timestamp": "2020-09-19 23:41:42.65589+00", "event_ulid": "dgcap1", "execution_id": "deployment-1", "operation_id": "dgcap1", "incarnation_id": "repo-1", "entity_description": "", "incarnation_description": ""}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('gcap3                     ', 'p', 1, '2020-09-19 21:39:17.245757+00', '2020-09-19 21:39:17.254094+00', '2020-09-19 21:39:17.245757+00', 'EventOperation', '{"type": "r", "entity_id": "src", "timestamp": "2020-09-19 23:34:42.65589+00", "event_ulid": "gcap3", "execution_id": "git-commit-and-push-3", "operation_id": "gcap3", "incarnation_id": "src-3", "entity_description": "./src/*", "incarnation_description": "./src/* #3"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dgcap1bb                  ', 'p', 1, '2020-09-19 21:54:22.429888+00', '2020-09-19 21:54:22.438761+00', '2020-09-19 21:54:22.429888+00', 'EventOperation', '{"type": "r", "entity_id": "repo", "execution_id": "checkout-3", "incarnation_id": "repo-3", "entity_description": "", "incarnation_description": ""}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dgcap1bt2b1               ', 'p', 1, '2020-09-19 21:57:54.106046+00', '2020-09-19 21:57:54.112916+00', '2020-09-19 21:57:54.106046+00', 'EventOperation', '{"type": "r", "entity_id": "tmp-store-1", "execution_id": "build-1", "incarnation_id": "tmp-store-1", "entity_description": "", "incarnation_description": ""}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dgcap1bt                  ', 'p', 1, '2020-09-19 21:55:31.050369+00', '2020-09-19 21:55:31.056307+00', '2020-09-19 21:55:31.050369+00', 'EventOperation', '{"type": "w", "entity_id": "tmp-store-1", "execution_id": "checkout-1", "incarnation_id": "tmp-store-1", "entity_description": "temp #2 src checkout", "incarnation_description": "temp #1 src checkout"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dgcap1bt2                 ', 'p', 1, '2020-09-19 21:55:51.337955+00', '2020-09-19 21:55:51.346914+00', '2020-09-19 21:55:51.337955+00', 'EventOperation', '{"type": "w", "entity_id": "tmp-store-3", "execution_id": "checkout-3", "incarnation_id": "tmp-store-3", "entity_description": "temp #2 src checkout", "incarnation_description": "temp #2 src checkout"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dgcap1bt2b                ', 'p', 1, '2020-09-19 21:57:39.876173+00', '2020-09-19 21:57:39.887142+00', '2020-09-19 21:57:39.876173+00', 'EventOperation', '{"type": "r", "entity_id": "tmp-store-3", "execution_id": "build-3", "incarnation_id": "tmp-store-3", "entity_description": "", "incarnation_description": ""}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dgcap1b                   ', 'p', 20, '2020-09-19 21:50:27.245512+00', '2020-09-19 21:52:16.805736+00', '2020-09-19 21:50:27.245512+00', 'EventOperation', '{"type": "r", "entity_id": "repo", "execution_id": "checkout-1", "incarnation_id": "repo-1", "entity_description": "", "incarnation_description": ""}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dgcabbbb-1                ', 'p', 1, '2020-09-19 22:14:20.308657+00', '2020-09-19 22:14:20.316788+00', '2020-09-19 22:14:20.308657+00', 'EventOperation', '{"type": "r", "entity_id": "tmp-src-1", "parent_id": "tmp-store-1", "execution_id": "build-1", "incarnation_id": "tmp-src-1", "entity_description": "temp #1 ./src/*", "incarnation_description": "temp #1 ./src/*"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dfbbbbb1                  ', 'p', 1, '2020-09-19 22:22:02.881363+00', '2020-09-19 22:22:02.887697+00', '2020-09-19 22:22:02.881363+00', 'EventOperation', '{"type": "w", "entity_id": "tmp-bin-1", "execution_id": "build-1", "incarnation_id": "tmp-bin-1", "entity_description": "temp #1 binary", "incarnation_description": "temp #1 binary"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dgcabbbb-3                ', 'p', 1, '2020-09-19 22:20:23.840772+00', '2020-09-19 22:20:23.848646+00', '2020-09-19 22:20:23.840772+00', 'EventOperation', '{"type": "r", "entity_id": "tmp-src-3", "parent_id": "tmp-store-3", "execution_id": "build-3", "incarnation_id": "tmp-src-3", "entity_description": "temp #2 ./src/*", "incarnation_description": "temp #2 ./src/*"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dfbbbbb3                  ', 'p', 1, '2020-09-19 22:22:32.763325+00', '2020-09-19 22:22:32.769806+00', '2020-09-19 22:22:32.763325+00', 'EventOperation', '{"type": "w", "entity_id": "tmp-bin-3", "execution_id": "build-3", "incarnation_id": "tmp-bin-3", "entity_description": "temp #2 binary", "incarnation_description": "temp #2 binary"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dfbbbbb3d                 ', 'p', 1, '2020-09-19 22:23:43.368225+00', '2020-09-19 22:23:43.374031+00', '2020-09-19 22:23:43.368225+00', 'EventOperation', '{"type": "r", "entity_id": "tmp-bin-3", "execution_id": "diff-3", "incarnation_id": "tmp-bin-3", "entity_description": "temp #2 binary", "incarnation_description": "temp #2 binary"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dfbbbbb1d                 ', 'p', 1, '2020-09-19 22:23:58.162363+00', '2020-09-19 22:23:58.167972+00', '2020-09-19 22:23:58.162363+00', 'EventOperation', '{"type": "r", "entity_id": "tmp-bin-1", "execution_id": "diff-1", "incarnation_id": "tmp-bin-1", "entity_description": "temp #1 binary", "incarnation_description": "temp #1 binary"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dfbbbd1                   ', 'p', 1, '2020-09-19 22:25:10.046597+00', '2020-09-19 22:25:10.054704+00', '2020-09-19 22:25:10.046597+00', 'EventOperation', '{"type": "r", "entity_id": "bin", "execution_id": "diff-1", "incarnation_id": "bin-0", "entity_description": "deployed binary", "incarnation_description": "binary #0"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dfbbbd3                   ', 'p', 1, '2020-09-19 22:25:29.574411+00', '2020-09-19 22:25:29.582392+00', '2020-09-19 22:25:29.574411+00', 'EventOperation', '{"type": "r", "entity_id": "bin", "execution_id": "diff-3", "incarnation_id": "bin-0", "entity_description": "deployed binary", "incarnation_description": "binary #0"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dfc3                      ', 'p', 1, '2020-09-19 22:26:26.166866+00', '2020-09-19 22:26:26.175133+00', '2020-09-19 22:26:26.166866+00', 'EventOperation', '{"type": "r", "entity_id": "tmp-bin-3", "execution_id": "copy-3", "incarnation_id": "tmp-bin-3", "entity_description": "temp #2 binary", "incarnation_description": "temp #2 binary"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dfc3w                     ', 'p', 1, '2020-09-19 22:27:07.98916+00', '2020-09-19 22:27:07.995312+00', '2020-09-19 22:27:07.98916+00', 'EventOperation', '{"type": "w", "entity_id": "bin", "execution_id": "copy-3", "incarnation_id": "bin-3", "entity_description": "deployed binary", "incarnation_description": "binary #3"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dfcs3                     ', 'p', 1, '2020-09-19 22:29:05.346176+00', '2020-09-19 22:29:05.352353+00', '2020-09-19 22:29:05.346176+00', 'EventOperation', '{"type": "w", "entity_id": "app", "execution_id": "stop-3", "incarnation_id": "app-0", "entity_description": "stopped app", "incarnation_description": "app #0"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dfcs3sa                   ', 'p', 1, '2020-09-19 22:30:15.89066+00', '2020-09-19 22:30:15.898644+00', '2020-09-19 22:30:15.89066+00', 'EventOperation', '{"type": "w", "entity_id": "app", "execution_id": "start-3", "incarnation_id": "app-3", "entity_description": "app", "incarnation_description": "app #3"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('dfcs3sar                  ', 'p', 1, '2020-09-19 22:30:52.501439+00', '2020-09-19 22:30:52.506313+00', '2020-09-19 22:30:52.501439+00', 'EventOperation', '{"type": "r", "entity_id": "bin", "execution_id": "start-3", "incarnation_id": "bin-3", "entity_description": "", "incarnation_description": ""}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('msg-1                     ', 'p', 28, '2020-09-19 23:36:40.222342+00', '2020-09-19 23:40:41.900376+00', '2020-09-19 23:36:40.222342+00', 'EventMessage', '{"sender": "git-commit-and-push-1", "target": "deployment-server", "interaction_id": "int-msg-1", "interaction_description": "notify commit #1"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('msg-2                     ', 'p', 1, '2020-09-20 00:00:53.410482+00', '2020-09-20 00:00:53.41773+00', '2020-09-20 00:00:53.410482+00', 'EventMessage', '{"sender": "git-commit-and-push-2", "target": "deployment-server", "interaction_id": "int-msg-2", "interaction_description": "notify commit #2"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('msg-3                     ', 'p', 1, '2020-09-20 00:01:07.917444+00', '2020-09-20 00:01:07.926094+00', '2020-09-20 00:01:07.917444+00', 'EventMessage', '{"sender": "git-commit-and-push-3", "target": "deployment-server", "interaction_id": "int-msg-3", "interaction_description": "notify commit #3"}') ON CONFLICT DO NOTHING;


--
-- Data for Name: executions; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.executions VALUES ('git-commit-and-push-1', '2020-09-19 21:33:55.707554+00', '2020-09-19 21:33:55.707554+00', NULL, NULL, NULL, 'git commit + git push #1', '2020-09-19 21:34:55.707554+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('git-commit-and-push-2', '2020-09-19 21:35:09.359734+00', '2020-09-19 21:35:09.359734+00', NULL, NULL, NULL, 'git commit + git push #2', '2020-09-19 21:36:09.359734+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('git-commit-and-push-3', '2020-09-19 21:38:37.7567+00', '2020-09-19 21:38:37.7567+00', NULL, NULL, NULL, 'git commit + git push #3', '2020-09-19 21:39:37.7567+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('deployment-server', '2020-09-19 21:40:17.722601+00', '2020-09-19 21:40:17.722601+00', NULL, NULL, NULL, 'deployment server loop', '2020-09-19 22:40:17.722601+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('deployment-1', '2020-09-19 21:40:42.987084+00', '2020-09-19 21:40:42.987084+00', 'deployment-server', NULL, NULL, 'deployment #1', '2020-09-19 22:40:42.987084+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('deployment-3', '2020-09-19 21:40:49.051576+00', '2020-09-19 21:40:49.051576+00', 'deployment-server', NULL, NULL, 'deployment #3', '2020-09-19 22:40:49.051576+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('checkout-1', '2020-09-19 21:45:03.317745+00', '2020-09-19 21:45:03.317745+00', 'deployment-1', NULL, NULL, 'checkout #1', '2020-09-19 21:46:03.317745+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('checkout-3', '2020-09-19 21:45:10.592684+00', '2020-09-19 21:45:10.592684+00', 'deployment-3', NULL, NULL, 'checkout #3', '2020-09-19 21:46:10.592684+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('build-1', '2020-09-19 21:57:06.641505+00', '2020-09-19 21:57:06.641505+00', 'deployment-1', NULL, NULL, 'build #1', '2020-09-19 21:58:06.641505+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('build-3', '2020-09-19 21:57:14.38028+00', '2020-09-19 21:57:14.38028+00', 'deployment-3', NULL, NULL, 'build #3', '2020-09-19 21:58:14.38028+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('diff-3', '2020-09-19 22:23:18.952718+00', '2020-09-19 22:23:18.952718+00', 'deployment-3', NULL, NULL, 'diff #3', '2020-09-19 22:24:18.952718+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('diff-1', '2020-09-19 22:23:25.902626+00', '2020-09-19 22:23:25.902626+00', 'deployment-1', NULL, NULL, 'diff #1', '2020-09-19 22:24:25.902626+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('copy-3', '2020-09-19 22:25:54.005951+00', '2020-09-19 22:25:54.005951+00', 'deployment-3', NULL, NULL, 'copy #3', '2020-09-19 22:26:54.005951+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('stop-3', '2020-09-19 22:28:35.607641+00', '2020-09-19 22:28:35.607641+00', 'deployment-3', NULL, NULL, 'stop #3', '2020-09-19 22:29:35.607641+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('start-3', '2020-09-19 22:29:26.884055+00', '2020-09-19 22:29:26.884055+00', 'deployment-3', NULL, NULL, 'start app #3', '2020-09-19 22:30:26.884055+00') ON CONFLICT DO NOTHING;


--
-- Data for Name: graph; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.graph VALUES ('src-1', 'read_by', 'git-commit-and-push-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('src-2', 'read_by', 'git-commit-and-push-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('src-3', 'read_by', 'git-commit-and-push-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo-3', 'read_by', 'deployment-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo-1', 'read_by', 'deployment-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo-1', 'read_by', 'checkout-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo-3', 'read_by', 'checkout-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-src-1', 'read_by', 'build-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-src-3', 'read_by', 'build-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-bin-3', 'read_by', 'diff-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-bin-1', 'read_by', 'diff-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('bin-0', 'read_by', 'diff-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('bin-0', 'read_by', 'diff-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-bin-3', 'read_by', 'copy-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('bin-3', 'read_by', 'start-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('git-commit-and-push-1', 'reads', 'src-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('git-commit-and-push-2', 'reads', 'src-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('git-commit-and-push-3', 'reads', 'src-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-3', 'reads', 'repo-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-1', 'reads', 'repo-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('checkout-1', 'reads', 'repo-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('checkout-3', 'reads', 'repo-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('build-1', 'reads', 'tmp-src-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('build-3', 'reads', 'tmp-src-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('diff-3', 'reads', 'tmp-bin-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('diff-1', 'reads', 'tmp-bin-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('diff-1', 'reads', 'bin-0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('diff-3', 'reads', 'bin-0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('copy-3', 'reads', 'tmp-bin-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('start-3', 'reads', 'bin-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('git-commit-and-push-1', 'writes', 'repo-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('git-commit-and-push-2', 'writes', 'repo-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('git-commit-and-push-3', 'writes', 'repo-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('checkout-1', 'writes', 'tmp-store-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('checkout-3', 'writes', 'tmp-store-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('build-1', 'writes', 'tmp-bin-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('build-3', 'writes', 'tmp-bin-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('copy-3', 'writes', 'bin-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('stop-3', 'writes', 'app-0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('start-3', 'writes', 'app-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo-1', 'written_by', 'git-commit-and-push-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo-2', 'written_by', 'git-commit-and-push-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo-3', 'written_by', 'git-commit-and-push-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-store-1', 'written_by', 'checkout-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-store-3', 'written_by', 'checkout-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-bin-1', 'written_by', 'build-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-bin-3', 'written_by', 'build-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('bin-3', 'written_by', 'copy-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('app-0', 'written_by', 'stop-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('app-3', 'written_by', 'start-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-1', 'child_of', 'deployment-server', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-3', 'child_of', 'deployment-server', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('checkout-1', 'child_of', 'deployment-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('checkout-3', 'child_of', 'deployment-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('build-1', 'child_of', 'deployment-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('build-3', 'child_of', 'deployment-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('diff-3', 'child_of', 'deployment-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('diff-1', 'child_of', 'deployment-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('copy-3', 'child_of', 'deployment-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('stop-3', 'child_of', 'deployment-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('start-3', 'child_of', 'deployment-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-server', 'parent_of', 'deployment-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-server', 'parent_of', 'deployment-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-1', 'parent_of', 'checkout-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-3', 'parent_of', 'checkout-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-1', 'parent_of', 'build-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-3', 'parent_of', 'build-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-3', 'parent_of', 'diff-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-1', 'parent_of', 'diff-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-3', 'parent_of', 'copy-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-3', 'parent_of', 'stop-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-3', 'parent_of', 'start-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('src-1', 'instance_of', 'src', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('src-2', 'instance_of', 'src', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo-2', 'instance_of', 'repo', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('src-3', 'instance_of', 'src', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo-1', 'instance_of', 'repo', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo-3', 'instance_of', 'repo', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-store-3', 'instance_of', 'tmp-store-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-store-1', 'instance_of', 'tmp-store-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-src-1', 'instance_of', 'tmp-src-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-src-3', 'instance_of', 'tmp-src-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-bin-1', 'instance_of', 'tmp-bin-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('bin-0', 'instance_of', 'bin', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-bin-3', 'instance_of', 'tmp-bin-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('app-0', 'instance_of', 'app', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('app-3', 'instance_of', 'app', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('bin-3', 'instance_of', 'bin', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('src', 'entity_of', 'src-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('src', 'entity_of', 'src-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo', 'entity_of', 'repo-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('src', 'entity_of', 'src-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo', 'entity_of', 'repo-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo', 'entity_of', 'repo-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-store-3', 'entity_of', 'tmp-store-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-store-1', 'entity_of', 'tmp-store-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-src-1', 'entity_of', 'tmp-src-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-src-3', 'entity_of', 'tmp-src-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-bin-1', 'entity_of', 'tmp-bin-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('bin', 'entity_of', 'bin-0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-bin-3', 'entity_of', 'tmp-bin-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('app', 'entity_of', 'app-0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('app', 'entity_of', 'app-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('bin', 'entity_of', 'bin-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('app-3', 'after', 'app-0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('app-0', 'before', 'app-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('bin-3', 'after', 'bin-0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('bin-0', 'before', 'bin-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo-2', 'after', 'repo-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo-1', 'before', 'repo-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo-3', 'after', 'repo-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('repo-2', 'before', 'repo-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('src-2', 'after', 'src-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('src-1', 'before', 'src-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('src-3', 'after', 'src-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('src-2', 'before', 'src-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-src-1', 'part_of', 'tmp-store-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-src-3', 'part_of', 'tmp-store-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-store-1', 'divides_into', 'tmp-src-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('tmp-store-3', 'divides_into', 'tmp-src-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('git-commit-and-push-1', 'sent_to', 'deployment-server', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-server', 'received_from', 'git-commit-and-push-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('git-commit-and-push-2', 'sent_to', 'deployment-server', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-server', 'received_from', 'git-commit-and-push-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('git-commit-and-push-3', 'sent_to', 'deployment-server', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deployment-server', 'received_from', 'git-commit-and-push-3', '{}') ON CONFLICT DO NOTHING;


--
-- Data for Name: incarnations; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.incarnations VALUES ('src-1', '2020-09-19 21:34:57.869683+00', 'src', NULL, './src/* #1', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('src-2', '2020-09-19 21:35:29.151998+00', 'src', NULL, './src/* #2', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('repo-2', '2020-09-19 21:36:50.485863+00', 'repo', 'git-commit-and-push-2', 'repo #2', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('src-3', '2020-09-19 21:39:17.254094+00', 'src', NULL, './src/* #3', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('repo-1', '2020-09-19 21:36:32.702626+00', 'repo', 'git-commit-and-push-1', 'repo #1', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('repo-3', '2020-09-19 21:38:56.019265+00', 'repo', 'git-commit-and-push-3', 'repo #3', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('tmp-store-3', '2020-09-19 21:55:51.346914+00', 'tmp-store-3', 'checkout-3', 'temp #2 src checkout', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('tmp-store-1', '2020-09-19 21:55:31.056307+00', 'tmp-store-1', 'checkout-1', 'temp #1 src checkout', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('tmp-src-1', '2020-09-19 22:14:20.316788+00', 'tmp-src-1', NULL, 'temp #1 ./src/*', 'tmp-store-1') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('tmp-src-3', '2020-09-19 22:20:23.848646+00', 'tmp-src-3', NULL, 'temp #2 ./src/*', 'tmp-store-3') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('tmp-bin-1', '2020-09-19 22:22:02.887697+00', 'tmp-bin-1', 'build-1', 'temp #1 binary', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('bin-0', '2020-09-19 22:25:10.054704+00', 'bin', NULL, 'binary #0', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('tmp-bin-3', '2020-09-19 22:22:32.769806+00', 'tmp-bin-3', 'build-3', 'temp #2 binary', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('app-0', '2020-09-19 22:29:05.352353+00', 'app', 'stop-3', 'app #0', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('app-3', '2020-09-19 22:30:15.898644+00', 'app', 'start-3', 'app #3', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('bin-3', '2020-09-19 22:27:07.995312+00', 'bin', 'copy-3', 'binary #3', NULL) ON CONFLICT DO NOTHING;


--
-- Data for Name: interactions; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.interactions VALUES ('int-msg-1', '2020-09-19 23:38:54.322309+00', '2020-09-19 23:36:40.222342+00', 'git-commit-and-push-1', 'deployment-server', 'notify commit #1') ON CONFLICT DO NOTHING;
INSERT INTO public.interactions VALUES ('int-msg-2', '2020-09-20 00:00:53.41773+00', '2020-09-20 00:00:53.410482+00', 'git-commit-and-push-2', 'deployment-server', 'notify commit #2') ON CONFLICT DO NOTHING;
INSERT INTO public.interactions VALUES ('int-msg-3', '2020-09-20 00:01:07.926094+00', '2020-09-20 00:01:07.917444+00', 'git-commit-and-push-3', 'deployment-server', 'notify commit #3') ON CONFLICT DO NOTHING;


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.messages VALUES ('msg-1                     ', '2020-09-19 23:40:41.900376+00', 'int-msg-1', '2020-09-19 23:36:40.222342+00', 'git-commit-and-push-1', 'deployment-server', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.messages VALUES ('msg-2                     ', '2020-09-20 00:00:53.41773+00', 'int-msg-2', '2020-09-20 00:00:53.410482+00', 'git-commit-and-push-2', 'deployment-server', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.messages VALUES ('msg-3                     ', '2020-09-20 00:01:07.926094+00', 'int-msg-3', '2020-09-20 00:01:07.917444+00', 'git-commit-and-push-3', 'deployment-server', NULL, NULL) ON CONFLICT DO NOTHING;


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.migrations VALUES (7, '2020-09-19 22:05:19.115872+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (9, '2020-09-19 22:05:19.120785+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (10, '2020-09-19 22:05:19.124912+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (11, '2020-09-19 22:05:19.127874+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (12, '2020-09-19 22:06:10.525477+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (1, '2020-09-19 22:06:59.954952+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (2, '2020-09-19 22:06:59.954952+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (3, '2020-09-19 22:06:59.954952+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (4, '2020-09-19 22:06:59.954952+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (5, '2020-09-19 22:06:59.954952+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (6, '2020-09-19 22:06:59.954952+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (8, '2020-09-19 22:06:59.954952+00') ON CONFLICT DO NOTHING;


--
-- Data for Name: operations; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.operations VALUES ('gcap1                     ', '2020-09-19 21:34:57.869683+00', '2020-09-19 23:34:42.65589+00', 'git-commit-and-push-1', 'r', 'src', 'src-1', './src/*', './src/* #1') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('gcap2                     ', '2020-09-19 21:35:29.151998+00', '2020-09-19 23:34:42.65589+00', 'git-commit-and-push-2', 'r', 'src', 'src-2', './src/*', './src/* #2') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('gcap1-1                   ', '2020-09-19 21:36:32.702626+00', '2020-09-19 23:34:42.65589+00', 'git-commit-and-push-1', 'w', 'repo', 'repo-1', 'repo', 'repo #1') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('gcap2-1                   ', '2020-09-19 21:36:50.485863+00', '2020-09-19 23:34:42.65589+00', 'git-commit-and-push-2', 'w', 'repo', 'repo-2', 'repo', 'repo #2') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('gcap3-1                   ', '2020-09-19 21:38:56.019265+00', '2020-09-19 23:34:42.65589+00', 'git-commit-and-push-3', 'w', 'repo', 'repo-3', 'repo', 'repo #3') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('gcap3                     ', '2020-09-19 21:39:17.254094+00', '2020-09-19 23:34:42.65589+00', 'git-commit-and-push-3', 'r', 'src', 'src-3', './src/*', './src/* #3') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dgcap3                    ', '2020-09-19 21:42:41.152077+00', '2020-09-19 23:42:42.65589+00', 'deployment-3', 'r', 'repo', 'repo-3', '', '') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dgcap1                    ', '2020-09-19 21:42:59.58418+00', '2020-09-19 23:41:42.65589+00', 'deployment-1', 'r', 'repo', 'repo-1', '', '') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dgcap1b                   ', '2020-09-19 21:52:16.805736+00', '2020-09-19 21:50:27.245512+00', 'checkout-1', 'r', 'repo', 'repo-1', '', '') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dgcap1bb                  ', '2020-09-19 21:54:22.438761+00', '2020-09-19 21:54:22.429888+00', 'checkout-3', 'r', 'repo', 'repo-3', '', '') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dgcap1bt                  ', '2020-09-19 21:55:31.056307+00', '2020-09-19 21:55:31.050369+00', 'checkout-1', 'w', 'tmp-store-1', 'tmp-store-1', 'temp #2 src checkout', 'temp #1 src checkout') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dgcap1bt2                 ', '2020-09-19 21:55:51.346914+00', '2020-09-19 21:55:51.337955+00', 'checkout-3', 'w', 'tmp-store-3', 'tmp-store-3', 'temp #2 src checkout', 'temp #2 src checkout') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dgcabbbb-1                ', '2020-09-19 22:14:20.316788+00', '2020-09-19 22:14:20.308657+00', 'build-1', 'r', 'tmp-src-1', 'tmp-src-1', 'temp #1 ./src/*', 'temp #1 ./src/*') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dgcabbbb-3                ', '2020-09-19 22:20:23.848646+00', '2020-09-19 22:20:23.840772+00', 'build-3', 'r', 'tmp-src-3', 'tmp-src-3', 'temp #2 ./src/*', 'temp #2 ./src/*') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dfbbbbb1                  ', '2020-09-19 22:22:02.887697+00', '2020-09-19 22:22:02.881363+00', 'build-1', 'w', 'tmp-bin-1', 'tmp-bin-1', 'temp #1 binary', 'temp #1 binary') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dfbbbbb3                  ', '2020-09-19 22:22:32.769806+00', '2020-09-19 22:22:32.763325+00', 'build-3', 'w', 'tmp-bin-3', 'tmp-bin-3', 'temp #2 binary', 'temp #2 binary') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dfbbbbb3d                 ', '2020-09-19 22:23:43.374031+00', '2020-09-19 22:23:43.368225+00', 'diff-3', 'r', 'tmp-bin-3', 'tmp-bin-3', 'temp #2 binary', 'temp #2 binary') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dfbbbbb1d                 ', '2020-09-19 22:23:58.167972+00', '2020-09-19 22:23:58.162363+00', 'diff-1', 'r', 'tmp-bin-1', 'tmp-bin-1', 'temp #1 binary', 'temp #1 binary') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dfbbbd1                   ', '2020-09-19 22:25:10.054704+00', '2020-09-19 22:25:10.046597+00', 'diff-1', 'r', 'bin', 'bin-0', 'deployed binary', 'binary #0') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dfbbbd3                   ', '2020-09-19 22:25:29.582392+00', '2020-09-19 22:25:29.574411+00', 'diff-3', 'r', 'bin', 'bin-0', 'deployed binary', 'binary #0') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dfc3                      ', '2020-09-19 22:26:26.175133+00', '2020-09-19 22:26:26.166866+00', 'copy-3', 'r', 'tmp-bin-3', 'tmp-bin-3', 'temp #2 binary', 'temp #2 binary') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dfc3w                     ', '2020-09-19 22:27:07.995312+00', '2020-09-19 22:27:07.98916+00', 'copy-3', 'w', 'bin', 'bin-3', 'deployed binary', 'binary #3') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dfcs3                     ', '2020-09-19 22:29:05.352353+00', '2020-09-19 22:29:05.346176+00', 'stop-3', 'w', 'app', 'app-0', 'stopped app', 'app #0') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dfcs3sa                   ', '2020-09-19 22:30:15.898644+00', '2020-09-19 22:30:15.89066+00', 'start-3', 'w', 'app', 'app-3', 'app', 'app #3') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('dfcs3sar                  ', '2020-09-19 22:30:52.506313+00', '2020-09-19 22:30:52.501439+00', 'start-3', 'r', 'bin', 'bin-3', '', '') ON CONFLICT DO NOTHING;


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
-- Name: incarnations fk_parent_id; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.incarnations
    ADD CONSTRAINT fk_parent_id FOREIGN KEY (parent_id) REFERENCES public.incarnations(incarnation_id);


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
-- Name: interactions interactions_initiator_participant_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.interactions
    ADD CONSTRAINT interactions_initiator_participant_fkey FOREIGN KEY (initiator_participant) REFERENCES public.executions(execution_id);


--
-- Name: interactions interactions_responder_participant_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.interactions
    ADD CONSTRAINT interactions_responder_participant_fkey FOREIGN KEY (responder_participant) REFERENCES public.executions(execution_id);


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

