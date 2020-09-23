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
  -- union all
  -- select incarnation_id, 'part_of', parent_id from incarnations where parent_id is not null
  -- union all
  -- select parent_id, 'divides_into', incarnation_id from incarnations where entity_id is not null
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

INSERT INTO public.entities VALUES ('docker-image-app', '2020-09-18 22:07:39.203469+00', 'docker image app') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('registry-docker-image-app', '2020-09-18 22:11:39.759327+00', 'docker image app @ registry') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('remote-docker-image-app', '2020-09-18 22:15:58.505193+00', 'docker image app @ remote') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('remote-app', '2020-09-18 22:20:14.117394+00', 'app @ remote') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('config', '2020-09-18 22:22:55.801518+00', 'config') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('remote-config', '2020-09-18 22:23:52.82767+00', 'config @ remote') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('cwd', '2020-09-18 22:41:33.658486+00', 'app sources') ON CONFLICT DO NOTHING;


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.events VALUES ('srdr2                     ', 'p', 1, '2020-09-18 22:37:25.909541+00', '2020-09-18 22:37:25.915537+00', '2020-09-18 22:37:25.909541+00', 'EventOperation', '{"type": "w", "entity_id": "remote-app", "timestamp": "2020-09-19 00:37:42.65589+00", "event_ulid": "srdr2", "execution_id": "ssh-remote-docker-run-1", "operation_id": "srdr2", "incarnation_id": "remote-app-2", "entity_description": "app @ remote", "incarnation_description": "updated app @ remote"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('bac1                      ', 'p', 1, '2020-09-18 22:41:33.64968+00', '2020-09-18 22:41:33.658486+00', '2020-09-18 22:41:33.64968+00', 'EventOperation', '{"type": "r", "entity_id": "cwd", "timestamp": "2020-09-19 00:21:42.65589+00", "event_ulid": "bac1", "execution_id": "docker-build-app-1", "operation_id": "bac1", "incarnation_id": "cwd-1", "entity_description": "app sources", "incarnation_description": "app sources 1"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('rac11                     ', 'p', 1, '2020-09-18 22:52:11.812958+00', '2020-09-18 22:52:11.822003+00', '2020-09-18 22:52:11.812958+00', 'EventOperation', '{"type": "r", "entity_id": "remote-app", "timestamp": "2020-09-19 00:52:42.65589+00", "event_ulid": "rac11", "execution_id": "remote-app-container", "operation_id": "rac11", "incarnation_id": "remote-app-2", "entity_description": "", "incarnation_description": ""}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('rac112                    ', 'p', 1, '2020-09-18 22:52:54.886083+00', '2020-09-18 22:52:54.894152+00', '2020-09-18 22:52:54.886083+00', 'EventOperation', '{"type": "r", "entity_id": "remote-config", "timestamp": "2020-09-19 00:52:42.65589+00", "event_ulid": "rac112", "execution_id": "remote-app-container", "operation_id": "rac112", "incarnation_id": "remote-config-1", "entity_description": "", "incarnation_description": ""}') ON CONFLICT DO NOTHING;


--
-- Data for Name: executions; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.executions VALUES ('deploy-script.sh-run-1', '2020-09-18 22:06:47.444648+00', '2020-09-18 22:06:47.444648+00', NULL, NULL, NULL, 'run deployment script', '2020-09-18 23:06:47.444648+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('docker-build-app-1', '2020-09-18 22:06:53.878845+00', '2020-09-18 22:06:53.878845+00', 'deploy-script.sh-run-1', NULL, NULL, 'build app container', '2020-09-18 22:07:53.878845+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('docker-push-app-1', '2020-09-18 22:08:30.680709+00', '2020-09-18 22:08:30.680709+00', 'deploy-script.sh-run-1', NULL, NULL, 'docker push app:1', '2020-09-18 22:09:30.680709+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('ssh-remote-1', '2020-09-18 22:12:35.408228+00', '2020-09-18 22:12:35.408228+00', 'deploy-script.sh-run-1', NULL, NULL, 'ssh remote -- docker pull', '2020-09-18 22:13:35.408228+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('ssh-remote-docker-pull-1', '2020-09-18 22:13:25.775045+00', '2020-09-18 22:13:25.775045+00', 'ssh-remote-1', NULL, NULL, 'docker pull', '2020-09-18 22:14:25.775045+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('scp1', '2020-09-18 22:21:22.157+00', '2020-09-18 22:21:22.157+00', 'deploy-script.sh-run-1', NULL, NULL, 'scp config', '2020-09-18 22:22:22.157+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('remote-docker-daemon', '2020-09-18 22:25:17.867301+00', '2020-09-18 22:25:17.867301+00', NULL, NULL, NULL, 'remote docker daemon', '2020-09-19 13:25:17.867301+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('ssh-remote-2', '2020-09-18 22:34:05.163658+00', '2020-09-18 22:34:05.163658+00', 'deploy-script.sh-run-1', NULL, NULL, 'ssh remote -- docker stop', '2020-09-18 22:35:05.163658+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('ssh-remote-docker-stop-1', '2020-09-18 22:18:24.688023+00', '2020-09-18 22:18:24.688023+00', 'ssh-remote-2', NULL, NULL, 'docker stop -n app', '2020-09-18 22:19:24.688023+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('remote-app-container', '2020-09-18 22:45:32.827288+00', '2020-09-18 22:45:32.827288+00', 'ssh-remote-docker-run-1', 'remote-docker-daemon', NULL, 'app container @ remote', '2020-09-19 03:45:32.827288+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('ssh-remote-3', '2020-09-18 22:46:54.159241+00', '2020-09-18 22:46:54.159241+00', 'deploy-script.sh-run-1', NULL, NULL, 'ssh remote -- docker run', '2020-09-18 22:47:54.159241+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('ssh-remote-docker-run-1', '2020-09-18 22:26:59.803797+00', '2020-09-18 22:26:59.803797+00', 'ssh-remote-3', NULL, NULL, 'docker run -n app', '2020-09-18 22:27:59.803797+00') ON CONFLICT DO NOTHING;


--
-- Data for Name: graph; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.graph VALUES ('remote-app-2', 'after', 'remote-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-app-1', 'before', 'remote-app-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('docker-image-app-1', 'read_by', 'docker-push-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('registry-docker-image-app-1', 'read_by', 'ssh-remote-docker-pull-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('config-1', 'read_by', 'scp1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-app-1', 'read_by', 'ssh-remote-docker-run-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-docker-image-app-1', 'read_by', 'ssh-remote-docker-run-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('cwd-1', 'read_by', 'docker-build-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-app-2', 'read_by', 'remote-app-container', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-config-1', 'read_by', 'remote-app-container', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('docker-push-app-1', 'reads', 'docker-image-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ssh-remote-docker-pull-1', 'reads', 'registry-docker-image-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('scp1', 'reads', 'config-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ssh-remote-docker-run-1', 'reads', 'remote-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ssh-remote-docker-run-1', 'reads', 'remote-docker-image-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('docker-build-app-1', 'reads', 'cwd-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-app-container', 'reads', 'remote-app-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-app-container', 'reads', 'remote-config-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('docker-build-app-1', 'writes', 'docker-image-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('docker-push-app-1', 'writes', 'registry-docker-image-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ssh-remote-docker-pull-1', 'writes', 'remote-docker-image-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ssh-remote-docker-stop-1', 'writes', 'remote-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('scp1', 'writes', 'remote-config-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ssh-remote-docker-run-1', 'writes', 'remote-app-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('docker-image-app-1', 'written_by', 'docker-build-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('registry-docker-image-app-1', 'written_by', 'docker-push-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-docker-image-app-1', 'written_by', 'ssh-remote-docker-pull-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-app-1', 'written_by', 'ssh-remote-docker-stop-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-config-1', 'written_by', 'scp1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-app-2', 'written_by', 'ssh-remote-docker-run-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('docker-build-app-1', 'child_of', 'deploy-script.sh-run-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('docker-push-app-1', 'child_of', 'deploy-script.sh-run-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ssh-remote-1', 'child_of', 'deploy-script.sh-run-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ssh-remote-docker-pull-1', 'child_of', 'ssh-remote-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('scp1', 'child_of', 'deploy-script.sh-run-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ssh-remote-2', 'child_of', 'deploy-script.sh-run-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ssh-remote-docker-stop-1', 'child_of', 'ssh-remote-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-app-container', 'child_of', 'ssh-remote-docker-run-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ssh-remote-3', 'child_of', 'deploy-script.sh-run-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ssh-remote-docker-run-1', 'child_of', 'ssh-remote-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deploy-script.sh-run-1', 'parent_of', 'docker-build-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deploy-script.sh-run-1', 'parent_of', 'docker-push-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deploy-script.sh-run-1', 'parent_of', 'ssh-remote-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ssh-remote-1', 'parent_of', 'ssh-remote-docker-pull-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deploy-script.sh-run-1', 'parent_of', 'scp1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deploy-script.sh-run-1', 'parent_of', 'ssh-remote-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ssh-remote-2', 'parent_of', 'ssh-remote-docker-stop-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ssh-remote-docker-run-1', 'parent_of', 'remote-app-container', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('deploy-script.sh-run-1', 'parent_of', 'ssh-remote-3', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('ssh-remote-3', 'parent_of', 'ssh-remote-docker-run-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-app-container', 'created_by', 'remote-docker-daemon', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-docker-daemon', 'creator_of', 'remote-app-container', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('docker-image-app-1', 'instance_of', 'docker-image-app', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('registry-docker-image-app-1', 'instance_of', 'registry-docker-image-app', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('config-1', 'instance_of', 'config', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-app-1', 'instance_of', 'remote-app', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-docker-image-app-1', 'instance_of', 'remote-docker-image-app', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('cwd-1', 'instance_of', 'cwd', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-app-2', 'instance_of', 'remote-app', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-config-1', 'instance_of', 'remote-config', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('docker-image-app', 'entity_of', 'docker-image-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('registry-docker-image-app', 'entity_of', 'registry-docker-image-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('config', 'entity_of', 'config-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-app', 'entity_of', 'remote-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-docker-image-app', 'entity_of', 'remote-docker-image-app-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('cwd', 'entity_of', 'cwd-1', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-app', 'entity_of', 'remote-app-2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO public.graph VALUES ('remote-config', 'entity_of', 'remote-config-1', '{}') ON CONFLICT DO NOTHING;


--
-- Data for Name: incarnations; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.incarnations VALUES ('docker-image-app-1', '2020-09-18 22:07:39.203469+00', 'docker-image-app', 'docker-build-app-1', 'docker image app:1') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('registry-docker-image-app-1', '2020-09-18 22:11:39.759327+00', 'registry-docker-image-app', 'docker-push-app-1', 'docker image app:1 @ registry') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('config-1', '2020-09-18 22:22:55.801518+00', 'config', NULL, 'config 1') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('remote-app-1', '2020-09-18 22:20:14.117394+00', 'remote-app', 'ssh-remote-docker-stop-1', 'stopped app @ remote') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('remote-docker-image-app-1', '2020-09-18 22:15:58.505193+00', 'remote-docker-image-app', 'ssh-remote-docker-pull-1', 'docker image app:1 @ remote') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('cwd-1', '2020-09-18 22:41:33.658486+00', 'cwd', NULL, 'app sources 1') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('remote-app-2', '2020-09-18 22:37:25.915537+00', 'remote-app', 'ssh-remote-docker-run-1', 'updated app @ remote') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('remote-config-1', '2020-09-18 22:23:52.82767+00', 'remote-config', 'scp1', 'config 1 @ remote') ON CONFLICT DO NOTHING;


--
-- Data for Name: interactions; Type: TABLE DATA; Schema: public; Owner: tenmo
--



--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: tenmo
--



--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.migrations VALUES (7, '2020-09-18 23:53:16.09547+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (9, '2020-09-18 23:53:16.099057+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (10, '2020-09-18 23:53:16.102008+00') ON CONFLICT DO NOTHING;
INSERT INTO public.migrations VALUES (11, '2020-09-18 23:53:16.104124+00') ON CONFLICT DO NOTHING;


--
-- Data for Name: operations; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.operations VALUES ('123122435                 ', '2020-09-18 22:07:39.203469+00', '2020-09-19 00:06:42.65589+00', 'docker-build-app-1', 'w', 'docker-image-app', 'docker-image-app-1', 'docker image app', 'docker image app:1') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('456245624356              ', '2020-09-18 22:10:26.129848+00', '2020-09-19 00:10:42.65589+00', 'docker-push-app-1', 'r', 'docker-image-app', 'docker-image-app-1', 'docker image app', 'docker image app:1') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('456245624356234           ', '2020-09-18 22:11:39.759327+00', '2020-09-19 00:11:42.65589+00', 'docker-push-app-1', 'w', 'registry-docker-image-app', 'registry-docker-image-app-1', 'docker image app @ registry', 'docker image app:1 @ registry') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('4562456243562341          ', '2020-09-18 22:14:12.468507+00', '2020-09-19 00:11:42.65589+00', 'ssh-remote-docker-pull-1', 'r', 'registry-docker-image-app', 'registry-docker-image-app-1', 'docker image app @ registry', 'docker image app:1 @ registry') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('45624562435623412         ', '2020-09-18 22:15:58.505193+00', '2020-09-19 00:15:42.65589+00', 'ssh-remote-docker-pull-1', 'w', 'remote-docker-image-app', 'remote-docker-image-app-1', 'docker image app @ remote', 'docker image app:1 @ remote') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('456245624356234123        ', '2020-09-18 22:20:14.117394+00', '2020-09-19 00:19:42.65589+00', 'ssh-remote-docker-stop-1', 'w', 'remote-app', 'remote-app-1', 'app @ remote', 'stopped app @ remote') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('scp1                      ', '2020-09-18 22:22:55.801518+00', '2020-09-19 00:21:42.65589+00', 'scp1', 'r', 'config', 'config-1', 'config', 'config 1') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('scp12                     ', '2020-09-18 22:23:52.82767+00', '2020-09-19 00:23:42.65589+00', 'scp1', 'w', 'remote-config', 'remote-config-1', 'config @ remote', 'config 1 @ remote') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('srdr1                     ', '2020-09-18 22:28:16.033191+00', '2020-09-19 00:27:42.65589+00', 'ssh-remote-docker-run-1', 'r', 'remote-app', 'remote-app-1', 'app @ remote', 'stopped app @ remote') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('srdr12                    ', '2020-09-18 22:31:17.864131+00', '2020-09-19 00:30:42.65589+00', 'ssh-remote-docker-run-1', 'r', 'remote-docker-image-app', 'remote-docker-image-app-1', '', '') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('srdr2                     ', '2020-09-18 22:37:25.915537+00', '2020-09-19 00:37:42.65589+00', 'ssh-remote-docker-run-1', 'w', 'remote-app', 'remote-app-2', 'app @ remote', 'updated app @ remote') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('bac1                      ', '2020-09-18 22:41:33.658486+00', '2020-09-19 00:21:42.65589+00', 'docker-build-app-1', 'r', 'cwd', 'cwd-1', 'app sources', 'app sources 1') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('rac11                     ', '2020-09-18 22:52:11.822003+00', '2020-09-19 00:52:42.65589+00', 'remote-app-container', 'r', 'remote-app', 'remote-app-2', '', '') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('rac112                    ', '2020-09-18 22:52:54.894152+00', '2020-09-19 00:52:42.65589+00', 'remote-app-container', 'r', 'remote-config', 'remote-config-1', '', '') ON CONFLICT DO NOTHING;


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

