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
-- Name: triple; Type: TYPE; Schema: public; Owner: tenmo
--

CREATE TYPE public.triple AS (
	source text,
	verb text,
	target text
);


ALTER TYPE public.triple OWNER TO tenmo;

--
-- Name: assert(text, text); Type: PROCEDURE; Schema: public; Owner: tenmo
--

CREATE PROCEDURE public.assert(sourcein text, targetin text)
    LANGUAGE sql
    AS $$

  call assert(sourceIn, targetIn, '');

  $$;


ALTER PROCEDURE public.assert(sourcein text, targetin text) OWNER TO tenmo;

--
-- Name: assert(text, text, text); Type: PROCEDURE; Schema: public; Owner: tenmo
--

CREATE PROCEDURE public.assert(sourcein text, targetin text, comment text)
    LANGUAGE sql
    AS $$

  insert into asserts (source, target, comment)
  select sourcein, targetin, comment
  on conflict do nothing;

  call populate_graph();

  $$;


ALTER PROCEDURE public.assert(sourcein text, targetin text, comment text) OWNER TO tenmo;

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

CREATE FUNCTION public.get_all_paths_from_by_verbs(start text, crawl_verbs text[]) RETURNS TABLE(depth integer, verbs text[], path text[])
    LANGUAGE plpgsql
    AS $$
  BEGIN
  RETURN QUERY

  WITH RECURSIVE search_step(id, link, verb, depth, route, verbs, cycle) AS (
    SELECT r.source, r.target, r.verb, 1,
           ARRAY[r.source],
           ARRAY[r.verb]::text[],
           false
      FROM graph r where r.source=start and r.verb = ANY(crawl_verbs)

     UNION ALL

    SELECT r.source, r.target, r.verb, sp.depth+1,
           sp.route || r.source,
           sp.verbs || r.verb,
           r.source = ANY(route)
      FROM graph r, search_step sp
     WHERE r.source = sp.link AND NOT cycle and r.verb = ANY(crawl_verbs)
  )
  SELECT sp.depth, array_append(sp.verbs, '<end>') AS verbs, sp.route || sp.link AS path
  FROM search_step AS sp
  WHERE NOT cycle
  ORDER BY depth ASC;

  END;
  $$;


ALTER FUNCTION public.get_all_paths_from_by_verbs(start text, crawl_verbs text[]) OWNER TO tenmo;

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
  select t.source, 'assert', t.target from asserts t
  union all
  select t.target, 'assert_reverse', t.source from asserts t
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
-- Name: asserts; Type: TABLE; Schema: public; Owner: tenmo
--

CREATE TABLE public.asserts (
    source text NOT NULL,
    target text NOT NULL,
    comment text DEFAULT ''::text
);


ALTER TABLE public.asserts OWNER TO tenmo;

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
-- Data for Name: asserts; Type: TABLE DATA; Schema: public; Owner: tenmo
--



