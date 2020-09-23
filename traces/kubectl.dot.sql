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
-- Name: get_all_paths_from(text, integer); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_all_paths_from(start text, depth_limit integer) RETURNS TABLE(depth integer, verbs text[], path text[])
    LANGUAGE plpgsql
    AS $$
  BEGIN
  RETURN QUERY
  SELECT * FROM get_all_paths_from(text, 100);
  END;
  $$;


ALTER FUNCTION public.get_all_paths_from(start text, depth_limit integer) OWNER TO tenmo;

--
-- Name: get_all_paths_from_by_verbs(text, text[], integer); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_all_paths_from_by_verbs(start text, crawl_verbs text[], depth_limit integer) RETURNS TABLE(depth integer, verbs text[], path text[])
    LANGUAGE plpgsql
    AS $$
  BEGIN
  RETURN QUERY
  SELECT * FROM get_all_paths_from_by_verbs(start, crawl_verbs, 100);
  END;
  $$;


ALTER FUNCTION public.get_all_paths_from_by_verbs(start text, crawl_verbs text[], depth_limit integer) OWNER TO tenmo;

--
-- Name: get_closure_from(text); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_closure_from(start text) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
  begin
  return query
  select * from get_closure_from(start, 100);
  end;
  $$;


ALTER FUNCTION public.get_closure_from(start text) OWNER TO tenmo;

--
-- Name: get_closure_from(text, integer); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_closure_from(start text, depth_limit integer) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
  begin
  return query
  select t.depth, t.path[array_upper(t.path,1)] from get_all_paths_from(start, depth_limit) as t;
  end;
  $$;


ALTER FUNCTION public.get_closure_from(start text, depth_limit integer) OWNER TO tenmo;

--
-- Name: get_closure_from_by_verbs(text, text[]); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_closure_from_by_verbs(start text, crawl_verbs text[]) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
  BEGIN
  RETURN QUERY
  SELECT * FROM get_closure_from_by_verbs(start, crawl_verbs, 100);
  END;
  $$;


ALTER FUNCTION public.get_closure_from_by_verbs(start text, crawl_verbs text[]) OWNER TO tenmo;

--
-- Name: get_closure_from_by_verbs(text, text[], integer); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_closure_from_by_verbs(start text, crawl_verbs text[], depth_limit integer) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
  BEGIN
  RETURN QUERY
  select t.depth, t.path[array_upper(t.path,1)] from get_all_paths_from_by_verbs(start, crawl_verbs, depth_limit) as t;
  END;
  $$;


ALTER FUNCTION public.get_closure_from_by_verbs(start text, crawl_verbs text[], depth_limit integer) OWNER TO tenmo;

--
-- Name: get_closure_from_by_verbs_filtered(text, text[], text[]); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_closure_from_by_verbs_filtered(start text, crawl_verbs text[], filter_verbs text[]) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
  BEGIN
  RETURN QUERY
  SELECT * FROM get_closure_from_by_verbs_filtered(start, crawl_verbs, filter_verbs, 100);
  END;
  $$;


ALTER FUNCTION public.get_closure_from_by_verbs_filtered(start text, crawl_verbs text[], filter_verbs text[]) OWNER TO tenmo;

--
-- Name: get_closure_from_by_verbs_filtered(text, text[], text[], integer); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_closure_from_by_verbs_filtered(start text, crawl_verbs text[], filter_verbs text[], depth_limit integer) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
  BEGIN
  RETURN QUERY
  select t.depth, t.path[array_upper(t.path,1)] from get_all_paths_from_by_verbs(start, crawl_verbs) as t where t.verbs[array_upper(t.verbs,1)-1] = ANY(filter_verbs);
  END;
  $$;


ALTER FUNCTION public.get_closure_from_by_verbs_filtered(start text, crawl_verbs text[], filter_verbs text[], depth_limit integer) OWNER TO tenmo;

--
-- Name: get_closure_from_filtered(text, text[]); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_closure_from_filtered(start text, filter_verbs text[]) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
  begin
  return query
  select * from get_closure_from_filtered(start, filter_verbs, 100);
  end;
  $$;


ALTER FUNCTION public.get_closure_from_filtered(start text, filter_verbs text[]) OWNER TO tenmo;

--
-- Name: get_closure_from_filtered(text, text[], integer); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_closure_from_filtered(start text, filter_verbs text[], depth_limit integer) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
  begin
  return query
  select t.depth, t.path[array_upper(t.path,1)] from get_all_paths_from(start, depth_limit) as t where t.verbs[array_upper(t.verbs,1)-1] = ANY(filter_verbs);
  end;
  $$;


ALTER FUNCTION public.get_closure_from_filtered(start text, filter_verbs text[], depth_limit integer) OWNER TO tenmo;

--
-- Name: get_shortest_path(text, text); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_shortest_path(start text, destination text) RETURNS TABLE(depth integer, path text[], verbs text[])
    LANGUAGE plpgsql
    AS $$
  BEGIN
  RETURN QUERY
  SELECT * FROM get_shortest_path(start, destination, 100);
  END;
  $$;


ALTER FUNCTION public.get_shortest_path(start text, destination text) OWNER TO tenmo;

--
-- Name: get_shortest_path(text, text, integer); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.get_shortest_path(start text, destination text, depth_limit integer) RETURNS TABLE(depth integer, path text[], verbs text[])
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
     WHERE r.source = sp.link AND NOT cycle AND sp.depth < depth_limit
  )
  SELECT sp.depth, (sp.route || destination) AS route, array_append(sp.verbs, '<destination>') as verbs
  FROM search_step AS sp
  WHERE link = destination AND NOT cycle AND NOT (destination = ANY(sp.route))
  ORDER BY depth ASC;

  END;
  $$;


ALTER FUNCTION public.get_shortest_path(start text, destination text, depth_limit integer) OWNER TO tenmo;

--
-- Name: migrate(text); Type: PROCEDURE; Schema: public; Owner: tenmo
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


ALTER PROCEDURE public.migrate(migration text) OWNER TO tenmo;

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
 select * from get_closure_from_by_verbs_filtered(start, ARRAY['written_by','reads']::text[], '{reads}'::text[], 2) as t where t.depth <= 2;
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
 SELECT * FROM provenance_set_indirect(start, 100);
 END;
 $$;


ALTER FUNCTION public.provenance_set_indirect(start text) OWNER TO tenmo;

--
-- Name: provenance_set_indirect(text, integer); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.provenance_set_indirect(start text, depth_limit integer) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
 BEGIN
 RETURN QUERY
 select * from get_closure_from_by_verbs_filtered(start, ARRAY['written_by','reads']::text[], '{reads}'::text[], depth_limit) as t;
 END;
 $$;


ALTER FUNCTION public.provenance_set_indirect(start text, depth_limit integer) OWNER TO tenmo;

--
-- Name: trace(text); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.trace(start text) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
  BEGIN
  RETURN QUERY
  SELECT * FROM trace(start, 100);
  END;
  $$;


ALTER FUNCTION public.trace(start text) OWNER TO tenmo;

--
-- Name: trace(text, integer); Type: FUNCTION; Schema: public; Owner: tenmo
--

CREATE FUNCTION public.trace(start text, depth_limit integer) RETURNS TABLE(depth integer, obj text)
    LANGUAGE plpgsql
    AS $$
  BEGIN
  RETURN QUERY
  select * from get_closure_from_by_verbs(start, ARRAY['child_of']::text[], depth_limit) as t;
  END;
  $$;


ALTER FUNCTION public.trace(start text, depth_limit integer) OWNER TO tenmo;

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
    parent_id text,
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

INSERT INTO public.entities VALUES ('en://file:///nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json', '2020-09-20 18:22:25.998265+00', 'file /nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('en://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx', '2020-09-20 18:22:26.006166+00', 'in-memory resource /apis/apps/v1/namespaces/default/deployments/nginx') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('en://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', '2020-09-20 18:22:26.01446+00', 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('en://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', '2020-09-20 18:22:26.022998+00', 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('en://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx', '2020-09-20 18:22:26.031025+00', 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/services/nginx') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('en:///apis/apps/v1/namespaces/default/deployments/nginx', '2020-09-20 18:22:26.069411+00', 'resource deployments/nginx') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', '2020-09-20 18:22:26.140342+00', 'resource configmaps/nginx-config') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', '2020-09-20 18:22:26.199053+00', 'resource configmaps/nginx-static') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('en://https://192.168.1.1/api/v1/namespaces/default/services/nginx', '2020-09-20 18:22:26.241941+00', 'resource services/nginx') ON CONFLICT DO NOTHING;


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.events VALUES ('01EJP9QYYQQDPPCVW0V7RGZ9JN', 'p', 1, '2020-09-20 17:42:17.817585+00', '2020-09-20 18:22:25.689001+00', '2020-09-20 17:42:17.815843+00', 'EventExecutionBegins', '{"timestamp": "2020-09-20T17:42:17.815843282Z", "event_ulid": "01EJP9QYYQQDPPCVW0V7RGZ9JN", "description": "kubectl apply", "execution_id": "ex://kubectl-apply-01EJP9QYYQQDPPCVW0V6TE9CBW"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9QXYAPH5HCJENYAZJHHC7', 'p', 1, '2020-09-20 17:42:16.780841+00', '2020-09-20 18:22:25.633245+00', '2020-09-20 17:42:16.778523+00', 'EventExecutionBegins', '{"timestamp": "2020-09-20T17:42:16.778523455Z", "event_ulid": "01EJP9QXYAPH5HCJENYAZJHHC7", "description": "kubectl apply", "execution_id": "ex://kubectl-apply-01EJP9QXYAPH5HCJENYABGSMF3"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9QYSE8DHSMC3MJR2HYBRN', 'p', 1, '2020-09-20 17:42:17.647968+00', '2020-09-20 18:22:25.647767+00', '2020-09-20 17:42:17.646453+00', 'EventExecutionBegins', '{"parent_id": "ex://kubectl-apply-01EJP9QXYAPH5HCJENYABGSMF3", "timestamp": "2020-09-20T17:42:17.646453318Z", "event_ulid": "01EJP9QYSE8DHSMC3MJR2HYBRN", "description": "kubectl apply resource building", "execution_id": "ex://kubectl-apply-builder-01EJP9QYSE8DHSMC3MJQCYRBMR"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R6QDJJ01VPENHSEEAGFV', 'p', 1, '2020-09-20 17:42:25.78063+00', '2020-09-20 18:22:25.736981+00', '2020-09-20 17:42:25.773477+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-Run-01EJP9R4ETBCWRTMARMD3SRW6M", "timestamp": "2020-09-20T17:42:25.773476723Z", "event_ulid": "01EJP9R6QDJJ01VPENHSEEAGFV", "description": "kube DC worker", "execution_id": "ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9QYSRXHZM53RCXTYJ4ZG1', 'p', 1, '2020-09-20 17:42:17.657998+00', '2020-09-20 18:22:25.6628+00', '2020-09-20 17:42:17.65675+00', 'EventOperation', '{"type": "r", "entity_id": "en://file:///dev/null", "timestamp": "2020-09-20T17:42:17.656750436Z", "event_ulid": "01EJP9QYSRXHZM53RCXTYJ4ZG1", "execution_id": "ex://kubectl-apply-builder-01EJP9QYSE8DHSMC3MJQCYRBMR", "operation_id": "01EJP9QYSRXHZM53RCXTYJ4ZG1", "incarnation_id": "i://file:///dev/null?ulid=01EJP9QYSRXHZM53RCXSFS0PMP", "entity_description": "file /dev/null", "incarnation_description": "file /dev/null"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9QYT1VPRG9P4N55Y8W6FY', 'p', 1, '2020-09-20 17:42:17.666659+00', '2020-09-20 18:22:25.677504+00', '2020-09-20 17:42:17.66599+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:17.665990438Z", "event_ulid": "01EJP9QYT1VPRG9P4N55Y8W6FY", "execution_id": "ex://kubectl-apply-builder-01EJP9QYSE8DHSMC3MJQCYRBMR"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9QZ675722EJV4ZC2447F4', 'p', 1, '2020-09-20 17:42:18.056841+00', '2020-09-20 18:22:25.709795+00', '2020-09-20 17:42:18.055884+00', 'EventOperation', '{"type": "r", "entity_id": "en://file:///dev/null", "timestamp": "2020-09-20T17:42:18.055883846Z", "event_ulid": "01EJP9QZ675722EJV4ZC2447F4", "execution_id": "ex://kubectl-apply-builder-01EJP9QZ63G9XB872N48REMV3X", "operation_id": "01EJP9QZ675722EJV4ZC2447F4", "incarnation_id": "i://file:///dev/null?ulid=01EJP9QZ675722EJV4ZBWACX4M", "entity_description": "file /dev/null", "incarnation_description": "file /dev/null"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9QZ63G9XB872N4CMS9MHZ', 'p', 1, '2020-09-20 17:42:18.052735+00', '2020-09-20 18:22:25.696086+00', '2020-09-20 17:42:18.051539+00', 'EventExecutionBegins', '{"parent_id": "ex://kubectl-apply-01EJP9QYYQQDPPCVW0V6TE9CBW", "timestamp": "2020-09-20T17:42:18.05153888Z", "event_ulid": "01EJP9QZ63G9XB872N4CMS9MHZ", "description": "kubectl apply resource building", "execution_id": "ex://kubectl-apply-builder-01EJP9QZ63G9XB872N48REMV3X"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9QZ6BA2HPRDEPN653P7TT', 'p', 1, '2020-09-20 17:42:18.060413+00', '2020-09-20 18:22:25.718154+00', '2020-09-20 17:42:18.05975+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:18.0597497Z", "event_ulid": "01EJP9QZ6BA2HPRDEPN653P7TT", "execution_id": "ex://kubectl-apply-builder-01EJP9QZ63G9XB872N48REMV3X"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R6QD140N96RHNE85A2J1', 'p', 2, '2020-09-20 17:42:25.807802+00', '2020-09-20 18:22:31.638736+00', '2020-09-20 17:42:25.773595+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-Run-01EJP9R4ETBCWRTMARMD3SRW6M", "timestamp": "2020-09-20T17:42:25.773594895Z", "event_ulid": "01EJP9R6QD140N96RHNE85A2J1", "description": "kube DC worker", "execution_id": "ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R4ETBCWRTMARMDD3R59A', 'p', 1, '2020-09-20 17:42:23.454642+00', '2020-09-20 18:22:25.730273+00', '2020-09-20 17:42:23.450889+00', 'EventExecutionBegins', '{"timestamp": "2020-09-20T17:42:23.450889356Z", "event_ulid": "01EJP9R4ETBCWRTMARMDD3R59A", "description": "kube DC Run", "execution_id": "ex://kube-DeploymentController-Run-01EJP9R4ETBCWRTMARMD3SRW6M"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R6QFH6H43Q6CWKH1TSTM', 'p', 1, '2020-09-20 17:42:25.808835+00', '2020-09-20 18:22:25.743591+00', '2020-09-20 17:42:25.775286+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-Run-01EJP9R4ETBCWRTMARMD3SRW6M", "timestamp": "2020-09-20T17:42:25.775286171Z", "event_ulid": "01EJP9R6QFH6H43Q6CWKH1TSTM", "description": "kube DC worker", "execution_id": "ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R6QRZK3FM97BHHNZRDGN', 'p', 1, '2020-09-20 17:42:25.83332+00', '2020-09-20 18:22:25.750345+00', '2020-09-20 17:42:25.785794+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-Run-01EJP9R4ETBCWRTMARMD3SRW6M", "timestamp": "2020-09-20T17:42:25.785794211Z", "event_ulid": "01EJP9R6QRZK3FM97BHHNZRDGN", "description": "kube DC worker", "execution_id": "ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R98AR33XC4MBDMHGD9NC', 'p', 1, '2020-09-20 17:42:28.364458+00', '2020-09-20 18:22:25.757834+00', '2020-09-20 17:42:28.362631+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X", "timestamp": "2020-09-20T17:42:28.362630652Z", "event_ulid": "01EJP9R98AR33XC4MBDMHGD9NC", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R98AR33XC4MBDKBB8F4M"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R99EZT88JXAQPNDS5QTW', 'p', 1, '2020-09-20 17:42:28.400835+00', '2020-09-20 18:22:25.76442+00', '2020-09-20 17:42:28.398733+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/kube-system/deployments/coredns", "timestamp": "2020-09-20T17:42:28.398732726Z", "event_ulid": "01EJP9R99EZT88JXAQPNDS5QTW", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R98AR33XC4MBDKBB8F4M", "operation_id": "01EJP9R99EZT88JXAQPNDS5QTW", "incarnation_id": "i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1", "entity_description": "deployment coredns", "incarnation_description": "deployment coredns"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R6QD140N96RHNAM8Q0GV', 'p', 2, '2020-09-20 17:42:25.814353+00', '2020-09-20 18:22:31.644293+00', '2020-09-20 17:42:25.773533+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-Run-01EJP9R4ETBCWRTMARMD3SRW6M", "timestamp": "2020-09-20T17:42:25.773533155Z", "event_ulid": "01EJP9R6QD140N96RHNAM8Q0GV", "description": "kube DC worker", "execution_id": "ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R9H01Y2JH65H01Y4R4D0', 'p', 3, '2020-09-20 17:42:28.642888+00', '2020-09-20 18:22:41.668617+00', '2020-09-20 17:42:28.641045+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/kube-system/deployments/coredns", "timestamp": "2020-09-20T17:42:28.641045366Z", "event_ulid": "01EJP9R9H01Y2JH65H01Y4R4D0", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9GH6AWYYQ725XW5A32M", "operation_id": "01EJP9R9H01Y2JH65H01Y4R4D0", "incarnation_id": "i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1", "entity_description": "deployment coredns", "incarnation_description": "deployment coredns"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R9DQMVTFBF07D2B79WP2', 'p', 1, '2020-09-20 17:42:28.552552+00', '2020-09-20 18:22:25.779984+00', '2020-09-20 17:42:28.535787+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR", "timestamp": "2020-09-20T17:42:28.535787017Z", "event_ulid": "01EJP9R9DQMVTFBF07D2B79WP2", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9DQMVTFBF07CYJQM5CF"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R9FTWCPAKP14JY26KZP0', 'p', 1, '2020-09-20 17:42:28.604759+00', '2020-09-20 18:22:25.805647+00', '2020-09-20 17:42:28.602968+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:28.602967622Z", "event_ulid": "01EJP9R9FTWCPAKP14JY26KZP0", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9DQMVTFBF07CYJQM5CF"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RAHCH415DJMRB2AR71P1', 'p', 1, '2020-09-20 17:42:29.684964+00', '2020-09-20 18:22:25.839771+00', '2020-09-20 17:42:29.676564+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4", "timestamp": "2020-09-20T17:42:29.676563847Z", "event_ulid": "01EJP9RAHCH415DJMRB2AR71P1", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAHCH415DJMRB208ADWG"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RAJ9MEDS3E5VBZFPVFSM', 'p', 1, '2020-09-20 17:42:29.711719+00', '2020-09-20 18:22:25.851653+00', '2020-09-20 17:42:29.705251+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:29.705251013Z", "event_ulid": "01EJP9RAJ9MEDS3E5VBZFPVFSM", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAHCH415DJMRB208ADWG"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RAMKA8S8S5BMJAG4HN5J', 'p', 1, '2020-09-20 17:42:29.782229+00', '2020-09-20 18:22:25.870737+00', '2020-09-20 17:42:29.779895+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR", "timestamp": "2020-09-20T17:42:29.779895136Z", "event_ulid": "01EJP9RAMKA8S8S5BMJAG4HN5J", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAMKA8S8S5BMJA0E5MTE"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RAMTSEQW8VJAHE6W3RT6', 'p', 1, '2020-09-20 17:42:29.788409+00', '2020-09-20 18:22:25.884018+00', '2020-09-20 17:42:29.786722+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/kube-system/deployments/coredns", "timestamp": "2020-09-20T17:42:29.786722261Z", "event_ulid": "01EJP9RAMTSEQW8VJAHE6W3RT6", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAMKA8S8S5BMJA0E5MTE", "operation_id": "01EJP9RAMTSEQW8VJAHE6W3RT6", "incarnation_id": "i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1", "entity_description": "deployment coredns", "incarnation_description": "deployment coredns"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R9GH6AWYYQ725VTVQTCD', 'p', 3, '2020-09-20 17:42:28.626984+00', '2020-09-20 18:22:41.659325+00', '2020-09-20 17:42:28.625628+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:28.625628044Z", "event_ulid": "01EJP9R9GH6AWYYQ725VTVQTCD", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9FV2M20K553R4BE5CQ5"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RE0Q9J5SYK5ZBTD0BT1N', 'p', 1, '2020-09-20 17:42:33.240663+00', '2020-09-20 18:22:25.912713+00', '2020-09-20 17:42:33.239657+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4", "timestamp": "2020-09-20T17:42:33.239656921Z", "event_ulid": "01EJP9RE0Q9J5SYK5ZBTD0BT1N", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE0Q9J5SYK5ZBQSQ01V2"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RE1FQBX3FEMGK3JD1RD3', 'p', 1, '2020-09-20 17:42:33.268079+00', '2020-09-20 18:22:25.927127+00', '2020-09-20 17:42:33.263858+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:33.263858042Z", "event_ulid": "01EJP9RE1FQBX3FEMGK3JD1RD3", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE0Q9J5SYK5ZBQSQ01V2"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R9DPJWRXZJJPHJKAY5WP', 'p', 1, '2020-09-20 17:42:28.536569+00', '2020-09-20 18:22:25.772467+00', '2020-09-20 17:42:28.534902+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:28.534902267Z", "event_ulid": "01EJP9R9DPJWRXZJJPHJKAY5WP", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R98AR33XC4MBDKBB8F4M"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RE72V4KXXSKCZ1073AT6', 'p', 1, '2020-09-20 17:42:33.446012+00', '2020-09-20 18:22:25.948231+00', '2020-09-20 17:42:33.442436+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR", "timestamp": "2020-09-20T17:42:33.442435766Z", "event_ulid": "01EJP9RE72V4KXXSKCZ1073AT6", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE72V4KXXSKCYZ6PDSEZ"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RE9710ST0KZAEVMNJ17P', 'p', 1, '2020-09-20 17:42:33.514821+00', '2020-09-20 18:22:25.957722+00', '2020-09-20 17:42:33.512052+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:33.512051597Z", "event_ulid": "01EJP9RE9710ST0KZAEVMNJ17P", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE72V4KXXSKCYZ6PDSEZ"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDP6M59FTSSRFNNETJBK', 'p', 1, '2020-09-20 17:42:32.907653+00', '2020-09-20 18:22:26.046103+00', '2020-09-20 17:42:32.902944+00', 'EventExecutionBegins', '{"parent_id": "ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9", "timestamp": "2020-09-20T17:42:32.902943736Z", "event_ulid": "01EJP9RDP6M59FTSSRFNNETJBK", "description": "kubectl apply one", "execution_id": "ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RCAVZB25SQGSVN1DHWG5', 'p', 1, '2020-09-20 17:42:31.517654+00', '2020-09-20 18:22:25.979909+00', '2020-09-20 17:42:31.515278+00', 'EventExecutionBegins', '{"timestamp": "2020-09-20T17:42:31.515277706Z", "event_ulid": "01EJP9RCAVZB25SQGSVN1DHWG5", "description": "kubectl apply", "execution_id": "ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RCQ1Y5Q05S9BEQ35FHTA', 'p', 1, '2020-09-20 17:42:31.907463+00', '2020-09-20 18:22:25.989843+00', '2020-09-20 17:42:31.905646+00', 'EventExecutionBegins', '{"parent_id": "ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9", "timestamp": "2020-09-20T17:42:31.905646314Z", "event_ulid": "01EJP9RCQ1Y5Q05S9BEQ35FHTA", "description": "kubectl apply resource building", "execution_id": "ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDM2KBXHW0N01SSHG1HF', 'p', 1, '2020-09-20 17:42:32.847466+00', '2020-09-20 18:22:26.006166+00', '2020-09-20 17:42:32.834325+00', 'EventOperation', '{"type": "w", "entity_id": "en://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:32.834325238Z", "event_ulid": "01EJP9RDM2KBXHW0N01SSHG1HF", "execution_id": "ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2", "operation_id": "01EJP9RDM2KBXHW0N01SSHG1HF", "incarnation_id": "i://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDM2KBXHW0N01QMZSCTZ", "entity_description": "in-memory resource /apis/apps/v1/namespaces/default/deployments/nginx", "incarnation_description": "in-memory resource /apis/apps/v1/namespaces/default/deployments/nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDMZJ36D52F9A6HD4ZT9', 'p', 1, '2020-09-20 17:42:32.865538+00', '2020-09-20 18:22:26.01446+00', '2020-09-20 17:42:32.863331+00', 'EventOperation', '{"type": "w", "entity_id": "en://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config", "timestamp": "2020-09-20T17:42:32.863330601Z", "event_ulid": "01EJP9RDMZJ36D52F9A6HD4ZT9", "execution_id": "ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2", "operation_id": "01EJP9RDMZJ36D52F9A6HD4ZT9", "incarnation_id": "i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDMY6BEN4XZBX83ZX0AW", "entity_description": "in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config", "incarnation_description": "in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDN6VFPTHWG7P8M8SYPZ', 'p', 1, '2020-09-20 17:42:32.878273+00', '2020-09-20 18:22:26.022998+00', '2020-09-20 17:42:32.870725+00', 'EventOperation', '{"type": "w", "entity_id": "en://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static", "timestamp": "2020-09-20T17:42:32.870725395Z", "event_ulid": "01EJP9RDN6VFPTHWG7P8M8SYPZ", "execution_id": "ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2", "operation_id": "01EJP9RDN6VFPTHWG7P8M8SYPZ", "incarnation_id": "i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9RDN6VFPTHWG7P6NBGWFC", "entity_description": "in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static", "incarnation_description": "in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDNKD3K51RJACXGKNRTC', 'p', 1, '2020-09-20 17:42:32.887862+00', '2020-09-20 18:22:26.031025+00', '2020-09-20 17:42:32.883722+00', 'EventOperation', '{"type": "w", "entity_id": "en://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx", "timestamp": "2020-09-20T17:42:32.88372174Z", "event_ulid": "01EJP9RDNKD3K51RJACXGKNRTC", "execution_id": "ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2", "operation_id": "01EJP9RDNKD3K51RJACXGKNRTC", "incarnation_id": "i://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9RDNKD3K51RJACSTS28PA", "entity_description": "in-memory resource https://192.168.1.1/api/v1/namespaces/default/services/nginx", "incarnation_description": "in-memory resource https://192.168.1.1/api/v1/namespaces/default/services/nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDNX46M6G8QDTGHQ2FBW', 'p', 1, '2020-09-20 17:42:32.896635+00', '2020-09-20 18:22:26.039356+00', '2020-09-20 17:42:32.89382+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:32.89381995Z", "event_ulid": "01EJP9RDNX46M6G8QDTGHQ2FBW", "execution_id": "ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9REJJBGX9ZERMGAEZ90NN', 'p', 1, '2020-09-20 17:42:33.815736+00', '2020-09-20 18:22:26.052868+00', '2020-09-20 17:42:33.811354+00', 'EventExecutionBegins', '{"parent_id": "ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9", "timestamp": "2020-09-20T17:42:33.811354441Z", "event_ulid": "01EJP9REJJBGX9ZERMGAEZ90NN", "description": "kubectl apply one", "execution_id": "ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RE9MTW1R87FT8E1CRCAR', 'p', 3, '2020-09-20 17:42:33.528924+00', '2020-09-20 18:22:41.678143+00', '2020-09-20 17:42:33.525004+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:33.525004361Z", "event_ulid": "01EJP9RE9MTW1R87FT8E1CRCAR", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE98R4XKYN7NV8HP95D9", "operation_id": "01EJP9RE9MTW1R87FT8E1CRCAR", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R9EFM8PSY3H28CQAE5XP', 'p', 1, '2020-09-20 17:42:28.561797+00', '2020-09-20 18:22:25.786702+00', '2020-09-20 17:42:28.559985+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/kube-system/deployments/coredns", "timestamp": "2020-09-20T17:42:28.559984505Z", "event_ulid": "01EJP9R9EFM8PSY3H28CQAE5XP", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9DQMVTFBF07CYJQM5CF", "operation_id": "01EJP9R9EFM8PSY3H28CQAE5XP", "incarnation_id": "i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1", "entity_description": "deployment coredns", "incarnation_description": "deployment coredns"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RCQA6DWGRG1Y8AGBH0YG', 'p', 1, '2020-09-20 17:42:31.916351+00', '2020-09-20 18:22:25.998265+00', '2020-09-20 17:42:31.914776+00', 'EventOperation', '{"type": "r", "entity_id": "en://file:///nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json", "timestamp": "2020-09-20T17:42:31.914775687Z", "event_ulid": "01EJP9RCQA6DWGRG1Y8AGBH0YG", "execution_id": "ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2", "operation_id": "01EJP9RCQA6DWGRG1Y8AGBH0YG", "incarnation_id": "i://file:///nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json?ulid=01EJP9RCQ95JT85A4AJNP67V6C", "entity_description": "file /nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json", "incarnation_description": "file /nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDPHNN79VTM51BQ0VJKC', 'p', 1, '2020-09-20 17:42:32.916886+00', '2020-09-20 18:22:26.060944+00', '2020-09-20 17:42:32.914027+00', 'EventOperation', '{"type": "r", "entity_id": "en://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:32.914026709Z", "event_ulid": "01EJP9RDPHNN79VTM51BQ0VJKC", "execution_id": "ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD", "operation_id": "01EJP9RDPHNN79VTM51BQ0VJKC", "incarnation_id": "i://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDM2KBXHW0N01QMZSCTZ", "entity_description": "in-memory resource /apis/apps/v1/namespaces/default/deployments/nginx", "incarnation_description": "in-memory resource /apis/apps/v1/namespaces/default/deployments/nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9REK0XP9YGKR00S67N37T', 'p', 1, '2020-09-20 17:42:33.82806+00', '2020-09-20 18:22:26.230771+00', '2020-09-20 17:42:33.824707+00', 'EventOperation', '{"type": "r", "entity_id": "en://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx", "timestamp": "2020-09-20T17:42:33.824706976Z", "event_ulid": "01EJP9REK0XP9YGKR00S67N37T", "execution_id": "ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY", "operation_id": "01EJP9REK0XP9YGKR00S67N37T", "incarnation_id": "i://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9RDNKD3K51RJACSTS28PA", "entity_description": "in-memory resource https://192.168.1.1/api/v1/namespaces/default/services/nginx", "incarnation_description": "in-memory resource https://192.168.1.1/api/v1/namespaces/default/services/nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVECGJA4S7E63DSCYW9B', 'p', 1, '2020-09-20 17:42:46.991639+00', '2020-09-20 18:22:26.409977+00', '2020-09-20 17:42:46.989096+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:46.989096024Z", "event_ulid": "01EJP9RVECGJA4S7E63DSCYW9B", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVE0C5D0F63557P7354Y", "operation_id": "01EJP9RVECGJA4S7E63DSCYW9B", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVHVXTYDKF53JPFGEF0D', 'p', 2, '2020-09-20 17:42:47.109543+00', '2020-09-20 18:22:31.663669+00', '2020-09-20 17:42:47.10066+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:47.100659924Z", "event_ulid": "01EJP9RVHVXTYDKF53JPFGEF0D", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVHA6DK0V7GN9WH4HFGD", "operation_id": "01EJP9RVHVXTYDKF53JPFGEF0D", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RY0ZCTYS1XY9XGCSTPW8', 'p', 3, '2020-09-20 17:42:49.633359+00', '2020-09-20 18:22:41.694764+00', '2020-09-20 17:42:49.631281+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:49.631281274Z", "event_ulid": "01EJP9RY0ZCTYS1XY9XGCSTPW8", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY0NMZ9J8C72FES14C7Y", "operation_id": "01EJP9RY0ZCTYS1XY9XGCSTPW8", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RV8BZ9QKRT9FNNCX6YZN', 'p', 3, '2020-09-20 17:42:46.804159+00', '2020-09-20 18:22:41.702999+00', '2020-09-20 17:42:46.796753+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:46.796752584Z", "event_ulid": "01EJP9RV8BZ9QKRT9FNNCX6YZN", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RV7AQX4HN3MYH19P8P5V", "operation_id": "01EJP9RV8BZ9QKRT9FNNCX6YZN", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RY2XXX1Z172AM3R0NY1N', 'p', 3, '2020-09-20 17:42:49.696332+00', '2020-09-20 18:22:41.686735+00', '2020-09-20 17:42:49.693562+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:49.693561536Z", "event_ulid": "01EJP9RY2XXX1Z172AM3R0NY1N", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY2FDEW8G382AJECQ03Z", "operation_id": "01EJP9RY2XXX1Z172AM3R0NY1N", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDQH4F7F7A2XY2X20RAM', 'p', 1, '2020-09-20 17:42:32.948833+00', '2020-09-20 18:22:26.069411+00', '2020-09-20 17:42:32.945592+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:32.945591614Z", "event_ulid": "01EJP9RDQH4F7F7A2XY2X20RAM", "execution_id": "ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD", "operation_id": "01EJP9RDQH4F7F7A2XY2X20RAM", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDPT8G67DTE7VN8XX7CX", "entity_description": "resource deployments/nginx", "incarnation_description": "resource deployments/nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDS7VP68NAQGK64GAF3V', 'p', 1, '2020-09-20 17:42:33.004599+00', '2020-09-20 18:22:26.077248+00', '2020-09-20 17:42:32.999923+00', 'EventOperation', '{"type": "w", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:32.999922821Z", "event_ulid": "01EJP9RDS7VP68NAQGK64GAF3V", "execution_id": "ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD", "operation_id": "01EJP9RDS7VP68NAQGK64GAF3V", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDS7VP68NAQGK4CFW6VH", "entity_description": "resource deployments/nginx", "incarnation_description": "resource deployments/nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDSKVR0QESKGCGK0R3G7', 'p', 1, '2020-09-20 17:42:33.01538+00', '2020-09-20 18:22:26.089583+00', '2020-09-20 17:42:33.011617+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:33.011617045Z", "event_ulid": "01EJP9RDSKVR0QESKGCGK0R3G7", "execution_id": "ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDSYQ8BXNDKD35HEXX6K', 'p', 1, '2020-09-20 17:42:33.025807+00', '2020-09-20 18:22:26.108385+00', '2020-09-20 17:42:33.022829+00', 'EventExecutionBegins', '{"parent_id": "ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9", "timestamp": "2020-09-20T17:42:33.022828526Z", "event_ulid": "01EJP9RDSYQ8BXNDKD35HEXX6K", "description": "kubectl apply one", "execution_id": "ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDT80Y58Z4XDNTR4QJT4', 'p', 1, '2020-09-20 17:42:33.035514+00', '2020-09-20 18:22:26.127255+00', '2020-09-20 17:42:33.032346+00', 'EventOperation', '{"type": "r", "entity_id": "en://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config", "timestamp": "2020-09-20T17:42:33.032345936Z", "event_ulid": "01EJP9RDT80Y58Z4XDNTR4QJT4", "execution_id": "ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5", "operation_id": "01EJP9RDT80Y58Z4XDNTR4QJT4", "incarnation_id": "i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDMY6BEN4XZBX83ZX0AW", "entity_description": "in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config", "incarnation_description": "in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RE1CA0R0G4WJD124NCTF', 'p', 1, '2020-09-20 17:42:33.270053+00', '2020-09-20 18:22:26.140342+00', '2020-09-20 17:42:33.261046+00', 'EventOperation', '{"type": "r", "entity_id": "en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config", "timestamp": "2020-09-20T17:42:33.261046232Z", "event_ulid": "01EJP9RE1CA0R0G4WJD124NCTF", "execution_id": "ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5", "operation_id": "01EJP9RE1CA0R0G4WJD124NCTF", "incarnation_id": "i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDTFQFNCK6GYB5DNJY0Z", "entity_description": "resource configmaps/nginx-config", "incarnation_description": "resource configmaps/nginx-config"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RE2ZXX51FPC9WTSBRG3X', 'p', 1, '2020-09-20 17:42:33.480235+00', '2020-09-20 18:22:26.1511+00', '2020-09-20 17:42:33.311615+00', 'EventOperation', '{"type": "w", "entity_id": "en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config", "timestamp": "2020-09-20T17:42:33.31161467Z", "event_ulid": "01EJP9RE2ZXX51FPC9WTSBRG3X", "execution_id": "ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5", "operation_id": "01EJP9RE2ZXX51FPC9WTSBRG3X", "incarnation_id": "i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RE2ZXX51FPC9WT303FQB", "entity_description": "resource configmaps/nginx-config", "incarnation_description": "resource configmaps/nginx-config"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RE8GMGE8X4BQF9DFZSVR', 'p', 1, '2020-09-20 17:42:33.489982+00', '2020-09-20 18:22:26.164172+00', '2020-09-20 17:42:33.488568+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:33.488568445Z", "event_ulid": "01EJP9RE8GMGE8X4BQF9DFZSVR", "execution_id": "ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9REENA5M3JB3ECVH2YZZJ', 'p', 1, '2020-09-20 17:42:33.691935+00', '2020-09-20 18:22:26.175306+00', '2020-09-20 17:42:33.686577+00', 'EventExecutionBegins', '{"parent_id": "ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9", "timestamp": "2020-09-20T17:42:33.68657741Z", "event_ulid": "01EJP9REENA5M3JB3ECVH2YZZJ", "description": "kubectl apply one", "execution_id": "ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9REF04W5E4XT5TJS5BA5E', 'p', 1, '2020-09-20 17:42:33.700647+00', '2020-09-20 18:22:26.186892+00', '2020-09-20 17:42:33.696995+00', 'EventOperation', '{"type": "r", "entity_id": "en://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static", "timestamp": "2020-09-20T17:42:33.696995214Z", "event_ulid": "01EJP9REF04W5E4XT5TJS5BA5E", "execution_id": "ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D", "operation_id": "01EJP9REF04W5E4XT5TJS5BA5E", "incarnation_id": "i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9RDN6VFPTHWG7P6NBGWFC", "entity_description": "in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static", "incarnation_description": "in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9REG548NMNRFSX21STP97', 'p', 1, '2020-09-20 17:42:33.736002+00', '2020-09-20 18:22:26.199053+00', '2020-09-20 17:42:33.733897+00', 'EventOperation', '{"type": "r", "entity_id": "en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static", "timestamp": "2020-09-20T17:42:33.73389739Z", "event_ulid": "01EJP9REG548NMNRFSX21STP97", "execution_id": "ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D", "operation_id": "01EJP9REG548NMNRFSX21STP97", "incarnation_id": "i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REFBRQDS6A0JNZF73E80", "entity_description": "resource configmaps/nginx-static", "incarnation_description": "resource configmaps/nginx-static"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9REHGBRTSZJXT07Z40CEA', 'p', 1, '2020-09-20 17:42:33.788855+00', '2020-09-20 18:22:26.210367+00', '2020-09-20 17:42:33.777262+00', 'EventOperation', '{"type": "w", "entity_id": "en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static", "timestamp": "2020-09-20T17:42:33.77726184Z", "event_ulid": "01EJP9REHGBRTSZJXT07Z40CEA", "execution_id": "ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D", "operation_id": "01EJP9REHGBRTSZJXT07Z40CEA", "incarnation_id": "i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REHF3W1074H5NWN2MF90", "entity_description": "resource configmaps/nginx-static", "incarnation_description": "resource configmaps/nginx-static"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9REJ6R8J65TVSEAAK740V', 'p', 1, '2020-09-20 17:42:33.800815+00', '2020-09-20 18:22:26.221533+00', '2020-09-20 17:42:33.798699+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:33.798699202Z", "event_ulid": "01EJP9REJ6R8J65TVSEAAK740V", "execution_id": "ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9REM99TFN48STSYR8GHBV', 'p', 1, '2020-09-20 17:42:33.870585+00', '2020-09-20 18:22:26.241941+00', '2020-09-20 17:42:33.865914+00', 'EventOperation', '{"type": "r", "entity_id": "en://https://192.168.1.1/api/v1/namespaces/default/services/nginx", "timestamp": "2020-09-20T17:42:33.865914169Z", "event_ulid": "01EJP9REM99TFN48STSYR8GHBV", "execution_id": "ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY", "operation_id": "01EJP9REM99TFN48STSYR8GHBV", "incarnation_id": "i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REKAW44WKNW8CC1A80V0", "entity_description": "resource services/nginx", "incarnation_description": "resource services/nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9REP7AB85EW3557CR70BW', 'p', 1, '2020-09-20 17:42:33.93104+00', '2020-09-20 18:22:26.252048+00', '2020-09-20 17:42:33.927654+00', 'EventOperation', '{"type": "w", "entity_id": "en://https://192.168.1.1/api/v1/namespaces/default/services/nginx", "timestamp": "2020-09-20T17:42:33.927653859Z", "event_ulid": "01EJP9REP7AB85EW3557CR70BW", "execution_id": "ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY", "operation_id": "01EJP9REP7AB85EW3557CR70BW", "incarnation_id": "i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REP7AB85EW3554GWPR7H", "entity_description": "resource services/nginx", "incarnation_description": "resource services/nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9REPGZ7W80T10Y94AEQVQ', 'p', 1, '2020-09-20 17:42:33.939711+00', '2020-09-20 18:22:26.260059+00', '2020-09-20 17:42:33.936875+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:33.936874584Z", "event_ulid": "01EJP9REPGZ7W80T10Y94AEQVQ", "execution_id": "ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9REPRVH06FY3V4N287FJD', 'p', 1, '2020-09-20 17:42:33.94786+00', '2020-09-20 18:22:26.266873+00', '2020-09-20 17:42:33.944731+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:33.944730611Z", "event_ulid": "01EJP9REPRVH06FY3V4N287FJD", "execution_id": "ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RR0SB8V90BRMKZC59TES', 'p', 2, '2020-09-20 17:42:43.486335+00', '2020-09-20 18:22:31.67945+00', '2020-09-20 17:42:43.481753+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS", "timestamp": "2020-09-20T17:42:43.481753332Z", "event_ulid": "01EJP9RR0SB8V90BRMKZC59TES", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RR0SB8V90BRMKW65F7D9"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RR4SWCNC1EZ8WCX6W9Z5', 'p', 2, '2020-09-20 17:42:43.61226+00', '2020-09-20 18:22:31.684919+00', '2020-09-20 17:42:43.609831+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:43.609831062Z", "event_ulid": "01EJP9RR4SWCNC1EZ8WCX6W9Z5", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RR0SB8V90BRMKW65F7D9"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RTGQZHPBRTB6883K0XJD', 'p', 1, '2020-09-20 17:42:46.042436+00', '2020-09-20 18:22:26.287743+00', '2020-09-20 17:42:46.039212+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X", "timestamp": "2020-09-20T17:42:46.039211612Z", "event_ulid": "01EJP9RTGQZHPBRTB6883K0XJD", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RTGPD0M1T5NXYNN52R7V"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RTNG7SRE3SC7TJ87XJFF', 'p', 1, '2020-09-20 17:42:46.195732+00', '2020-09-20 18:22:26.293544+00', '2020-09-20 17:42:46.193011+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:46.193011047Z", "event_ulid": "01EJP9RTNG7SRE3SC7TJ87XJFF", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RTGPD0M1T5NXYNN52R7V"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVAFJF6KVNB4KAGHE723', 'p', 1, '2020-09-20 17:42:46.867765+00', '2020-09-20 18:22:26.316794+00', '2020-09-20 17:42:46.863718+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4", "timestamp": "2020-09-20T17:42:46.863718358Z", "event_ulid": "01EJP9RVAFJF6KVNB4KAGHE723", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVAFJF6KVNB4K6PGXJVK"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVDYJ253JCNT63948648', 'p', 1, '2020-09-20 17:42:46.979775+00', '2020-09-20 18:22:26.321009+00', '2020-09-20 17:42:46.975719+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:46.975719464Z", "event_ulid": "01EJP9RVDYJ253JCNT63948648", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVAFJF6KVNB4K6PGXJVK"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVM1VE5XY8YYDK40PFV2', 'p', 2, '2020-09-20 17:42:47.176677+00', '2020-09-20 18:22:31.690797+00', '2020-09-20 17:42:47.170049+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV", "timestamp": "2020-09-20T17:42:47.170048631Z", "event_ulid": "01EJP9RVM1VE5XY8YYDK40PFV2", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVM1VE5XY8YYDJR4DVC1"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RR4V1Q2JAJCVT34PDBD5', 'p', 1, '2020-09-20 17:42:43.612734+00', '2020-09-20 18:22:26.356817+00', '2020-09-20 17:42:43.611232+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4", "timestamp": "2020-09-20T17:42:43.611232358Z", "event_ulid": "01EJP9RR4V1Q2JAJCVT34PDBD5", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RR4TH46SB049QZ2ES0EQ"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RR6G37YEQ3TT6Z1TTAS0', 'p', 1, '2020-09-20 17:42:43.665966+00', '2020-09-20 18:22:26.362615+00', '2020-09-20 17:42:43.664499+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:43.664498625Z", "event_ulid": "01EJP9RR6G37YEQ3TT6Z1TTAS0", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RR4TH46SB049QZ2ES0EQ"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RTHNQJBBT2QVNBN4V9X3', 'p', 1, '2020-09-20 17:42:46.076737+00', '2020-09-20 18:22:26.368839+00', '2020-09-20 17:42:46.069592+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:46.069592009Z", "event_ulid": "01EJP9RTHNQJBBT2QVNBN4V9X3", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RTGPD0M1T5NXYNN52R7V", "operation_id": "01EJP9RTHNQJBBT2QVNBN4V9X3", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RTNH8ERENR0A5KK03551', 'p', 1, '2020-09-20 17:42:46.195607+00', '2020-09-20 18:22:26.375099+00', '2020-09-20 17:42:46.193936+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR", "timestamp": "2020-09-20T17:42:46.193936304Z", "event_ulid": "01EJP9RTNH8ERENR0A5KK03551", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RTNH8ERENR0A5JR7W7FJ"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RV2HQDW7GZ8V1BX3HF1D', 'p', 1, '2020-09-20 17:42:46.615952+00', '2020-09-20 18:22:26.380406+00', '2020-09-20 17:42:46.609532+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:46.609532421Z", "event_ulid": "01EJP9RV2HQDW7GZ8V1BX3HF1D", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RTNH8ERENR0A5JR7W7FJ"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVB82GFF3HD2H673SY0K', 'p', 1, '2020-09-20 17:42:46.897475+00', '2020-09-20 18:22:26.398358+00', '2020-09-20 17:42:46.888834+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:46.888833561Z", "event_ulid": "01EJP9RVB82GFF3HD2H673SY0K", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVAFJF6KVNB4K6PGXJVK", "operation_id": "01EJP9RVB82GFF3HD2H673SY0K", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVE0C5D0F635590RVK29', 'p', 1, '2020-09-20 17:42:46.978805+00', '2020-09-20 18:22:26.404665+00', '2020-09-20 17:42:46.976806+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X", "timestamp": "2020-09-20T17:42:46.976806194Z", "event_ulid": "01EJP9RVE0C5D0F635590RVK29", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVE0C5D0F63557P7354Y"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVHA6DK0V7GN9XXG5HXA', 'p', 1, '2020-09-20 17:42:47.087781+00', '2020-09-20 18:22:26.416081+00', '2020-09-20 17:42:47.082991+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR", "timestamp": "2020-09-20T17:42:47.082990919Z", "event_ulid": "01EJP9RVHA6DK0V7GN9XXG5HXA", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVHA6DK0V7GN9WH4HFGD"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVJPVPW8M3PSSAGX7REP', 'p', 1, '2020-09-20 17:42:47.134461+00', '2020-09-20 18:22:26.420806+00', '2020-09-20 17:42:47.12634+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:47.126340283Z", "event_ulid": "01EJP9RVJPVPW8M3PSSAGX7REP", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVHA6DK0V7GN9WH4HFGD"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVMJ7B10NFVQVEEN2K48', 'p', 2, '2020-09-20 17:42:47.192092+00', '2020-09-20 18:22:31.696664+00', '2020-09-20 17:42:47.186832+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:47.18683177Z", "event_ulid": "01EJP9RVMJ7B10NFVQVEEN2K48", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVM1VE5XY8YYDJR4DVC1", "operation_id": "01EJP9RVMJ7B10NFVQVEEN2K48", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVSS83EXEK6DRYKDHJ3F', 'p', 1, '2020-09-20 17:42:47.36129+00', '2020-09-20 18:22:26.435264+00', '2020-09-20 17:42:47.353981+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4", "timestamp": "2020-09-20T17:42:47.353981226Z", "event_ulid": "01EJP9RVSS83EXEK6DRYKDHJ3F", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVSRG6R0N1R2SKZQVGGK"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVTA3NB5VR32S3DVCHW4', 'p', 1, '2020-09-20 17:42:47.373383+00', '2020-09-20 18:22:26.441736+00', '2020-09-20 17:42:47.370184+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:47.370184403Z", "event_ulid": "01EJP9RVTA3NB5VR32S3DVCHW4", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVSRG6R0N1R2SKZQVGGK", "operation_id": "01EJP9RVTA3NB5VR32S3DVCHW4", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVVBNEMW8NCYS6VC2GHG', 'p', 1, '2020-09-20 17:42:47.408814+00', '2020-09-20 18:22:26.447649+00', '2020-09-20 17:42:47.40376+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X", "timestamp": "2020-09-20T17:42:47.403759899Z", "event_ulid": "01EJP9RVVBNEMW8NCYS6VC2GHG", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVVBNEMW8NCYS5C89TG9"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVX35Z13N240JNA4ZWFB', 'p', 1, '2020-09-20 17:42:47.46364+00', '2020-09-20 18:22:26.453267+00', '2020-09-20 17:42:47.459727+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:47.459727068Z", "event_ulid": "01EJP9RVX35Z13N240JNA4ZWFB", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVVBNEMW8NCYS5C89TG9"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RXTHY4QYS5GJWAKJ8ZHG', 'p', 1, '2020-09-20 17:42:49.429925+00', '2020-09-20 18:22:26.485507+00', '2020-09-20 17:42:49.425271+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X", "timestamp": "2020-09-20T17:42:49.425271292Z", "event_ulid": "01EJP9RXTHY4QYS5GJWAKJ8ZHG", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXTHY4QYS5GJW76013ZV"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RXY8FAKTENWJDY448503', 'p', 1, '2020-09-20 17:42:49.547561+00', '2020-09-20 18:22:26.493752+00', '2020-09-20 17:42:49.545173+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:49.545172844Z", "event_ulid": "01EJP9RXY8FAKTENWJDY448503", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXTHY4QYS5GJW76013ZV"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RY0NMZ9J8C72FFHBDNS8', 'p', 2, '2020-09-20 17:42:49.623908+00', '2020-09-20 18:22:31.702656+00', '2020-09-20 17:42:49.621772+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV", "timestamp": "2020-09-20T17:42:49.621771965Z", "event_ulid": "01EJP9RY0NMZ9J8C72FFHBDNS8", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY0NMZ9J8C72FES14C7Y"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RY4NMWJ2TPFCQ6BHNSWN', 'p', 1, '2020-09-20 17:42:49.753016+00', '2020-09-20 18:22:26.526851+00', '2020-09-20 17:42:49.749833+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4", "timestamp": "2020-09-20T17:42:49.749832933Z", "event_ulid": "01EJP9RY4NMWJ2TPFCQ6BHNSWN", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY4NMWJ2TPFCQ3WY5TNF"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RY50K4CWHMQKK17CKWBJ', 'p', 1, '2020-09-20 17:42:49.762443+00', '2020-09-20 18:22:26.535788+00', '2020-09-20 17:42:49.760501+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:49.76050077Z", "event_ulid": "01EJP9RY50K4CWHMQKK17CKWBJ", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY4NMWJ2TPFCQ3WY5TNF", "operation_id": "01EJP9RY50K4CWHMQKK17CKWBJ", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVVRM0JXSGA1436NWKJX', 'p', 1, '2020-09-20 17:42:47.418614+00', '2020-09-20 18:22:26.545726+00', '2020-09-20 17:42:47.416416+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:47.416415698Z", "event_ulid": "01EJP9RVVRM0JXSGA1436NWKJX", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVVBNEMW8NCYS5C89TG9", "operation_id": "01EJP9RVVRM0JXSGA1436NWKJX", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVX4KHT1D9DY96KKVK3B', 'p', 1, '2020-09-20 17:42:47.46268+00', '2020-09-20 18:22:26.55547+00', '2020-09-20 17:42:47.460511+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR", "timestamp": "2020-09-20T17:42:47.460511246Z", "event_ulid": "01EJP9RVX4KHT1D9DY96KKVK3B", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVX4KHT1D9DY967NSGFY"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVXEZ0S9CYPRWQH5Z627', 'p', 1, '2020-09-20 17:42:47.472768+00', '2020-09-20 18:22:26.564237+00', '2020-09-20 17:42:47.470725+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:47.470725114Z", "event_ulid": "01EJP9RVXEZ0S9CYPRWQH5Z627", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVX4KHT1D9DY967NSGFY", "operation_id": "01EJP9RVXEZ0S9CYPRWQH5Z627", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RY2ECKHND43SG3V0T1Y0', 'p', 2, '2020-09-20 17:42:49.68085+00', '2020-09-20 18:22:31.708444+00', '2020-09-20 17:42:49.679518+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:49.679518131Z", "event_ulid": "01EJP9RY2ECKHND43SG3V0T1Y0", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY0NMZ9J8C72FES14C7Y"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RX9DTXKB3VZ1FKPJZNZ1', 'p', 3, '2020-09-20 17:42:48.880979+00', '2020-09-20 18:22:41.711871+00', '2020-09-20 17:42:48.878683+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:48.87868255Z", "event_ulid": "01EJP9RX9DTXKB3VZ1FKPJZNZ1", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RX737YVMRJNW04W8MM0Q"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RXMPV6SKF7EDMVEKTN9W', 'p', 1, '2020-09-20 17:42:49.239656+00', '2020-09-20 18:22:26.591602+00', '2020-09-20 17:42:49.238402+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4", "timestamp": "2020-09-20T17:42:49.238402291Z", "event_ulid": "01EJP9RXMPV6SKF7EDMVEKTN9W", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXMPV6SKF7EDMRV4E5J1"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RXQ0BEYZYHJTGXMZJ6BD', 'p', 1, '2020-09-20 17:42:49.314466+00', '2020-09-20 18:22:26.600384+00', '2020-09-20 17:42:49.312343+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:49.312342694Z", "event_ulid": "01EJP9RXQ0BEYZYHJTGXMZJ6BD", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXMPV6SKF7EDMRV4E5J1"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RXV1ZYMBN0PB7AE3M41S', 'p', 1, '2020-09-20 17:42:49.444983+00', '2020-09-20 18:22:26.610096+00', '2020-09-20 17:42:49.442033+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:49.44203292Z", "event_ulid": "01EJP9RXV1ZYMBN0PB7AE3M41S", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXTHY4QYS5GJW76013ZV", "operation_id": "01EJP9RXV1ZYMBN0PB7AE3M41S", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RXYFQKCGXANTJZYVV2KG', 'p', 1, '2020-09-20 17:42:49.553472+00', '2020-09-20 18:22:26.62017+00', '2020-09-20 17:42:49.551916+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR", "timestamp": "2020-09-20T17:42:49.551916159Z", "event_ulid": "01EJP9RXYFQKCGXANTJZYVV2KG", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXYFQKCGXANTJXHM6S6Y"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RY09VED5VGGSDN6BTF02', 'p', 1, '2020-09-20 17:42:49.610816+00', '2020-09-20 18:22:26.627885+00', '2020-09-20 17:42:49.609478+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:49.609478224Z", "event_ulid": "01EJP9RY09VED5VGGSDN6BTF02", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXYFQKCGXANTJXHM6S6Y"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RY2FDEW8G382AJVV1HWS', 'p', 2, '2020-09-20 17:42:49.681475+00', '2020-09-20 18:22:36.649234+00', '2020-09-20 17:42:49.679886+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS", "timestamp": "2020-09-20T17:42:49.679886055Z", "event_ulid": "01EJP9RY2FDEW8G382AJVV1HWS", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY2FDEW8G382AJECQ03Z"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RY5ANW6WWQY3PZ77NCMJ', 'p', 1, '2020-09-20 17:42:49.772326+00', '2020-09-20 18:22:26.651799+00', '2020-09-20 17:42:49.770483+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:49.770482765Z", "event_ulid": "01EJP9RY5ANW6WWQY3PZ77NCMJ", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY4NMWJ2TPFCQ3WY5TNF"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RAHYERK1Y0ZFRBGEY470', 'p', 1, '2020-09-20 17:42:29.698245+00', '2020-09-20 18:22:26.681629+00', '2020-09-20 17:42:29.694783+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/kube-system/deployments/coredns", "timestamp": "2020-09-20T17:42:29.694783202Z", "event_ulid": "01EJP9RAHYERK1Y0ZFRBGEY470", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAHCH415DJMRB208ADWG", "operation_id": "01EJP9RAHYERK1Y0ZFRBGEY470", "incarnation_id": "i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1", "entity_description": "deployment coredns", "incarnation_description": "deployment coredns"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RAJVZTV7ZG1493GP3K1E', 'p', 1, '2020-09-20 17:42:29.727937+00', '2020-09-20 18:22:26.6906+00', '2020-09-20 17:42:29.723609+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X", "timestamp": "2020-09-20T17:42:29.723608932Z", "event_ulid": "01EJP9RAJVZTV7ZG1493GP3K1E", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAJT3N1HE1JRX5BDM0C9"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RAMJ3RE41FW5NGHJNTN4', 'p', 1, '2020-09-20 17:42:29.782412+00', '2020-09-20 18:22:26.69871+00', '2020-09-20 17:42:29.779239+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:29.779238628Z", "event_ulid": "01EJP9RAMJ3RE41FW5NGHJNTN4", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAJT3N1HE1JRX5BDM0C9"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RAN4PBQSGK2FCZVVYRZS', 'p', 1, '2020-09-20 17:42:29.800499+00', '2020-09-20 18:22:26.707594+00', '2020-09-20 17:42:29.79755+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:29.797550453Z", "event_ulid": "01EJP9RAN4PBQSGK2FCZVVYRZS", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAMKA8S8S5BMJA0E5MTE"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RE129DRBKKFXDZQEMXFB', 'p', 1, '2020-09-20 17:42:33.254803+00', '2020-09-20 18:22:26.732009+00', '2020-09-20 17:42:33.250965+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:33.250965342Z", "event_ulid": "01EJP9RE129DRBKKFXDZQEMXFB", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE0Q9J5SYK5ZBQSQ01V2", "operation_id": "01EJP9RE129DRBKKFXDZQEMXFB", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RE52E78V6KNHF0Q8M70W', 'p', 1, '2020-09-20 17:42:33.38102+00', '2020-09-20 18:22:26.740356+00', '2020-09-20 17:42:33.379038+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X", "timestamp": "2020-09-20T17:42:33.379038323Z", "event_ulid": "01EJP9RE52E78V6KNHF0Q8M70W", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE52E78V6KNHEZGEWXWB"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RE64S5W4T3TB2B30N8RM', 'p', 1, '2020-09-20 17:42:33.414994+00', '2020-09-20 18:22:26.748305+00', '2020-09-20 17:42:33.412901+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:33.412901286Z", "event_ulid": "01EJP9RE64S5W4T3TB2B30N8RM", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE52E78V6KNHEZGEWXWB"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDSXB6Z116C8JAXHYJCW', 'p', 2, '2020-09-20 17:42:33.022955+00', '2020-09-20 18:22:31.724994+00', '2020-09-20 17:42:33.021739+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV", "timestamp": "2020-09-20T17:42:33.021739281Z", "event_ulid": "01EJP9RDSXB6Z116C8JAXHYJCW", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RDSXB6Z116C8JAEG6CRF"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RE7C9QK9Q7V3VB13989F', 'p', 1, '2020-09-20 17:42:33.462331+00', '2020-09-20 18:22:26.756937+00', '2020-09-20 17:42:33.453645+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:33.453645012Z", "event_ulid": "01EJP9RE7C9QK9Q7V3VB13989F", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE72V4KXXSKCYZ6PDSEZ", "operation_id": "01EJP9RE7C9QK9Q7V3VB13989F", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDYSM2J1P530KNSC8VBM', 'p', 3, '2020-09-20 17:42:33.179779+00', '2020-09-20 18:22:41.719971+00', '2020-09-20 17:42:33.177691+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:33.177690945Z", "event_ulid": "01EJP9RDYSM2J1P530KNSC8VBM", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RDXFMFD27ERA78811GTE", "operation_id": "01EJP9RDYSM2J1P530KNSC8VBM", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9REA4TK7NR750RV9CWVJ7', 'p', 2, '2020-09-20 17:42:33.544063+00', '2020-09-20 18:22:36.672705+00', '2020-09-20 17:42:33.540409+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:33.540409391Z", "event_ulid": "01EJP9REA4TK7NR750RV9CWVJ7", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE98R4XKYN7NV8HP95D9"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RAK5SKHVKJZ0SPNDY6EA', 'p', 2, '2020-09-20 17:42:29.737587+00', '2020-09-20 18:22:31.718222+00', '2020-09-20 17:42:29.733961+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/kube-system/deployments/coredns", "timestamp": "2020-09-20T17:42:29.733960807Z", "event_ulid": "01EJP9RAK5SKHVKJZ0SPNDY6EA", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAJT3N1HE1JRX5BDM0C9", "operation_id": "01EJP9RAK5SKHVKJZ0SPNDY6EA", "incarnation_id": "i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1", "entity_description": "deployment coredns", "incarnation_description": "deployment coredns"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RR5TGGX8D45HTV6GTG8S', 'p', 2, '2020-09-20 17:42:43.64483+00', '2020-09-20 18:22:31.747099+00', '2020-09-20 17:42:43.642541+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/kube-system/deployments/coredns", "timestamp": "2020-09-20T17:42:43.642540806Z", "event_ulid": "01EJP9RR5TGGX8D45HTV6GTG8S", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RR4TH46SB049QZ2ES0EQ", "operation_id": "01EJP9RR5TGGX8D45HTV6GTG8S", "incarnation_id": "i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1", "entity_description": "deployment coredns", "incarnation_description": "deployment coredns"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RE5JWXJWZAE7YTY7FWZD', 'p', 2, '2020-09-20 17:42:33.39844+00', '2020-09-20 18:22:31.740894+00', '2020-09-20 17:42:33.395484+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:33.395483989Z", "event_ulid": "01EJP9RE5JWXJWZAE7YTY7FWZD", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE52E78V6KNHEZGEWXWB", "operation_id": "01EJP9RE5JWXJWZAE7YTY7FWZD", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDXE93AS8R7Y70T43VRS', 'p', 2, '2020-09-20 17:42:33.136589+00', '2020-09-20 18:22:31.73046+00', '2020-09-20 17:42:33.134974+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:33.134973784Z", "event_ulid": "01EJP9RDXE93AS8R7Y70T43VRS", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RDSXB6Z116C8JAEG6CRF"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RV4813SGSYFYS26551D3', 'p', 2, '2020-09-20 17:42:46.670795+00', '2020-09-20 18:22:31.760997+00', '2020-09-20 17:42:46.665026+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV", "timestamp": "2020-09-20T17:42:46.665025786Z", "event_ulid": "01EJP9RV4813SGSYFYS26551D3", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RV4813SGSYFYRYV49J0X"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RTNZJS1GHMCQH4X1R7ZT', 'p', 2, '2020-09-20 17:42:46.212252+00', '2020-09-20 18:22:31.754495+00', '2020-09-20 17:42:46.207697+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:46.207697271Z", "event_ulid": "01EJP9RTNZJS1GHMCQH4X1R7ZT", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RTNH8ERENR0A5JR7W7FJ", "operation_id": "01EJP9RTNZJS1GHMCQH4X1R7ZT", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RV7AQX4HN3MYGXGVN7S6', 'p', 2, '2020-09-20 17:42:46.767548+00', '2020-09-20 18:22:31.766883+00', '2020-09-20 17:42:46.762507+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:46.76250717Z", "event_ulid": "01EJP9RV7AQX4HN3MYGXGVN7S6", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RV4813SGSYFYRYV49J0X"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RE98R4XKYN7NV9TY6QEM', 'p', 2, '2020-09-20 17:42:33.51538+00', '2020-09-20 18:22:36.661636+00', '2020-09-20 17:42:33.512887+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV", "timestamp": "2020-09-20T17:42:33.512887178Z", "event_ulid": "01EJP9RE98R4XKYN7NV9TY6QEM", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE98R4XKYN7NV8HP95D9"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVHA6DK0V7GN9TBM1WGW', 'p', 2, '2020-09-20 17:42:47.085918+00', '2020-09-20 18:22:31.776872+00', '2020-09-20 17:42:47.082374+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:47.082373522Z", "event_ulid": "01EJP9RVHA6DK0V7GN9TBM1WGW", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVE0C5D0F63557P7354Y"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVQ4HGWHP60XA5JQDQ56', 'p', 2, '2020-09-20 17:42:47.273895+00', '2020-09-20 18:22:31.783042+00', '2020-09-20 17:42:47.268837+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS", "timestamp": "2020-09-20T17:42:47.268836606Z", "event_ulid": "01EJP9RVQ4HGWHP60XA5JQDQ56", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVQ4HGWHP60XA2J5CSNZ"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVQKDWFW575NZWXC8GS4', 'p', 2, '2020-09-20 17:42:47.286846+00', '2020-09-20 18:22:31.789492+00', '2020-09-20 17:42:47.283857+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:47.283856951Z", "event_ulid": "01EJP9RVQKDWFW575NZWXC8GS4", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVQ4HGWHP60XA2J5CSNZ", "operation_id": "01EJP9RVQKDWFW575NZWXC8GS4", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVSJWHCWBXDMQJP469ZZ', 'p', 2, '2020-09-20 17:42:47.361766+00', '2020-09-20 18:22:31.795894+00', '2020-09-20 17:42:47.347032+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:47.347032019Z", "event_ulid": "01EJP9RVSJWHCWBXDMQJP469ZZ", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVQ4HGWHP60XA2J5CSNZ"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVTYA85FSHXMGJRCDVKZ', 'p', 2, '2020-09-20 17:42:47.393789+00', '2020-09-20 18:22:31.801738+00', '2020-09-20 17:42:47.390407+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:47.390406805Z", "event_ulid": "01EJP9RVTYA85FSHXMGJRCDVKZ", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVSRG6R0N1R2SKZQVGGK"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RR1S8GWG8BEQ0T62056H', 'p', 2, '2020-09-20 17:42:43.523173+00', '2020-09-20 18:22:31.808022+00', '2020-09-20 17:42:43.513877+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/kube-system/deployments/coredns", "timestamp": "2020-09-20T17:42:43.513876688Z", "event_ulid": "01EJP9RR1S8GWG8BEQ0T62056H", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RR0SB8V90BRMKW65F7D9", "operation_id": "01EJP9RR1S8GWG8BEQ0T62056H", "incarnation_id": "i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1", "entity_description": "deployment coredns", "incarnation_description": "deployment coredns"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RV4N04Y5J17FR00NJ7VZ', 'p', 2, '2020-09-20 17:42:46.68233+00', '2020-09-20 18:22:31.816118+00', '2020-09-20 17:42:46.678397+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:46.678397039Z", "event_ulid": "01EJP9RV4N04Y5J17FR00NJ7VZ", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RV4813SGSYFYRYV49J0X", "operation_id": "01EJP9RV4N04Y5J17FR00NJ7VZ", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RV7AQX4HN3MYH47TX1KG', 'p', 2, '2020-09-20 17:42:46.771819+00', '2020-09-20 18:22:31.825674+00', '2020-09-20 17:42:46.762842+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS", "timestamp": "2020-09-20T17:42:46.76284185Z", "event_ulid": "01EJP9RV7AQX4HN3MYH47TX1KG", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RV7AQX4HN3MYH19P8P5V"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RV90QP5XMT2Z9XJHSZ9A', 'p', 2, '2020-09-20 17:42:46.821222+00', '2020-09-20 18:22:31.834776+00', '2020-09-20 17:42:46.816418+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:46.816418212Z", "event_ulid": "01EJP9RV90QP5XMT2Z9XJHSZ9A", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RV7AQX4HN3MYH19P8P5V"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RVQ20VPV7TYN1D8FX2WD', 'p', 2, '2020-09-20 17:42:47.277722+00', '2020-09-20 18:22:31.843897+00', '2020-09-20 17:42:47.267042+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:47.267041964Z", "event_ulid": "01EJP9RVQ20VPV7TYN1D8FX2WD", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVM1VE5XY8YYDJR4DVC1"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RWKB77RWEF70SRN00A10', 'p', 2, '2020-09-20 17:42:48.173938+00', '2020-09-20 18:22:31.853429+00', '2020-09-20 17:42:48.171616+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:48.171616428Z", "event_ulid": "01EJP9RWKB77RWEF70SRN00A10", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVX4KHT1D9DY967NSGFY"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RX7DBEY871HT3XGEMA7G', 'p', 3, '2020-09-20 17:42:48.817629+00', '2020-09-20 18:22:41.728497+00', '2020-09-20 17:42:48.813594+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:48.813594389Z", "event_ulid": "01EJP9RX7DBEY871HT3XGEMA7G", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RX737YVMRJNW04W8MM0Q", "operation_id": "01EJP9RX7DBEY871HT3XGEMA7G", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RX9EXDE6QB3NK4PNCXEK', 'p', 2, '2020-09-20 17:42:48.882306+00', '2020-09-20 18:22:31.869715+00', '2020-09-20 17:42:48.879166+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS", "timestamp": "2020-09-20T17:42:48.879166131Z", "event_ulid": "01EJP9RX9EXDE6QB3NK4PNCXEK", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RX9EXDE6QB3NK1MMCKFC"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RXAJRZ7YDP2DVK3TFP8B', 'p', 2, '2020-09-20 17:42:48.920601+00', '2020-09-20 18:22:31.87933+00', '2020-09-20 17:42:48.914746+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:48.914746351Z", "event_ulid": "01EJP9RXAJRZ7YDP2DVK3TFP8B", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RX9EXDE6QB3NK1MMCKFC"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RXN2G0XEEZHP24MDFGGQ', 'p', 2, '2020-09-20 17:42:49.253611+00', '2020-09-20 18:22:31.888265+00', '2020-09-20 17:42:49.250849+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:49.250848565Z", "event_ulid": "01EJP9RXN2G0XEEZHP24MDFGGQ", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXMPV6SKF7EDMRV4E5J1", "operation_id": "01EJP9RXN2G0XEEZHP24MDFGGQ", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RXYQAD0NNZ0EW8C0BT9R', 'p', 2, '2020-09-20 17:42:49.561938+00', '2020-09-20 18:22:31.89775+00', '2020-09-20 17:42:49.559596+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:49.559595906Z", "event_ulid": "01EJP9RXYQAD0NNZ0EW8C0BT9R", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXYFQKCGXANTJXHM6S6Y", "operation_id": "01EJP9RXYQAD0NNZ0EW8C0BT9R", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RX737YVMRJNW05D2XYXS', 'p', 2, '2020-09-20 17:42:48.806905+00', '2020-09-20 18:22:31.907337+00', '2020-09-20 17:42:48.803681+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV", "timestamp": "2020-09-20T17:42:48.803681118Z", "event_ulid": "01EJP9RX737YVMRJNW05D2XYXS", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RX737YVMRJNW04W8MM0Q"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R9FV2M20K553R6FG5NMQ', 'p', 2, '2020-09-20 17:42:28.604528+00', '2020-09-20 18:22:36.69023+00', '2020-09-20 17:42:28.603463+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV", "timestamp": "2020-09-20T17:42:28.603462936Z", "event_ulid": "01EJP9R9FV2M20K553R6FG5NMQ", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9FV2M20K553R4BE5CQ5"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RX9Z856F69JZ8J4MHN0B', 'p', 2, '2020-09-20 17:42:48.903029+00', '2020-09-20 18:22:31.916551+00', '2020-09-20 17:42:48.896002+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:48.896002349Z", "event_ulid": "01EJP9RX9Z856F69JZ8J4MHN0B", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RX9EXDE6QB3NK1MMCKFC", "operation_id": "01EJP9RX9Z856F69JZ8J4MHN0B", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R9HB65DBCNP25P0W0GAC', 'p', 2, '2020-09-20 17:42:28.652954+00', '2020-09-20 18:22:36.717661+00', '2020-09-20 17:42:28.651667+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:28.651667387Z", "event_ulid": "01EJP9R9HB65DBCNP25P0W0GAC", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9GH6AWYYQ725XW5A32M"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RY4KNTWP96HPKAWG4ANG', 'p', 2, '2020-09-20 17:42:49.753658+00', '2020-09-20 18:22:36.681012+00', '2020-09-20 17:42:49.747987+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:49.747986889Z", "event_ulid": "01EJP9RY4KNTWP96HPKAWG4ANG", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY2FDEW8G382AJECQ03Z"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R9G6NRC2W0WXNCXEXEYE', 'p', 2, '2020-09-20 17:42:28.615944+00', '2020-09-20 18:22:36.698624+00', '2020-09-20 17:42:28.614943+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/kube-system/deployments/coredns", "timestamp": "2020-09-20T17:42:28.614942608Z", "event_ulid": "01EJP9R9G6NRC2W0WXNCXEXEYE", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9FV2M20K553R4BE5CQ5", "operation_id": "01EJP9R9G6NRC2W0WXNCXEXEYE", "incarnation_id": "i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1", "entity_description": "deployment coredns", "incarnation_description": "deployment coredns"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RE0PXRCBJ1PG0FJG1GBR', 'p', 2, '2020-09-20 17:42:33.240444+00', '2020-09-20 18:22:36.745996+00', '2020-09-20 17:42:33.238499+00', 'EventExecutionEnds', '{"timestamp": "2020-09-20T17:42:33.238499232Z", "event_ulid": "01EJP9RE0PXRCBJ1PG0FJG1GBR", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RDXFMFD27ERA78811GTE"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9R9GH6AWYYQ7261FCP5SJ', 'p', 2, '2020-09-20 17:42:28.630608+00', '2020-09-20 18:22:36.708523+00', '2020-09-20 17:42:28.626002+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS", "timestamp": "2020-09-20T17:42:28.626002114Z", "event_ulid": "01EJP9R9GH6AWYYQ7261FCP5SJ", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9GH6AWYYQ725XW5A32M"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDT5ASB37AQ7P5GRZN25', 'p', 2, '2020-09-20 17:42:33.030946+00', '2020-09-20 18:22:36.727209+00', '2020-09-20 17:42:33.029302+00', 'EventOperation', '{"type": "r", "entity_id": "en:///apis/apps/v1/namespaces/default/deployments/nginx", "timestamp": "2020-09-20T17:42:33.029302253Z", "event_ulid": "01EJP9RDT5ASB37AQ7P5GRZN25", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RDSXB6Z116C8JAEG6CRF", "operation_id": "01EJP9RDT5ASB37AQ7P5GRZN25", "incarnation_id": "i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1", "entity_description": "deployment nginx", "incarnation_description": "deployment nginx"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJP9RDXFMFD27ERA7A4XSKV4', 'p', 2, '2020-09-20 17:42:33.138509+00', '2020-09-20 18:22:36.736986+00', '2020-09-20 17:42:33.135856+00', 'EventExecutionBegins', '{"parent_id": "ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS", "timestamp": "2020-09-20T17:42:33.135856019Z", "event_ulid": "01EJP9RDXFMFD27ERA7A4XSKV4", "description": "kube DC process one", "execution_id": "ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RDXFMFD27ERA78811GTE"}') ON CONFLICT DO NOTHING;


--
-- Data for Name: executions; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.executions VALUES ('ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', '2020-09-20 18:22:25.989843+00', '2020-09-20 17:42:31.905646+00', 'ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9', NULL, NULL, 'kubectl apply resource building', '2020-09-20 17:42:32.89382+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD', '2020-09-20 18:22:26.046103+00', '2020-09-20 17:42:32.902944+00', 'ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9', NULL, NULL, 'kubectl apply one', '2020-09-20 17:42:33.011617+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5', '2020-09-20 18:22:26.108385+00', '2020-09-20 17:42:33.022829+00', 'ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9', NULL, NULL, 'kubectl apply one', '2020-09-20 17:42:33.488568+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D', '2020-09-20 18:22:26.175306+00', '2020-09-20 17:42:33.686577+00', 'ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9', NULL, NULL, 'kubectl apply one', '2020-09-20 17:42:33.798699+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY', '2020-09-20 18:22:26.052868+00', '2020-09-20 17:42:33.811354+00', 'ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9', NULL, NULL, 'kubectl apply one', '2020-09-20 17:42:33.936875+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9', '2020-09-20 18:22:25.979909+00', '2020-09-20 17:42:31.515278+00', NULL, NULL, NULL, 'kubectl apply', '2020-09-20 17:42:33.944731+00') ON CONFLICT DO NOTHING;


--
-- Data for Name: graph; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.graph VALUES ('i://file:///dev/null?ulid=01EJP9QYSRXHZM53RCXSFS0PMP', 'read_by', 'ex://kubectl-apply-builder-01EJP9QYSE8DHSMC3MJQCYRBMR', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://file:///dev/null?ulid=01EJP9QZ675722EJV4ZBWACX4M', 'read_by', 'ex://kubectl-apply-builder-01EJP9QZ63G9XB872N48REMV3X', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R98AR33XC4MBDKBB8F4M', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9DQMVTFBF07CYJQM5CF', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAMKA8S8S5BMJA0E5MTE', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://file:///nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json?ulid=01EJP9RCQ95JT85A4AJNP67V6C', 'read_by', 'ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDM2KBXHW0N01QMZSCTZ', 'read_by', 'ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDPT8G67DTE7VN8XX7CX', 'read_by', 'ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDMY6BEN4XZBX83ZX0AW', 'read_by', 'ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDTFQFNCK6GYB5DNJY0Z', 'read_by', 'ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9RDN6VFPTHWG7P6NBGWFC', 'read_by', 'ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REFBRQDS6A0JNZF73E80', 'read_by', 'ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9RDNKD3K51RJACSTS28PA', 'read_by', 'ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REKAW44WKNW8CC1A80V0', 'read_by', 'ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RTGPD0M1T5NXYNN52R7V', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVAFJF6KVNB4K6PGXJVK', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVE0C5D0F63557P7354Y', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVSRG6R0N1R2SKZQVGGK', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY4NMWJ2TPFCQ3WY5TNF', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVVBNEMW8NCYS5C89TG9', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVX4KHT1D9DY967NSGFY', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXTHY4QYS5GJW76013ZV', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAHCH415DJMRB208ADWG', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE0Q9J5SYK5ZBQSQ01V2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE72V4KXXSKCYZ6PDSEZ', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-builder-01EJP9QYSE8DHSMC3MJQCYRBMR', 'reads', 'i://file:///dev/null?ulid=01EJP9QYSRXHZM53RCXSFS0PMP', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-builder-01EJP9QZ63G9XB872N48REMV3X', 'reads', 'i://file:///dev/null?ulid=01EJP9QZ675722EJV4ZBWACX4M', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R98AR33XC4MBDKBB8F4M', 'reads', 'i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9DQMVTFBF07CYJQM5CF', 'reads', 'i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAMKA8S8S5BMJA0E5MTE', 'reads', 'i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', 'reads', 'i://file:///nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json?ulid=01EJP9RCQ95JT85A4AJNP67V6C', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD', 'reads', 'i://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDM2KBXHW0N01QMZSCTZ', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDPT8G67DTE7VN8XX7CX', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5', 'reads', 'i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDMY6BEN4XZBX83ZX0AW', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5', 'reads', 'i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDTFQFNCK6GYB5DNJY0Z', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D', 'reads', 'i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9RDN6VFPTHWG7P6NBGWFC', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D', 'reads', 'i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REFBRQDS6A0JNZF73E80', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY', 'reads', 'i://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9RDNKD3K51RJACSTS28PA', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY', 'reads', 'i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REKAW44WKNW8CC1A80V0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RTGPD0M1T5NXYNN52R7V', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVAFJF6KVNB4K6PGXJVK', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVE0C5D0F63557P7354Y', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVSRG6R0N1R2SKZQVGGK', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY4NMWJ2TPFCQ3WY5TNF', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVVBNEMW8NCYS5C89TG9', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVX4KHT1D9DY967NSGFY', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXTHY4QYS5GJW76013ZV', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAHCH415DJMRB208ADWG', 'reads', 'i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE0Q9J5SYK5ZBQSQ01V2', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE72V4KXXSKCYZ6PDSEZ', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', 'writes', 'i://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDM2KBXHW0N01QMZSCTZ', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', 'writes', 'i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDMY6BEN4XZBX83ZX0AW', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', 'writes', 'i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9RDN6VFPTHWG7P6NBGWFC', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', 'writes', 'i://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9RDNKD3K51RJACSTS28PA', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD', 'writes', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDS7VP68NAQGK4CFW6VH', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5', 'writes', 'i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RE2ZXX51FPC9WT303FQB', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D', 'writes', 'i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REHF3W1074H5NWN2MF90', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY', 'writes', 'i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REP7AB85EW3554GWPR7H', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDM2KBXHW0N01QMZSCTZ', 'written_by', 'ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDMY6BEN4XZBX83ZX0AW', 'written_by', 'ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9RDN6VFPTHWG7P6NBGWFC', 'written_by', 'ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9RDNKD3K51RJACSTS28PA', 'written_by', 'ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDS7VP68NAQGK4CFW6VH', 'written_by', 'ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RE2ZXX51FPC9WT303FQB', 'written_by', 'ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REHF3W1074H5NWN2MF90', 'written_by', 'ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REP7AB85EW3554GWPR7H', 'written_by', 'ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-builder-01EJP9QYSE8DHSMC3MJQCYRBMR', 'child_of', 'ex://kubectl-apply-01EJP9QXYAPH5HCJENYABGSMF3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-builder-01EJP9QZ63G9XB872N48REMV3X', 'child_of', 'ex://kubectl-apply-01EJP9QYYQQDPPCVW0V6TE9CBW', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X', 'child_of', 'ex://kube-DeploymentController-Run-01EJP9R4ETBCWRTMARMD3SRW6M', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR', 'child_of', 'ex://kube-DeploymentController-Run-01EJP9R4ETBCWRTMARMD3SRW6M', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4', 'child_of', 'ex://kube-DeploymentController-Run-01EJP9R4ETBCWRTMARMD3SRW6M', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R98AR33XC4MBDKBB8F4M', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9DQMVTFBF07CYJQM5CF', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAHCH415DJMRB208ADWG', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE0Q9J5SYK5ZBQSQ01V2', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE72V4KXXSKCYZ6PDSEZ', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', 'child_of', 'ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD', 'child_of', 'ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5', 'child_of', 'ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D', 'child_of', 'ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY', 'child_of', 'ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RTGPD0M1T5NXYNN52R7V', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVAFJF6KVNB4K6PGXJVK', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RR4TH46SB049QZ2ES0EQ', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RTNH8ERENR0A5JR7W7FJ', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVE0C5D0F63557P7354Y', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVHA6DK0V7GN9WH4HFGD', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVSRG6R0N1R2SKZQVGGK', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVVBNEMW8NCYS5C89TG9', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXTHY4QYS5GJW76013ZV', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVX4KHT1D9DY967NSGFY', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXMPV6SKF7EDMRV4E5J1', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXYFQKCGXANTJXHM6S6Y', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY4NMWJ2TPFCQ3WY5TNF', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAJT3N1HE1JRX5BDM0C9', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAMKA8S8S5BMJA0E5MTE', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE52E78V6KNHEZGEWXWB', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-01EJP9QXYAPH5HCJENYABGSMF3', 'parent_of', 'ex://kubectl-apply-builder-01EJP9QYSE8DHSMC3MJQCYRBMR', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-01EJP9QYYQQDPPCVW0V6TE9CBW', 'parent_of', 'ex://kubectl-apply-builder-01EJP9QZ63G9XB872N48REMV3X', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-Run-01EJP9R4ETBCWRTMARMD3SRW6M', 'parent_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-Run-01EJP9R4ETBCWRTMARMD3SRW6M', 'parent_of', 'ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-Run-01EJP9R4ETBCWRTMARMD3SRW6M', 'parent_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R98AR33XC4MBDKBB8F4M', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9DQMVTFBF07CYJQM5CF', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAHCH415DJMRB208ADWG', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE0Q9J5SYK5ZBQSQ01V2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE72V4KXXSKCYZ6PDSEZ', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9', 'parent_of', 'ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9', 'parent_of', 'ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9', 'parent_of', 'ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9', 'parent_of', 'ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kubectl-apply-01EJP9RCAVZB25SQGSVJGAV4V9', 'parent_of', 'ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RTGPD0M1T5NXYNN52R7V', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVAFJF6KVNB4K6PGXJVK', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RR4TH46SB049QZ2ES0EQ', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RTNH8ERENR0A5JR7W7FJ', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVE0C5D0F63557P7354Y', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVHA6DK0V7GN9WH4HFGD', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVSRG6R0N1R2SKZQVGGK', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVVBNEMW8NCYS5C89TG9', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXTHY4QYS5GJW76013ZV', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVX4KHT1D9DY967NSGFY', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXMPV6SKF7EDMRV4E5J1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXYFQKCGXANTJXHM6S6Y', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q839KQ7HPNH5KYCJY4', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY4NMWJ2TPFCQ3WY5TNF', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAJT3N1HE1JRX5BDM0C9', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6QFH6H43Q6CWFY2PJMR', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAMKA8S8S5BMJA0E5MTE', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q8JKXAW4N8BX1X254X', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE52E78V6KNHEZGEWXWB', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://file:///dev/null?ulid=01EJP9QYSRXHZM53RCXSFS0PMP', 'instance_of', 'en://file:///dev/null', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://file:///dev/null?ulid=01EJP9QZ675722EJV4ZBWACX4M', 'instance_of', 'en://file:///dev/null', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://file:///nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json?ulid=01EJP9RCQ95JT85A4AJNP67V6C', 'instance_of', 'en://file:///nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDM2KBXHW0N01QMZSCTZ', 'instance_of', 'en://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDPT8G67DTE7VN8XX7CX', 'instance_of', 'en:///apis/apps/v1/namespaces/default/deployments/nginx', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDS7VP68NAQGK4CFW6VH', 'instance_of', 'en:///apis/apps/v1/namespaces/default/deployments/nginx', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDMY6BEN4XZBX83ZX0AW', 'instance_of', 'en://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDTFQFNCK6GYB5DNJY0Z', 'instance_of', 'en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RE2ZXX51FPC9WT303FQB', 'instance_of', 'en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9RDN6VFPTHWG7P6NBGWFC', 'instance_of', 'en://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REFBRQDS6A0JNZF73E80', 'instance_of', 'en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REHF3W1074H5NWN2MF90', 'instance_of', 'en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9RDNKD3K51RJACSTS28PA', 'instance_of', 'en://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REKAW44WKNW8CC1A80V0', 'instance_of', 'en://https://192.168.1.1/api/v1/namespaces/default/services/nginx', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REP7AB85EW3554GWPR7H', 'instance_of', 'en://https://192.168.1.1/api/v1/namespaces/default/services/nginx', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', 'instance_of', 'en:///apis/apps/v1/namespaces/kube-system/deployments/coredns', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'instance_of', 'en:///apis/apps/v1/namespaces/default/deployments/nginx', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en://file:///dev/null', 'entity_of', 'i://file:///dev/null?ulid=01EJP9QYSRXHZM53RCXSFS0PMP', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en://file:///dev/null', 'entity_of', 'i://file:///dev/null?ulid=01EJP9QZ675722EJV4ZBWACX4M', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en://file:///nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json', 'entity_of', 'i://file:///nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json?ulid=01EJP9RCQ95JT85A4AJNP67V6C', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx', 'entity_of', 'i://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDM2KBXHW0N01QMZSCTZ', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en:///apis/apps/v1/namespaces/default/deployments/nginx', 'entity_of', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDPT8G67DTE7VN8XX7CX', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en:///apis/apps/v1/namespaces/default/deployments/nginx', 'entity_of', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDS7VP68NAQGK4CFW6VH', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', 'entity_of', 'i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDMY6BEN4XZBX83ZX0AW', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', 'entity_of', 'i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDTFQFNCK6GYB5DNJY0Z', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', 'entity_of', 'i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RE2ZXX51FPC9WT303FQB', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', 'entity_of', 'i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9RDN6VFPTHWG7P6NBGWFC', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', 'entity_of', 'i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REFBRQDS6A0JNZF73E80', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', 'entity_of', 'i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REHF3W1074H5NWN2MF90', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx', 'entity_of', 'i://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9RDNKD3K51RJACSTS28PA', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en://https://192.168.1.1/api/v1/namespaces/default/services/nginx', 'entity_of', 'i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REKAW44WKNW8CC1A80V0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en://https://192.168.1.1/api/v1/namespaces/default/services/nginx', 'entity_of', 'i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REP7AB85EW3554GWPR7H', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en:///apis/apps/v1/namespaces/kube-system/deployments/coredns', 'entity_of', 'i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('en:///apis/apps/v1/namespaces/default/deployments/nginx', 'entity_of', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDPT8G67DTE7VN8XX7CX', 'after', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'before', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDPT8G67DTE7VN8XX7CX', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDS7VP68NAQGK4CFW6VH', 'after', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDPT8G67DTE7VN8XX7CX', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDPT8G67DTE7VN8XX7CX', 'before', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDS7VP68NAQGK4CFW6VH', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://file:///dev/null?ulid=01EJP9QZ675722EJV4ZBWACX4M', 'after', 'i://file:///dev/null?ulid=01EJP9QYSRXHZM53RCXSFS0PMP', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://file:///dev/null?ulid=01EJP9QYSRXHZM53RCXSFS0PMP', 'before', 'i://file:///dev/null?ulid=01EJP9QZ675722EJV4ZBWACX4M', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RE2ZXX51FPC9WT303FQB', 'after', 'i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDTFQFNCK6GYB5DNJY0Z', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDTFQFNCK6GYB5DNJY0Z', 'before', 'i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RE2ZXX51FPC9WT303FQB', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REHF3W1074H5NWN2MF90', 'after', 'i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REFBRQDS6A0JNZF73E80', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REFBRQDS6A0JNZF73E80', 'before', 'i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REHF3W1074H5NWN2MF90', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REP7AB85EW3554GWPR7H', 'after', 'i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REKAW44WKNW8CC1A80V0', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REKAW44WKNW8CC1A80V0', 'before', 'i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REP7AB85EW3554GWPR7H', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVHA6DK0V7GN9WH4HFGD', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVM1VE5XY8YYDJR4DVC1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAJT3N1HE1JRX5BDM0C9', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE52E78V6KNHEZGEWXWB', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RR4TH46SB049QZ2ES0EQ', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RTNH8ERENR0A5JR7W7FJ', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVQ4HGWHP60XA2J5CSNZ', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RR0SB8V90BRMKW65F7D9', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RV4813SGSYFYRYV49J0X', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXMPV6SKF7EDMRV4E5J1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXYFQKCGXANTJXHM6S6Y', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RX9EXDE6QB3NK1MMCKFC', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVHA6DK0V7GN9WH4HFGD', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVM1VE5XY8YYDJR4DVC1', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RAJT3N1HE1JRX5BDM0C9', 'reads', 'i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE52E78V6KNHEZGEWXWB', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RR4TH46SB049QZ2ES0EQ', 'reads', 'i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RTNH8ERENR0A5JR7W7FJ', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVQ4HGWHP60XA2J5CSNZ', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RR0SB8V90BRMKW65F7D9', 'reads', 'i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RV4813SGSYFYRYV49J0X', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXMPV6SKF7EDMRV4E5J1', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RXYFQKCGXANTJXHM6S6Y', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RX9EXDE6QB3NK1MMCKFC', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS', 'child_of', 'ex://kube-DeploymentController-Run-01EJP9R4ETBCWRTMARMD3SRW6M', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV', 'child_of', 'ex://kube-DeploymentController-Run-01EJP9R4ETBCWRTMARMD3SRW6M', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RR0SB8V90BRMKW65F7D9', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY0NMZ9J8C72FES14C7Y', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RDSXB6Z116C8JAEG6CRF', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RV4813SGSYFYRYV49J0X', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVQ4HGWHP60XA2J5CSNZ', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RV7AQX4HN3MYH19P8P5V', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVM1VE5XY8YYDJR4DVC1', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RX9EXDE6QB3NK1MMCKFC', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RX737YVMRJNW04W8MM0Q', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-Run-01EJP9R4ETBCWRTMARMD3SRW6M', 'parent_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-Run-01EJP9R4ETBCWRTMARMD3SRW6M', 'parent_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RR0SB8V90BRMKW65F7D9', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY0NMZ9J8C72FES14C7Y', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RDSXB6Z116C8JAEG6CRF', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RV4813SGSYFYRYV49J0X', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVQ4HGWHP60XA2J5CSNZ', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RV7AQX4HN3MYH19P8P5V', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RVM1VE5XY8YYDJR4DVC1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RX9EXDE6QB3NK1MMCKFC', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RX737YVMRJNW04W8MM0Q', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9FV2M20K553R4BE5CQ5', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RDSXB6Z116C8JAEG6CRF', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9FV2M20K553R4BE5CQ5', 'reads', 'i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RDSXB6Z116C8JAEG6CRF', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE98R4XKYN7NV8HP95D9', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY2FDEW8G382AJECQ03Z', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9FV2M20K553R4BE5CQ5', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9GH6AWYYQ725XW5A32M', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RDXFMFD27ERA78811GTE', 'child_of', 'ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE98R4XKYN7NV8HP95D9', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY2FDEW8G382AJECQ03Z', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q8JJ01VPENHSEEAGFV', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9FV2M20K553R4BE5CQ5', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9GH6AWYYQ725XW5A32M', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-01EJP9R6Q7E8JR50CQTPKDW2SS', 'parent_of', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RDXFMFD27ERA78811GTE', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9GH6AWYYQ725XW5A32M', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE98R4XKYN7NV8HP95D9', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY2FDEW8G382AJECQ03Z', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY0NMZ9J8C72FES14C7Y', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RV7AQX4HN3MYH19P8P5V', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RDXFMFD27ERA78811GTE', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', 'read_by', 'ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RX737YVMRJNW04W8MM0Q', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9R9GH6AWYYQ725XW5A32M', 'reads', 'i:///apis/apps/v1/namespaces/kube-system/deployments/coredns?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RE98R4XKYN7NV8HP95D9', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY2FDEW8G382AJECQ03Z', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RY0NMZ9J8C72FES14C7Y', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RV7AQX4HN3MYH19P8P5V', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RDXFMFD27ERA78811GTE', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ex://kube-DeploymentController-worker-processNextWorkItem-01EJP9RX737YVMRJNW04W8MM0Q', 'reads', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?gen=1', '{}') ON CONFLICT DO NOTHING;


--
-- Data for Name: incarnations; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.incarnations VALUES ('i://file:///nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json?ulid=01EJP9RCQ95JT85A4AJNP67V6C', '2020-09-20 18:22:25.998265+00', 'en://file:///nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json', NULL, NULL, 'file /nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDM2KBXHW0N01QMZSCTZ', '2020-09-20 18:22:26.006166+00', 'en://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx', 'ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', NULL, 'in-memory resource /apis/apps/v1/namespaces/default/deployments/nginx') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDPT8G67DTE7VN8XX7CX', '2020-09-20 18:22:26.069411+00', 'en:///apis/apps/v1/namespaces/default/deployments/nginx', NULL, NULL, 'resource deployments/nginx') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDS7VP68NAQGK4CFW6VH', '2020-09-20 18:22:26.077248+00', 'en:///apis/apps/v1/namespaces/default/deployments/nginx', 'ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD', NULL, 'resource deployments/nginx') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDMY6BEN4XZBX83ZX0AW', '2020-09-20 18:22:26.01446+00', 'en://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', 'ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', NULL, 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDTFQFNCK6GYB5DNJY0Z', '2020-09-20 18:22:26.140342+00', 'en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', NULL, NULL, 'resource configmaps/nginx-config') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RE2ZXX51FPC9WT303FQB', '2020-09-20 18:22:26.1511+00', 'en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', 'ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5', NULL, 'resource configmaps/nginx-config') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9RDN6VFPTHWG7P6NBGWFC', '2020-09-20 18:22:26.022998+00', 'en://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', 'ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', NULL, 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REFBRQDS6A0JNZF73E80', '2020-09-20 18:22:26.199053+00', 'en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', NULL, NULL, 'resource configmaps/nginx-static') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REHF3W1074H5NWN2MF90', '2020-09-20 18:22:26.210367+00', 'en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', 'ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D', NULL, 'resource configmaps/nginx-static') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9RDNKD3K51RJACSTS28PA', '2020-09-20 18:22:26.031025+00', 'en://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx', 'ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', NULL, 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/services/nginx') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REKAW44WKNW8CC1A80V0', '2020-09-20 18:22:26.241941+00', 'en://https://192.168.1.1/api/v1/namespaces/default/services/nginx', NULL, NULL, 'resource services/nginx') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REP7AB85EW3554GWPR7H', '2020-09-20 18:22:26.252048+00', 'en://https://192.168.1.1/api/v1/namespaces/default/services/nginx', 'ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY', NULL, 'resource services/nginx') ON CONFLICT DO NOTHING;


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

INSERT INTO public.operations VALUES ('01EJP9RCQA6DWGRG1Y8AGBH0YG', '2020-09-20 18:22:25.998265+00', '2020-09-20 17:42:31.914776+00', 'ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', 'r', 'en://file:///nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json', 'i://file:///nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json?ulid=01EJP9RCQ95JT85A4AJNP67V6C', 'file /nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json', 'file /nix/store/va46ws49g08xvyf82fvpzfw7p7bzgjm3-kubenix-generated.json') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJP9RDM2KBXHW0N01SSHG1HF', '2020-09-20 18:22:26.006166+00', '2020-09-20 17:42:32.834325+00', 'ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', 'w', 'en://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx', 'i://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDM2KBXHW0N01QMZSCTZ', 'in-memory resource /apis/apps/v1/namespaces/default/deployments/nginx', 'in-memory resource /apis/apps/v1/namespaces/default/deployments/nginx') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJP9RDMZJ36D52F9A6HD4ZT9', '2020-09-20 18:22:26.01446+00', '2020-09-20 17:42:32.863331+00', 'ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', 'w', 'en://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', 'i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDMY6BEN4XZBX83ZX0AW', 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJP9RDN6VFPTHWG7P8M8SYPZ', '2020-09-20 18:22:26.022998+00', '2020-09-20 17:42:32.870725+00', 'ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', 'w', 'en://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', 'i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9RDN6VFPTHWG7P6NBGWFC', 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJP9RDNKD3K51RJACXGKNRTC', '2020-09-20 18:22:26.031025+00', '2020-09-20 17:42:32.883722+00', 'ex://kubectl-apply-builder-01EJP9RCQ1Y5Q05S9BEP0N17D2', 'w', 'en://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx', 'i://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9RDNKD3K51RJACSTS28PA', 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/services/nginx', 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/services/nginx') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJP9RDPHNN79VTM51BQ0VJKC', '2020-09-20 18:22:26.060944+00', '2020-09-20 17:42:32.914027+00', 'ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD', 'r', 'en://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx', 'i://in-memory-/apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDM2KBXHW0N01QMZSCTZ', 'in-memory resource /apis/apps/v1/namespaces/default/deployments/nginx', 'in-memory resource /apis/apps/v1/namespaces/default/deployments/nginx') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJP9RDQH4F7F7A2XY2X20RAM', '2020-09-20 18:22:26.069411+00', '2020-09-20 17:42:32.945592+00', 'ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD', 'r', 'en:///apis/apps/v1/namespaces/default/deployments/nginx', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDPT8G67DTE7VN8XX7CX', 'resource deployments/nginx', 'resource deployments/nginx') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJP9RDS7VP68NAQGK64GAF3V', '2020-09-20 18:22:26.077248+00', '2020-09-20 17:42:32.999923+00', 'ex://kubectl-apply-one-01EJP9RDP6M59FTSSRFK74JKSD', 'w', 'en:///apis/apps/v1/namespaces/default/deployments/nginx', 'i:///apis/apps/v1/namespaces/default/deployments/nginx?ulid=01EJP9RDS7VP68NAQGK4CFW6VH', 'resource deployments/nginx', 'resource deployments/nginx') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJP9RDT80Y58Z4XDNTR4QJT4', '2020-09-20 18:22:26.127255+00', '2020-09-20 17:42:33.032346+00', 'ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5', 'r', 'en://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', 'i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDMY6BEN4XZBX83ZX0AW', 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJP9RE1CA0R0G4WJD124NCTF', '2020-09-20 18:22:26.140342+00', '2020-09-20 17:42:33.261046+00', 'ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5', 'r', 'en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', 'i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RDTFQFNCK6GYB5DNJY0Z', 'resource configmaps/nginx-config', 'resource configmaps/nginx-config') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJP9RE2ZXX51FPC9WTSBRG3X', '2020-09-20 18:22:26.1511+00', '2020-09-20 17:42:33.311615+00', 'ex://kubectl-apply-one-01EJP9RDSYQ8BXNDKD34BPEVV5', 'w', 'en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config', 'i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-config?ulid=01EJP9RE2ZXX51FPC9WT303FQB', 'resource configmaps/nginx-config', 'resource configmaps/nginx-config') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJP9REF04W5E4XT5TJS5BA5E', '2020-09-20 18:22:26.186892+00', '2020-09-20 17:42:33.696995+00', 'ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D', 'r', 'en://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', 'i://in-memory-https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9RDN6VFPTHWG7P6NBGWFC', 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJP9REG548NMNRFSX21STP97', '2020-09-20 18:22:26.199053+00', '2020-09-20 17:42:33.733897+00', 'ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D', 'r', 'en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', 'i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REFBRQDS6A0JNZF73E80', 'resource configmaps/nginx-static', 'resource configmaps/nginx-static') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJP9REHGBRTSZJXT07Z40CEA', '2020-09-20 18:22:26.210367+00', '2020-09-20 17:42:33.777262+00', 'ex://kubectl-apply-one-01EJP9REENA5M3JB3ECSTCDZ3D', 'w', 'en://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static', 'i://https://192.168.1.1/api/v1/namespaces/default/configmaps/nginx-static?ulid=01EJP9REHF3W1074H5NWN2MF90', 'resource configmaps/nginx-static', 'resource configmaps/nginx-static') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJP9REK0XP9YGKR00S67N37T', '2020-09-20 18:22:26.230771+00', '2020-09-20 17:42:33.824707+00', 'ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY', 'r', 'en://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx', 'i://in-memory-https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9RDNKD3K51RJACSTS28PA', 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/services/nginx', 'in-memory resource https://192.168.1.1/api/v1/namespaces/default/services/nginx') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJP9REM99TFN48STSYR8GHBV', '2020-09-20 18:22:26.241941+00', '2020-09-20 17:42:33.865914+00', 'ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY', 'r', 'en://https://192.168.1.1/api/v1/namespaces/default/services/nginx', 'i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REKAW44WKNW8CC1A80V0', 'resource services/nginx', 'resource services/nginx') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJP9REP7AB85EW3557CR70BW', '2020-09-20 18:22:26.252048+00', '2020-09-20 17:42:33.927654+00', 'ex://kubectl-apply-one-01EJP9REJJBGX9ZERMGAEVWEAY', 'w', 'en://https://192.168.1.1/api/v1/namespaces/default/services/nginx', 'i://https://192.168.1.1/api/v1/namespaces/default/services/nginx?ulid=01EJP9REP7AB85EW3554GWPR7H', 'resource services/nginx', 'resource services/nginx') ON CONFLICT DO NOTHING;


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
-- Name: incarnations incarnations_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.incarnations
    ADD CONSTRAINT incarnations_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.incarnations(incarnation_id);


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