--
-- Data for Name: entities; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.entities VALUES ('e:///home/gleber/code/nix/tests/simple.deps.builder.sh', '2020-09-20 15:56:44.341022+00', 'NSO /home/gleber/code/nix/tests/simple.deps.builder.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', '2020-09-20 15:56:44.349422+00', 'NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', '2020-09-20 15:56:44.376863+00', 'NSO /run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', '2020-09-20 15:56:44.471595+00', 'NSO /run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', '2020-09-20 15:56:44.482396+00', 'NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', '2020-09-20 15:56:44.505517+00', 'NSO /run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top', '2020-09-20 15:56:44.588975+00', 'NSO /run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top') ON CONFLICT DO NOTHING;


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.events VALUES ('01EJP3PNKH41F4QX56FTR3WHS9', 'p', 1, '2020-09-20 15:56:44.203943+00', '2020-09-20 15:56:44.244228+00', '2020-09-20 15:55:26.499597+00', 'EventExecutionBegins', '{"parent_id": "123471719825408", "timestamp": "2020-09-20T15:55:26.499597", "creator_id": null, "event_ulid": "01EJP3PNKH41F4QX56FTR3WHS9", "process_id": null, "description": "_main.eval", "execution_id": "123471719825410"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNKF2QGRRHFVSX149SFP', 'p', 1, '2020-09-20 15:56:44.188097+00', '2020-09-20 15:56:44.203364+00', '2020-09-20 15:55:26.499422+00', 'EventExecutionBegins', '{"parent_id": null, "timestamp": "2020-09-20T15:55:26.499422", "creator_id": null, "event_ulid": "01EJP3PNKF2QGRRHFVSX149SFP", "process_id": null, "description": "_main", "execution_id": "123471719825408"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNKGF14C773MCAWA4KJG', 'p', 1, '2020-09-20 15:56:44.195084+00', '2020-09-20 15:56:44.218477+00', '2020-09-20 15:55:26.499503+00', 'EventExecutionBegins', '{"parent_id": "123471719825408", "timestamp": "2020-09-20T15:55:26.499503", "creator_id": null, "event_ulid": "01EJP3PNKGF14C773MCAWA4KJG", "process_id": null, "description": "evaluating file ''/home/gleber/code/nix/inst/share/nix/corepkgs/derivation.nix''", "execution_id": "123471719825409"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNKHBD0MCY8P4BWAWMQX', 'p', 1, '2020-09-20 15:56:44.198846+00', '2020-09-20 15:56:44.232652+00', '2020-09-20 15:55:26.499554+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.499554", "event_ulid": "01EJP3PNKHBD0MCY8P4BWAWMQX", "execution_id": "123471719825409"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNKJ9Y04KDPRWPGZ6KTY', 'p', 1, '2020-09-20 15:56:44.207373+00', '2020-09-20 15:56:44.256005+00', '2020-09-20 15:55:26.499643+00', 'EventExecutionBegins', '{"parent_id": "123471719825410", "timestamp": "2020-09-20T15:55:26.499643", "creator_id": null, "event_ulid": "01EJP3PNKJ9Y04KDPRWPGZ6KTY", "process_id": null, "description": "evaluating file ''/home/gleber/code/nix/tests/config.nix''", "execution_id": "123471719825411"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNKJJRPKMHX483HBQVDB', 'p', 1, '2020-09-20 15:56:44.212581+00', '2020-09-20 15:56:44.278798+00', '2020-09-20 15:55:26.499691+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.499691", "event_ulid": "01EJP3PNKJJRPKMHX483HBQVDB", "execution_id": "123471719825411"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNKJDHTATB49TTV9B3HA', 'p', 1, '2020-09-20 15:56:44.217746+00', '2020-09-20 15:56:44.289195+00', '2020-09-20 15:55:26.499737+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.499737", "event_ulid": "01EJP3PNKJDHTATB49TTV9B3HA", "execution_id": "123471719825410"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNKKMAKEHDH0XNV66N2H', 'p', 1, '2020-09-20 15:56:44.220736+00', '2020-09-20 15:56:44.300125+00', '2020-09-20 15:55:26.499783+00', 'EventExecutionBegins', '{"parent_id": "123471719825408", "timestamp": "2020-09-20T15:55:26.499783", "creator_id": null, "event_ulid": "01EJP3PNKKMAKEHDH0XNV66N2H", "process_id": null, "description": "preparing build of 1 derivations", "execution_id": "123471719825412"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNKKEHP7BCZ1K5F80MPX', 'p', 1, '2020-09-20 15:56:44.224849+00', '2020-09-20 15:56:44.311351+00', '2020-09-20 15:55:26.49984+00', 'EventExecutionBegins', '{"parent_id": "123471719825412", "timestamp": "2020-09-20T15:55:26.499840", "creator_id": null, "event_ulid": "01EJP3PNKKEHP7BCZ1K5F80MPX", "process_id": null, "description": "derivation ''dependencies-top'' being evaled", "execution_id": "123471719825413"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNMEW5SD1YT8ZMA2WFH8', 'p', 1, '2020-09-20 15:56:44.261902+00', '2020-09-20 15:56:44.322786+00', '2020-09-20 15:55:26.50156+00', 'EventExecutionBegins', '{"parent_id": "123471719825412", "timestamp": "2020-09-20T15:55:26.501560", "creator_id": null, "event_ulid": "01EJP3PNMEW5SD1YT8ZMA2WFH8", "process_id": null, "description": "building 1 paths", "execution_id": "123471719825416"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNKMFGT6SR0J3A9Y1Z6Y', 'p', 1, '2020-09-20 15:56:44.227646+00', '2020-09-20 15:56:44.333282+00', '2020-09-20 15:55:26.49989+00', 'EventExecutionBegins', '{"parent_id": "123471719825413", "timestamp": "2020-09-20T15:55:26.499890", "creator_id": null, "event_ulid": "01EJP3PNKMFGT6SR0J3A9Y1Z6Y", "process_id": null, "description": "copying referenced file", "execution_id": "123471719825414"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNKMQ0W1PNHV2PRBA68Z', 'p', 1, '2020-09-20 15:56:44.231711+00', '2020-09-20 15:56:44.341022+00', '2020-09-20 15:55:26.499933+00', 'EventOperation', '{"type": "r", "entity_id": "e:///home/gleber/code/nix/tests/simple.deps.builder.sh", "timestamp": "2020-09-20T15:55:26.499933", "event_ulid": "01EJP3PNKMQ0W1PNHV2PRBA68Z", "execution_id": "123471719825414", "operation_id": "123471719825414-01EJP3PNKMQ0W1PNHV2PRBA68Z", "incarnation_id": "i:///home/gleber/code/nix/tests/simple.deps.builder.sh", "entity_description": "NSO /home/gleber/code/nix/tests/simple.deps.builder.sh", "incarnation_description": "NSO /home/gleber/code/nix/tests/simple.deps.builder.sh"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNKR1382ZSG0PNV8DJJY', 'p', 1, '2020-09-20 15:56:44.234738+00', '2020-09-20 15:56:44.349422+00', '2020-09-20 15:55:26.500409+00', 'EventOperation', '{"type": "w", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh", "timestamp": "2020-09-20T15:55:26.500409", "event_ulid": "01EJP3PNKR1382ZSG0PNV8DJJY", "execution_id": "123471719825414", "operation_id": "123471719825414-01EJP3PNKR1382ZSG0PNV8DJJY", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNKRQZNEBPXCZ18SKMXK', 'p', 1, '2020-09-20 15:56:44.23907+00', '2020-09-20 15:56:44.357887+00', '2020-09-20 15:55:26.500457+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.500457", "event_ulid": "01EJP3PNKRQZNEBPXCZ18SKMXK", "execution_id": "123471719825414"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNKSXMSNWDH69M3TE9FZ', 'p', 1, '2020-09-20 15:56:44.243177+00', '2020-09-20 15:56:44.364069+00', '2020-09-20 15:55:26.500501+00', 'EventExecutionBegins', '{"parent_id": "123471719825413", "timestamp": "2020-09-20T15:55:26.500501", "creator_id": null, "event_ulid": "01EJP3PNKSXMSNWDH69M3TE9FZ", "process_id": null, "description": "derivation ''dependencies-input-0'' being evaled", "execution_id": "123471719825415"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNMAZ6ATA3TXAJSBXA9P', 'p', 1, '2020-09-20 15:56:44.250441+00', '2020-09-20 15:56:44.370166+00', '2020-09-20 15:55:26.501125+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.501125", "event_ulid": "01EJP3PNMAZ6ATA3TXAJSBXA9P", "execution_id": "123471719825415"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNMDHJ8PV1HZ8320ZFDJ', 'p', 1, '2020-09-20 15:56:44.254781+00', '2020-09-20 15:56:44.376863+00', '2020-09-20 15:55:26.501467+00', 'EventOperation', '{"type": "w", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv", "timestamp": "2020-09-20T15:55:26.501467", "event_ulid": "01EJP3PNMDHJ8PV1HZ8320ZFDJ", "execution_id": "123471719825413", "operation_id": "123471719825413-01EJP3PNMDHJ8PV1HZ8320ZFDJ", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNMD02RY9V0NN7TR7NM9', 'p', 1, '2020-09-20 15:56:44.257728+00', '2020-09-20 15:56:44.384106+00', '2020-09-20 15:55:26.501512+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.501512", "event_ulid": "01EJP3PNMD02RY9V0NN7TR7NM9", "execution_id": "123471719825413"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNN5X3EVYKXQH0WRPVK4', 'p', 1, '2020-09-20 15:56:44.293464+00', '2020-09-20 15:56:44.449144+00', '2020-09-20 15:55:26.503185+00', 'EventOperation', '{"type": "r", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv", "timestamp": "2020-09-20T15:55:26.503185", "event_ulid": "01EJP3PNN5X3EVYKXQH0WRPVK4", "execution_id": "123471719825422", "operation_id": "123471719825422-01EJP3PNN5X3EVYKXQH0WRPVK4", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNMA57GBHAKKMQ46MM0C', 'p', 2, '2020-09-20 15:56:44.246142+00', '2020-09-20 15:56:50.114101+00', '2020-09-20 15:55:26.501027+00', 'EventOperation', '{"type": "w", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv", "timestamp": "2020-09-20T15:55:26.501027", "event_ulid": "01EJP3PNMA57GBHAKKMQ46MM0C", "execution_id": "123471719825415", "operation_id": "123471719825415-01EJP3PNMA57GBHAKKMQ46MM0C", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNQHFXY0TRVKQXVNJY16', 'p', 1, '2020-09-20 15:56:44.306228+00', '2020-09-20 15:56:44.526796+00', '2020-09-20 15:55:26.524721+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.524721", "event_ulid": "01EJP3PNQHFXY0TRVKQXVNJY16", "execution_id": "123471719825423"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNME2DR378474CD9PDMK', 'p', 1, '2020-09-20 15:56:44.265932+00', '2020-09-20 15:56:44.391967+00', '2020-09-20 15:55:26.50161+00', 'EventExecutionBegins', '{"parent_id": "123471719825416", "timestamp": "2020-09-20T15:55:26.501610", "creator_id": null, "event_ulid": "01EJP3PNME2DR378474CD9PDMK", "process_id": null, "description": "querying info about missing paths", "execution_id": "123471719825417"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNMFC1CCMA84WHV4N35P', 'p', 1, '2020-09-20 15:56:44.268833+00', '2020-09-20 15:56:44.398035+00', '2020-09-20 15:55:26.501696+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.501696", "event_ulid": "01EJP3PNMFC1CCMA84WHV4N35P", "execution_id": "123471719825417"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNMG5ZAJWRXNPF5DPJ3S', 'p', 1, '2020-09-20 15:56:44.271634+00', '2020-09-20 15:56:44.404275+00', '2020-09-20 15:55:26.501949+00', 'EventExecutionBegins', '{"parent_id": "123471719825416", "timestamp": "2020-09-20T15:55:26.501949", "creator_id": null, "event_ulid": "01EJP3PNMG5ZAJWRXNPF5DPJ3S", "process_id": null, "description": "", "execution_id": "123471719825418"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNMH1K89YJ4MR2VDCWG8', 'p', 1, '2020-09-20 15:56:44.27458+00', '2020-09-20 15:56:44.410351+00', '2020-09-20 15:55:26.501993+00', 'EventExecutionBegins', '{"parent_id": "123471719825416", "timestamp": "2020-09-20T15:55:26.501993", "creator_id": null, "event_ulid": "01EJP3PNMH1K89YJ4MR2VDCWG8", "process_id": null, "description": "", "execution_id": "123471719825419"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNMHZQMT2BSE44F6WDV8', 'p', 1, '2020-09-20 15:56:44.279505+00', '2020-09-20 15:56:44.418591+00', '2020-09-20 15:55:26.50204+00', 'EventExecutionBegins', '{"parent_id": "123471719825416", "timestamp": "2020-09-20T15:55:26.502040", "creator_id": null, "event_ulid": "01EJP3PNMHZQMT2BSE44F6WDV8", "process_id": null, "description": "", "execution_id": "123471719825420"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNMJYF1ZWKHRSFMRTA43', 'p', 1, '2020-09-20 15:56:44.284428+00', '2020-09-20 15:56:44.425312+00', '2020-09-20 15:55:26.502087+00', 'EventExecutionBegins', '{"parent_id": "123471719825416", "timestamp": "2020-09-20T15:55:26.502087", "creator_id": null, "event_ulid": "01EJP3PNMJYF1ZWKHRSFMRTA43", "process_id": null, "description": "querying info about missing paths", "execution_id": "123471719825421"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNMJCGWYHPBJAEK96D2B', 'p', 1, '2020-09-20 15:56:44.288543+00', '2020-09-20 15:56:44.431368+00', '2020-09-20 15:55:26.502189+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.502189", "event_ulid": "01EJP3PNMJCGWYHPBJAEK96D2B", "execution_id": "123471719825421"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNMKEC7FHX6B0CM3GHJ2', 'p', 1, '2020-09-20 15:56:44.291394+00', '2020-09-20 15:56:44.437908+00', '2020-09-20 15:55:26.50236+00', 'EventExecutionBegins', '{"parent_id": "123471719825416", "timestamp": "2020-09-20T15:55:26.502360", "creator_id": null, "event_ulid": "01EJP3PNMKEC7FHX6B0CM3GHJ2", "process_id": null, "description": "overall building ''/run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv''", "execution_id": "123471719825422"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNNBBCR2FXRB8MTA7NXY', 'p', 1, '2020-09-20 15:56:44.295279+00', '2020-09-20 15:56:44.461128+00', '2020-09-20 15:55:26.503914+00', 'EventExecutionBegins', '{"parent_id": "123471719825416", "timestamp": "2020-09-20T15:55:26.503914", "creator_id": null, "event_ulid": "01EJP3PNNBBCR2FXRB8MTA7NXY", "process_id": null, "description": "overall building ''/run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv''", "execution_id": "123471719825423"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNP8G269F58MHF6MWY2Q', 'p', 1, '2020-09-20 15:56:44.297345+00', '2020-09-20 15:56:44.471595+00', '2020-09-20 15:55:26.504416+00', 'EventOperation', '{"type": "r", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv", "timestamp": "2020-09-20T15:55:26.504416", "event_ulid": "01EJP3PNP8G269F58MHF6MWY2Q", "execution_id": "123471719825423", "operation_id": "123471719825423-01EJP3PNP8G269F58MHF6MWY2Q", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNPF5WEJ9ZJVJF46RC8B', 'p', 1, '2020-09-20 15:56:44.299114+00', '2020-09-20 15:56:44.482396+00', '2020-09-20 15:55:26.505113+00', 'EventOperation', '{"type": "r", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh", "timestamp": "2020-09-20T15:55:26.505113", "event_ulid": "01EJP3PNPF5WEJ9ZJVJF46RC8B", "execution_id": "123471719825423", "operation_id": "123471719825423-01EJP3PNPF5WEJ9ZJVJF46RC8B", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNQ8D4TBR4AZEJJVXFTM', 'p', 1, '2020-09-20 15:56:44.300807+00', '2020-09-20 15:56:44.494732+00', '2020-09-20 15:55:26.521197+00', 'EventExecutionBegins', '{"parent_id": "123471719825423", "timestamp": "2020-09-20T15:55:26.521197", "creator_id": null, "event_ulid": "01EJP3PNQ8D4TBR4AZEJJVXFTM", "process_id": null, "description": "building ''/run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv''", "execution_id": "123471719825424"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNQDWPXR1ZK28NG7300V', 'p', 1, '2020-09-20 15:56:44.302475+00', '2020-09-20 15:56:44.505517+00', '2020-09-20 15:55:26.523894+00', 'EventOperation', '{"type": "w", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0", "timestamp": "2020-09-20T15:55:26.523894", "event_ulid": "01EJP3PNQDWPXR1ZK28NG7300V", "execution_id": "123471719825423", "operation_id": "123471719825423-01EJP3PNQDWPXR1ZK28NG7300V", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNQHD80PKGCJA8EGTR7X', 'p', 1, '2020-09-20 15:56:44.304549+00', '2020-09-20 15:56:44.517044+00', '2020-09-20 15:55:26.524675+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.524675", "event_ulid": "01EJP3PNQHD80PKGCJA8EGTR7X", "execution_id": "123471719825424"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNQKMEJFXK39W4V23CC7', 'p', 1, '2020-09-20 15:56:44.310904+00', '2020-09-20 15:56:44.547932+00', '2020-09-20 15:55:26.524921+00', 'EventOperation', '{"type": "r", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0", "timestamp": "2020-09-20T15:55:26.524921", "event_ulid": "01EJP3PNQKMEJFXK39W4V23CC7", "execution_id": "123471719825422", "operation_id": "123471719825422-01EJP3PNQKMEJFXK39W4V23CC7", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNQKBQEZ5TRN4QA87WRA', 'p', 1, '2020-09-20 15:56:44.308959+00', '2020-09-20 15:56:44.536746+00', '2020-09-20 15:55:26.524871+00', 'EventOperation', '{"type": "r", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv", "timestamp": "2020-09-20T15:55:26.524871", "event_ulid": "01EJP3PNQKBQEZ5TRN4QA87WRA", "execution_id": "123471719825422", "operation_id": "123471719825422-01EJP3PNQKBQEZ5TRN4QA87WRA", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNRCKJ3V0WJ2AFE425R5', 'p', 1, '2020-09-20 15:56:44.31658+00', '2020-09-20 15:56:44.588975+00', '2020-09-20 15:55:26.543839+00', 'EventOperation', '{"type": "w", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top", "timestamp": "2020-09-20T15:55:26.543839", "event_ulid": "01EJP3PNRCKJ3V0WJ2AFE425R5", "execution_id": "123471719825422", "operation_id": "123471719825422-01EJP3PNRCKJ3V0WJ2AFE425R5", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNR2P5FSKZ01HCA3Q6BN', 'p', 1, '2020-09-20 15:56:44.314902+00', '2020-09-20 15:56:44.575976+00', '2020-09-20 15:55:26.529035+00', 'EventExecutionBegins', '{"parent_id": "123471719825422", "timestamp": "2020-09-20T15:55:26.529035", "creator_id": null, "event_ulid": "01EJP3PNR2P5FSKZ01HCA3Q6BN", "process_id": null, "description": "building ''/run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv''", "execution_id": "123471719825425"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNQM8J18RYVSZGE974VP', 'p', 1, '2020-09-20 15:56:44.312617+00', '2020-09-20 15:56:44.562258+00', '2020-09-20 15:55:26.524974+00', 'EventOperation', '{"type": "r", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh", "timestamp": "2020-09-20T15:55:26.524974", "event_ulid": "01EJP3PNQM8J18RYVSZGE974VP", "execution_id": "123471719825422", "operation_id": "123471719825422-01EJP3PNQM8J18RYVSZGE974VP", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNRHP1W0J2K8AA3HYE1Q', 'p', 1, '2020-09-20 15:56:44.328635+00', '2020-09-20 15:56:44.661451+00', '2020-09-20 15:55:26.544598+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.544598", "event_ulid": "01EJP3PNRHP1W0J2K8AA3HYE1Q", "execution_id": "123471719825416"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNRG2RATQGJKQCJAANQ8', 'p', 1, '2020-09-20 15:56:44.322253+00', '2020-09-20 15:56:44.626593+00', '2020-09-20 15:55:26.544443+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.544443", "event_ulid": "01EJP3PNRG2RATQGJKQCJAANQ8", "execution_id": "123471719825420"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNRFM5TH364T9N2X5PBF', 'p', 1, '2020-09-20 15:56:44.318673+00', '2020-09-20 15:56:44.600988+00', '2020-09-20 15:55:26.544292+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.544292", "event_ulid": "01EJP3PNRFM5TH364T9N2X5PBF", "execution_id": "123471719825425"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNRFKANTQD3ZCJQZACR3', 'p', 1, '2020-09-20 15:56:44.320468+00', '2020-09-20 15:56:44.6103+00', '2020-09-20 15:55:26.544339+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.544339", "event_ulid": "01EJP3PNRFKANTQD3ZCJQZACR3", "execution_id": "123471719825422"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNRH5AFWV3A3TP3XQZTV', 'p', 1, '2020-09-20 15:56:44.324067+00', '2020-09-20 15:56:44.638752+00', '2020-09-20 15:55:26.544493+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.544493", "event_ulid": "01EJP3PNRH5AFWV3A3TP3XQZTV", "execution_id": "123471719825419"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNRJZXJN5SXC5EAPYTXK', 'p', 1, '2020-09-20 15:56:44.330728+00', '2020-09-20 15:56:44.669105+00', '2020-09-20 15:55:26.544694+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.544694", "event_ulid": "01EJP3PNRJZXJN5SXC5EAPYTXK", "execution_id": "123471719825412"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNRHYZR7D88TMRR0653V', 'p', 1, '2020-09-20 15:56:44.326682+00', '2020-09-20 15:56:44.653246+00', '2020-09-20 15:55:26.544546+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.544546", "event_ulid": "01EJP3PNRHYZR7D88TMRR0653V", "execution_id": "123471719825418"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP3PNRJN0AF4PBM1XQNB7M3', 'p', 1, '2020-09-20 15:56:44.33325+00', '2020-09-20 15:56:44.678807+00', '2020-09-20 15:55:26.544751+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T15:55:26.544751", "event_ulid": "01EJP3PNRJN0AF4PBM1XQNB7M3", "execution_id": "123471719825408"}') ON CONFLICT DO NOTHING;


--
-- Data for Name: executions; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.executions VALUES ('123471719825409', '2020-09-20 15:56:44.218477+00', '2020-09-20 15:55:26.499503+00', '123471719825408', NULL, NULL, 'evaluating file ''/home/gleber/code/nix/inst/share/nix/corepkgs/derivation.nix''', '2020-09-20 15:55:26.499554+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825411', '2020-09-20 15:56:44.256005+00', '2020-09-20 15:55:26.499643+00', '123471719825410', NULL, NULL, 'evaluating file ''/home/gleber/code/nix/tests/config.nix''', '2020-09-20 15:55:26.499691+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825410', '2020-09-20 15:56:44.244228+00', '2020-09-20 15:55:26.499597+00', '123471719825408', NULL, NULL, '_main.eval', '2020-09-20 15:55:26.499737+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825414', '2020-09-20 15:56:44.333282+00', '2020-09-20 15:55:26.49989+00', '123471719825413', NULL, NULL, 'copying referenced file', '2020-09-20 15:55:26.500457+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825415', '2020-09-20 15:56:44.364069+00', '2020-09-20 15:55:26.500501+00', '123471719825413', NULL, NULL, 'derivation ''dependencies-input-0'' being evaled', '2020-09-20 15:55:26.501125+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825413', '2020-09-20 15:56:44.311351+00', '2020-09-20 15:55:26.49984+00', '123471719825412', NULL, NULL, 'derivation ''dependencies-top'' being evaled', '2020-09-20 15:55:26.501512+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825417', '2020-09-20 15:56:44.391967+00', '2020-09-20 15:55:26.50161+00', '123471719825416', NULL, NULL, 'querying info about missing paths', '2020-09-20 15:55:26.501696+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825421', '2020-09-20 15:56:44.425312+00', '2020-09-20 15:55:26.502087+00', '123471719825416', NULL, NULL, 'querying info about missing paths', '2020-09-20 15:55:26.502189+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825424', '2020-09-20 15:56:44.494732+00', '2020-09-20 15:55:26.521197+00', '123471719825423', NULL, NULL, 'building ''/run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv''', '2020-09-20 15:55:26.524675+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825423', '2020-09-20 15:56:44.461128+00', '2020-09-20 15:55:26.503914+00', '123471719825416', NULL, NULL, 'overall building ''/run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv''', '2020-09-20 15:55:26.524721+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825425', '2020-09-20 15:56:44.575976+00', '2020-09-20 15:55:26.529035+00', '123471719825422', NULL, NULL, 'building ''/run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv''', '2020-09-20 15:55:26.544292+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825422', '2020-09-20 15:56:44.437908+00', '2020-09-20 15:55:26.50236+00', '123471719825416', NULL, NULL, 'overall building ''/run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv''', '2020-09-20 15:55:26.544339+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825420', '2020-09-20 15:56:44.418591+00', '2020-09-20 15:55:26.50204+00', '123471719825416', NULL, NULL, '', '2020-09-20 15:55:26.544443+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825419', '2020-09-20 15:56:44.410351+00', '2020-09-20 15:55:26.501993+00', '123471719825416', NULL, NULL, '', '2020-09-20 15:55:26.544493+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825418', '2020-09-20 15:56:44.404275+00', '2020-09-20 15:55:26.501949+00', '123471719825416', NULL, NULL, '', '2020-09-20 15:55:26.544546+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825416', '2020-09-20 15:56:44.322786+00', '2020-09-20 15:55:26.50156+00', '123471719825412', NULL, NULL, 'building 1 paths', '2020-09-20 15:55:26.544598+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825412', '2020-09-20 15:56:44.300125+00', '2020-09-20 15:55:26.499783+00', '123471719825408', NULL, NULL, 'preparing build of 1 derivations', '2020-09-20 15:55:26.544694+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('123471719825408', '2020-09-20 15:56:44.203364+00', '2020-09-20 15:55:26.499422+00', NULL, NULL, NULL, '_main', '2020-09-20 15:55:26.544751+00') ON CONFLICT DO NOTHING;


--
-- Data for Name: graph; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.graph VALUES ('i:///home/gleber/code/nix/tests/simple.deps.builder.sh', 'read_by', '123471719825414', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', 'read_by', '123471719825422', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', 'read_by', '123471719825423', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', 'read_by', '123471719825423', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', 'read_by', '123471719825422', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', 'read_by', '123471719825422', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'read_by', '123471719825422', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825414', 'reads', 'i:///home/gleber/code/nix/tests/simple.deps.builder.sh', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825422', 'reads', 'i:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825423', 'reads', 'i:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825423', 'reads', 'i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825422', 'reads', 'i:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825422', 'reads', 'i:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825422', 'reads', 'i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825414', 'writes', 'i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825413', 'writes', 'i:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825423', 'writes', 'i:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825422', 'writes', 'i:///run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'written_by', '123471719825414', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', 'written_by', '123471719825413', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', 'written_by', '123471719825423', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top', 'written_by', '123471719825422', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825409', 'child_of', '123471719825408', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825411', 'child_of', '123471719825410', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825410', 'child_of', '123471719825408', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825414', 'child_of', '123471719825413', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825415', 'child_of', '123471719825413', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825413', 'child_of', '123471719825412', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825417', 'child_of', '123471719825416', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825421', 'child_of', '123471719825416', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825424', 'child_of', '123471719825423', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825423', 'child_of', '123471719825416', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825425', 'child_of', '123471719825422', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825422', 'child_of', '123471719825416', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825420', 'child_of', '123471719825416', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825419', 'child_of', '123471719825416', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825418', 'child_of', '123471719825416', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825416', 'child_of', '123471719825412', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825412', 'child_of', '123471719825408', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825408', 'parent_of', '123471719825409', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825410', 'parent_of', '123471719825411', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825408', 'parent_of', '123471719825410', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825413', 'parent_of', '123471719825414', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825413', 'parent_of', '123471719825415', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825412', 'parent_of', '123471719825413', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825416', 'parent_of', '123471719825417', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825416', 'parent_of', '123471719825421', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825423', 'parent_of', '123471719825424', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825416', 'parent_of', '123471719825423', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825422', 'parent_of', '123471719825425', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825416', 'parent_of', '123471719825422', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825416', 'parent_of', '123471719825420', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825416', 'parent_of', '123471719825419', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825416', 'parent_of', '123471719825418', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825412', 'parent_of', '123471719825416', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825408', 'parent_of', '123471719825412', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///home/gleber/code/nix/tests/simple.deps.builder.sh', 'instance_of', 'e:///home/gleber/code/nix/tests/simple.deps.builder.sh', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', 'instance_of', 'e:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', 'instance_of', 'e:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', 'instance_of', 'e:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', 'instance_of', 'e:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'instance_of', 'e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top', 'instance_of', 'e:///run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('e:///home/gleber/code/nix/tests/simple.deps.builder.sh', 'entity_of', 'i:///home/gleber/code/nix/tests/simple.deps.builder.sh', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('e:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', 'entity_of', 'i:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('e:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', 'entity_of', 'i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('e:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', 'entity_of', 'i:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('e:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', 'entity_of', 'i:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'entity_of', 'i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('e:///run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top', 'entity_of', 'i:///run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('123471719825415', 'writes', 'i:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', 'written_by', '123471719825415', '{}') ON CONFLICT DO NOTHING;


--
-- Data for Name: incarnations; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.incarnations VALUES ('i:///home/gleber/code/nix/tests/simple.deps.builder.sh', '2020-09-20 15:56:44.341022+00', 'e:///home/gleber/code/nix/tests/simple.deps.builder.sh', NULL, 'NSO /home/gleber/code/nix/tests/simple.deps.builder.sh', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', '2020-09-20 15:56:44.376863+00', 'e:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', '123471719825413', 'NSO /run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', '2020-09-20 15:56:44.482396+00', 'e:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', NULL, 'NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', '2020-09-20 15:56:44.505517+00', 'e:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', '123471719825423', 'NSO /run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', '2020-09-20 15:56:44.349422+00', 'e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', '123471719825414', 'NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top', '2020-09-20 15:56:44.588975+00', 'e:///run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top', '123471719825422', 'NSO /run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', '2020-09-20 15:56:44.471595+00', 'e:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', '123471719825415', 'NSO /run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', NULL) ON CONFLICT DO NOTHING;


--
-- Data for Name: interactions; Type: TABLE DATA; Schema: public; Owner: tenmo
--



--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: tenmo
--



--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: tenmo
--



--
-- Data for Name: operations; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.operations VALUES ('123471719825414-01EJP3PNKMQ0W1PNHV2PRBA68Z', '2020-09-20 15:56:44.341022+00', '2020-09-20 15:55:26.499933+00', '123471719825414', 'r', 'e:///home/gleber/code/nix/tests/simple.deps.builder.sh', 'i:///home/gleber/code/nix/tests/simple.deps.builder.sh', 'NSO /home/gleber/code/nix/tests/simple.deps.builder.sh', 'NSO /home/gleber/code/nix/tests/simple.deps.builder.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('123471719825414-01EJP3PNKR1382ZSG0PNV8DJJY', '2020-09-20 15:56:44.349422+00', '2020-09-20 15:55:26.500409+00', '123471719825414', 'w', 'e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('123471719825413-01EJP3PNMDHJ8PV1HZ8320ZFDJ', '2020-09-20 15:56:44.376863+00', '2020-09-20 15:55:26.501467+00', '123471719825413', 'w', 'e:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', 'i:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', 'NSO /run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', 'NSO /run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('123471719825422-01EJP3PNN5X3EVYKXQH0WRPVK4', '2020-09-20 15:56:44.449144+00', '2020-09-20 15:55:26.503185+00', '123471719825422', 'r', 'e:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', 'i:///run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', 'NSO /run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv', 'NSO /run/user/1000/nix-test/logging-json/store/j55p0z81q8cak1da2xnikzk4s82g23rk-dependencies-top.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('123471719825423-01EJP3PNP8G269F58MHF6MWY2Q', '2020-09-20 15:56:44.471595+00', '2020-09-20 15:55:26.504416+00', '123471719825423', 'r', 'e:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', 'i:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', 'NSO /run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', 'NSO /run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('123471719825423-01EJP3PNPF5WEJ9ZJVJF46RC8B', '2020-09-20 15:56:44.482396+00', '2020-09-20 15:55:26.505113+00', '123471719825423', 'r', 'e:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', 'i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', 'NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', 'NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('123471719825423-01EJP3PNQDWPXR1ZK28NG7300V', '2020-09-20 15:56:44.505517+00', '2020-09-20 15:55:26.523894+00', '123471719825423', 'w', 'e:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', 'i:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', 'NSO /run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', 'NSO /run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('123471719825422-01EJP3PNQKBQEZ5TRN4QA87WRA', '2020-09-20 15:56:44.536746+00', '2020-09-20 15:55:26.524871+00', '123471719825422', 'r', 'e:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', 'i:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', 'NSO /run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', 'NSO /run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('123471719825422-01EJP3PNQKMEJFXK39W4V23CC7', '2020-09-20 15:56:44.547932+00', '2020-09-20 15:55:26.524921+00', '123471719825422', 'r', 'e:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', 'i:///run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', 'NSO /run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0', 'NSO /run/user/1000/nix-test/logging-json/store/bvh8wgmd0asn08dg5nxhf9g8v2vw2zbw-dependencies-input-0') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('123471719825422-01EJP3PNQM8J18RYVSZGE974VP', '2020-09-20 15:56:44.562258+00', '2020-09-20 15:55:26.524974+00', '123471719825422', 'r', 'e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('123471719825422-01EJP3PNRCKJ3V0WJ2AFE425R5', '2020-09-20 15:56:44.588975+00', '2020-09-20 15:55:26.543839+00', '123471719825422', 'w', 'e:///run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top', 'i:///run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top', 'NSO /run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top', 'NSO /run/user/1000/nix-test/logging-json/store/dc9zd1kawf2kal6z9cyi4iy0ba8c95my-dependencies-top') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('123471719825415-01EJP3PNMA57GBHAKKMQ46MM0C', '2020-09-20 15:56:50.114101+00', '2020-09-20 15:55:26.501027+00', '123471719825415', 'w', 'e:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', 'i:///run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', 'NSO /run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv', 'NSO /run/user/1000/nix-test/logging-json/store/bd73whr00dmzw3gs67kinns6yyv1jlgg-dependencies-input-0.drv') ON CONFLICT DO NOTHING;


--
-- Data for Name: processes; Type: TABLE DATA; Schema: public; Owner: tenmo
--



--
-- Name: annotations annotations_pkey; Type: CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.annotations
    ADD CONSTRAINT annotations_pkey PRIMARY KEY (annotation_id);


--
-- Name: asserts asserts_pkey; Type: CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.asserts
    ADD CONSTRAINT asserts_pkey PRIMARY KEY (source, target);


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

