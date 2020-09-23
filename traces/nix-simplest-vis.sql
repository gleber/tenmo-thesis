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
-- Data for Name: entities; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', '2020-09-16 15:50:37.809759+00', 'NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', '2020-09-16 15:50:37.891361+00', 'NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', '2020-09-16 15:50:37.898775+00', 'NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', '2020-09-16 15:50:37.918154+00', 'NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', '2020-09-16 15:50:37.926004+00', 'NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.entities VALUES ('e:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', '2020-09-16 15:50:37.941249+00', 'NSO /run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top') ON CONFLICT DO NOTHING;


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.events VALUES ('01EJBSRKQVD04M4FQG170E9496', 'p', 1, '2020-09-16 15:50:37.662769+00', '2020-09-16 15:50:37.743635+00', '2020-09-16 15:48:42.654606+00', 'EventExecutionEnds', '{"timestamp": "2020-09-16T15:48:42.654606", "event_ulid": "01EJBSRKQVD04M4FQG170E9496", "execution_id": "120740120625154"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKQS50JW39GJMF8JZGGC', 'p', 1, '2020-09-16 15:50:37.613038+00', '2020-09-16 15:50:37.631811+00', '2020-09-16 15:48:42.654273+00', 'EventExecutionBegins', '{"parent_id": null, "timestamp": "2020-09-16T15:48:42.654273", "creator_id": null, "event_ulid": "01EJBSRKQS50JW39GJMF8JZGGC", "process_id": null, "description": "_main", "execution_id": "120740120625152"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKQTP3J1W55FPDFZ0E2W', 'p', 1, '2020-09-16 15:50:37.620886+00', '2020-09-16 15:50:37.650752+00', '2020-09-16 15:48:42.65434+00', 'EventExecutionBegins', '{"parent_id": "120740120625152", "timestamp": "2020-09-16T15:48:42.654340", "creator_id": null, "event_ulid": "01EJBSRKQTP3J1W55FPDFZ0E2W", "process_id": null, "description": "evaluating file ''/home/gleber/code/nix/inst/share/nix/corepkgs/derivation.nix''", "execution_id": "120740120625153"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKQTDN36CMEHDXFHPB4A', 'p', 1, '2020-09-16 15:50:37.653873+00', '2020-09-16 15:50:37.720888+00', '2020-09-16 15:48:42.654552+00', 'EventExecutionEnds', '{"timestamp": "2020-09-16T15:48:42.654552", "event_ulid": "01EJBSRKQTDN36CMEHDXFHPB4A", "execution_id": "120740120625155"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKQTKT4N27SDZCK3Q7T7', 'p', 1, '2020-09-16 15:50:37.626392+00', '2020-09-16 15:50:37.667721+00', '2020-09-16 15:48:42.654393+00', 'EventExecutionEnds', '{"timestamp": "2020-09-16T15:48:42.654393", "event_ulid": "01EJBSRKQTKT4N27SDZCK3Q7T7", "execution_id": "120740120625153"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKQT06KHZX2D9KRASB4E', 'p', 1, '2020-09-16 15:50:37.635729+00', '2020-09-16 15:50:37.685742+00', '2020-09-16 15:48:42.654442+00', 'EventExecutionBegins', '{"parent_id": "120740120625152", "timestamp": "2020-09-16T15:48:42.654442", "creator_id": null, "event_ulid": "01EJBSRKQT06KHZX2D9KRASB4E", "process_id": null, "description": "_main.eval", "execution_id": "120740120625154"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKQTQVPEGCZM78MDE8F9', 'p', 1, '2020-09-16 15:50:37.645285+00', '2020-09-16 15:50:37.704277+00', '2020-09-16 15:48:42.654497+00', 'EventExecutionBegins', '{"parent_id": "120740120625154", "timestamp": "2020-09-16T15:48:42.654497", "creator_id": null, "event_ulid": "01EJBSRKQTQVPEGCZM78MDE8F9", "process_id": null, "description": "evaluating file ''/home/gleber/code/nix/tests/config.nix''", "execution_id": "120740120625155"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKQV89TWD93HJ0EAE0A7', 'p', 1, '2020-09-16 15:50:37.671796+00', '2020-09-16 15:50:37.758284+00', '2020-09-16 15:48:42.654662+00', 'EventExecutionBegins', '{"parent_id": "120740120625152", "timestamp": "2020-09-16T15:48:42.654662", "creator_id": null, "event_ulid": "01EJBSRKQV89TWD93HJ0EAE0A7", "process_id": null, "description": "preparing build of 1 derivations", "execution_id": "120740120625156"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKR1QKDWMF406K37RBWG', 'p', 2, '2020-09-16 15:50:37.716648+00', '2020-09-16 15:50:46.366774+00', '2020-09-16 15:48:42.655784+00', 'EventOperation', '{"type": "w", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv", "timestamp": "2020-09-16T15:48:42.655784", "event_ulid": "01EJBSRKR1QKDWMF406K37RBWG", "execution_id": "120740120625157", "operation_id": "120740120625157-01EJBSRKR1QKDWMF406K37RBWG", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKR2JV9F5MASB88THFD0', 'p', 1, '2020-09-16 15:50:37.731384+00', '2020-09-16 15:50:37.828999+00', '2020-09-16 15:48:42.655857+00', 'EventExecutionBegins', '{"parent_id": "120740120625156", "timestamp": "2020-09-16T15:48:42.655857", "creator_id": null, "event_ulid": "01EJBSRKR2JV9F5MASB88THFD0", "process_id": null, "description": "building 1 paths", "execution_id": "120740120625159"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKQVPCCM2RFKKNNYEH0S', 'p', 1, '2020-09-16 15:50:37.680635+00', '2020-09-16 15:50:37.780166+00', '2020-09-16 15:48:42.654716+00', 'EventExecutionBegins', '{"parent_id": "120740120625156", "timestamp": "2020-09-16T15:48:42.654716", "creator_id": null, "event_ulid": "01EJBSRKQVPCCM2RFKKNNYEH0S", "process_id": null, "description": "derivation ''dependencies-top'' being evaled", "execution_id": "120740120625157"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKQXG6P05T8TRV3K22EB', 'p', 1, '2020-09-16 15:50:37.689613+00', '2020-09-16 15:50:37.794534+00', '2020-09-16 15:48:42.655037+00', 'EventExecutionBegins', '{"parent_id": "120740120625157", "timestamp": "2020-09-16T15:48:42.655037", "creator_id": null, "event_ulid": "01EJBSRKQXG6P05T8TRV3K22EB", "process_id": null, "description": "derivation ''dependencies-input-0'' being evaled", "execution_id": "120740120625158"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKR0V30GR3VP8841XN88', 'p', 1, '2020-09-16 15:50:37.708033+00', '2020-09-16 15:50:37.823288+00', '2020-09-16 15:48:42.655563+00', 'EventExecutionEnds', '{"timestamp": "2020-09-16T15:48:42.655563", "event_ulid": "01EJBSRKR0V30GR3VP8841XN88", "execution_id": "120740120625158"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKR2NWK59YM46C5820W9', 'p', 1, '2020-09-16 15:50:37.739081+00', '2020-09-16 15:50:37.834701+00', '2020-09-16 15:48:42.65589+00', 'EventExecutionBegins', '{"parent_id": "120740120625159", "timestamp": "2020-09-16T15:48:42.655890", "creator_id": null, "event_ulid": "01EJBSRKR2NWK59YM46C5820W9", "process_id": null, "description": "querying info about missing paths", "execution_id": "120740120625160"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKR11FN456Y94QNDKZRG', 'p', 2, '2020-09-16 15:50:37.724212+00', '2020-09-16 15:50:46.379781+00', '2020-09-16 15:48:42.655815+00', 'EventExecutionEnds', '{"timestamp": "2020-09-16T15:48:42.655815", "event_ulid": "01EJBSRKR11FN456Y94QNDKZRG", "execution_id": "120740120625157"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKR34SM53917TD0A9MPM', 'p', 1, '2020-09-16 15:50:37.754041+00', '2020-09-16 15:50:37.846214+00', '2020-09-16 15:48:42.656079+00', 'EventExecutionBegins', '{"parent_id": "120740120625159", "timestamp": "2020-09-16T15:48:42.656079", "creator_id": null, "event_ulid": "01EJBSRKR34SM53917TD0A9MPM", "process_id": null, "description": "", "execution_id": "120740120625161"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKR2M3F6R3ESTDZE2TNB', 'p', 1, '2020-09-16 15:50:37.74649+00', '2020-09-16 15:50:37.840509+00', '2020-09-16 15:48:42.655956+00', 'EventExecutionEnds', '{"timestamp": "2020-09-16T15:48:42.655956", "event_ulid": "01EJBSRKR2M3F6R3ESTDZE2TNB", "execution_id": "120740120625160"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKR4YQN7KJDPR0D8W36Y', 'p', 1, '2020-09-16 15:50:37.761251+00', '2020-09-16 15:50:37.852296+00', '2020-09-16 15:48:42.656109+00', 'EventExecutionBegins', '{"parent_id": "120740120625159", "timestamp": "2020-09-16T15:48:42.656109", "creator_id": null, "event_ulid": "01EJBSRKR4YQN7KJDPR0D8W36Y", "process_id": null, "description": "", "execution_id": "120740120625162"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKR4KE82MSE9FEQ2VHQS', 'p', 1, '2020-09-16 15:50:37.768645+00', '2020-09-16 15:50:37.858816+00', '2020-09-16 15:48:42.65614+00', 'EventExecutionBegins', '{"parent_id": "120740120625159", "timestamp": "2020-09-16T15:48:42.656140", "creator_id": null, "event_ulid": "01EJBSRKR4KE82MSE9FEQ2VHQS", "process_id": null, "description": "", "execution_id": "120740120625163"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKQZDGTK1HAMW1J591DN', 'p', 1, '2020-09-16 15:50:37.698646+00', '2020-09-16 15:50:37.809759+00', '2020-09-16 15:48:42.655531+00', 'EventOperation', '{"type": "w", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv", "timestamp": "2020-09-16T15:48:42.655531", "event_ulid": "01EJBSRKQZDGTK1HAMW1J591DN", "execution_id": "120740120625158", "operation_id": "120740120625158-01EJBSRKQZDGTK1HAMW1J591DN", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKRQM1PYE43CRKZH6KE3', 'p', 1, '2020-09-16 15:50:37.790072+00', '2020-09-16 15:50:37.877189+00', '2020-09-16 15:48:42.663671+00', 'EventExecutionBegins', '{"parent_id": "120740120625159", "timestamp": "2020-09-16T15:48:42.663671", "creator_id": null, "event_ulid": "01EJBSRKRQM1PYE43CRKZH6KE3", "process_id": null, "description": "building ''/run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv''", "execution_id": "120740120625165"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKR4ES17NSVFAR3HSE7H', 'p', 1, '2020-09-16 15:50:37.775899+00', '2020-09-16 15:50:37.865225+00', '2020-09-16 15:48:42.65617+00', 'EventExecutionBegins', '{"parent_id": "120740120625159", "timestamp": "2020-09-16T15:48:42.656170", "creator_id": null, "event_ulid": "01EJBSRKR4ES17NSVFAR3HSE7H", "process_id": null, "description": "querying info about missing paths", "execution_id": "120740120625164"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKR5MW2Z33F5PG6H7N34', 'p', 1, '2020-09-16 15:50:37.782907+00', '2020-09-16 15:50:37.871548+00', '2020-09-16 15:48:42.656237+00', 'EventExecutionEnds', '{"timestamp": "2020-09-16T15:48:42.656237", "event_ulid": "01EJBSRKR5MW2Z33F5PG6H7N34", "execution_id": "120740120625164"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKRQKQ5N4XGAF0A37PPH', 'p', 1, '2020-09-16 15:50:37.797409+00', '2020-09-16 15:50:37.883947+00', '2020-09-16 15:48:42.663709+00', 'EventOperation', '{"type": "r", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv", "timestamp": "2020-09-16T15:48:42.663709", "event_ulid": "01EJBSRKRQKQ5N4XGAF0A37PPH", "execution_id": "120740120625165", "operation_id": "120740120625165-01EJBSRKRQKQ5N4XGAF0A37PPH", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKS200VJE0TJXZ72HYEP', 'p', 1, '2020-09-16 15:50:37.82399+00', '2020-09-16 15:50:37.91161+00', '2020-09-16 15:48:42.669498+00', 'EventExecutionBegins', '{"parent_id": "120740120625159", "timestamp": "2020-09-16T15:48:42.669498", "creator_id": null, "event_ulid": "01EJBSRKS200VJE0TJXZ72HYEP", "process_id": null, "description": "building ''/run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv''", "execution_id": "120740120625166"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKRRA1TDQTCD9S2PEANF', 'p', 1, '2020-09-16 15:50:37.80501+00', '2020-09-16 15:50:37.891361+00', '2020-09-16 15:48:42.663742+00', 'EventOperation', '{"type": "r", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh", "timestamp": "2020-09-16T15:48:42.663742", "event_ulid": "01EJBSRKRRA1TDQTCD9S2PEANF", "execution_id": "120740120625165", "operation_id": "120740120625165-01EJBSRKRRA1TDQTCD9S2PEANF", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKRT03J2H0A65TBQ0JKD', 'p', 1, '2020-09-16 15:50:37.812531+00', '2020-09-16 15:50:37.898775+00', '2020-09-16 15:48:42.666924+00', 'EventOperation', '{"type": "w", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0", "timestamp": "2020-09-16T15:48:42.666924", "event_ulid": "01EJBSRKRT03J2H0A65TBQ0JKD", "execution_id": "120740120625165", "operation_id": "120740120625165-01EJBSRKRT03J2H0A65TBQ0JKD", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKRWA2CV80QCJ0M8NC4G', 'p', 1, '2020-09-16 15:50:37.820044+00', '2020-09-16 15:50:37.90586+00', '2020-09-16 15:48:42.667406+00', 'EventExecutionEnds', '{"timestamp": "2020-09-16T15:48:42.667406", "event_ulid": "01EJBSRKRWA2CV80QCJ0M8NC4G", "execution_id": "120740120625165"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKS3DEMBMGDJWXRPR9NW', 'p', 1, '2020-09-16 15:50:37.826689+00', '2020-09-16 15:50:37.918154+00', '2020-09-16 15:48:42.669549+00', 'EventOperation', '{"type": "r", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv", "timestamp": "2020-09-16T15:48:42.669549", "event_ulid": "01EJBSRKS3DEMBMGDJWXRPR9NW", "execution_id": "120740120625166", "operation_id": "120740120625166-01EJBSRKS3DEMBMGDJWXRPR9NW", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKS3MKYF212HDDBBT2WF', 'p', 1, '2020-09-16 15:50:37.829589+00', '2020-09-16 15:50:37.926004+00', '2020-09-16 15:48:42.669598+00', 'EventOperation', '{"type": "r", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh", "timestamp": "2020-09-16T15:48:42.669598", "event_ulid": "01EJBSRKS3MKYF212HDDBBT2WF", "execution_id": "120740120625166", "operation_id": "120740120625166-01EJBSRKS3MKYF212HDDBBT2WF", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKS31Q6D7YW8R0THR0V4', 'p', 1, '2020-09-16 15:50:37.832472+00', '2020-09-16 15:50:37.933513+00', '2020-09-16 15:48:42.66965+00', 'EventOperation', '{"type": "r", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0", "timestamp": "2020-09-16T15:48:42.669650", "event_ulid": "01EJBSRKS31Q6D7YW8R0THR0V4", "execution_id": "120740120625166", "operation_id": "120740120625166-01EJBSRKS31Q6D7YW8R0THR0V4", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKS973GZ07VFE7S19E0K', 'p', 1, '2020-09-16 15:50:37.844127+00', '2020-09-16 15:50:37.961128+00', '2020-09-16 15:48:42.676953+00', 'EventExecutionEnds', '{"timestamp": "2020-09-16T15:48:42.676953", "event_ulid": "01EJBSRKS973GZ07VFE7S19E0K", "execution_id": "120740120625162"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKS7DF7731J1AZYGN9V9', 'p', 1, '2020-09-16 15:50:37.835246+00', '2020-09-16 15:50:37.941249+00', '2020-09-16 15:48:42.676486+00', 'EventOperation', '{"type": "w", "entity_id": "e:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top", "timestamp": "2020-09-16T15:48:42.676486", "event_ulid": "01EJBSRKS7DF7731J1AZYGN9V9", "execution_id": "120740120625166", "operation_id": "120740120625166-01EJBSRKS7DF7731J1AZYGN9V9", "incarnation_id": "i:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top", "entity_description": "NSO /run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top", "incarnation_description": "NSO /run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKS83RB7FZ3P94WNHJC8', 'p', 1, '2020-09-16 15:50:37.838562+00', '2020-09-16 15:50:37.948259+00', '2020-09-16 15:48:42.676858+00', 'EventExecutionEnds', '{"timestamp": "2020-09-16T15:48:42.676858", "event_ulid": "01EJBSRKS83RB7FZ3P94WNHJC8", "execution_id": "120740120625166"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKS9NMA62GJGKBSNAKB8', 'p', 1, '2020-09-16 15:50:37.846768+00', '2020-09-16 15:50:37.966267+00', '2020-09-16 15:48:42.676981+00', 'EventExecutionEnds', '{"timestamp": "2020-09-16T15:48:42.676981", "event_ulid": "01EJBSRKS9NMA62GJGKBSNAKB8", "execution_id": "120740120625161"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKS92ZJFZ5NRH0NZNM3G', 'p', 1, '2020-09-16 15:50:37.8412+00', '2020-09-16 15:50:37.955083+00', '2020-09-16 15:48:42.676923+00', 'EventExecutionEnds', '{"timestamp": "2020-09-16T15:48:42.676923", "event_ulid": "01EJBSRKS92ZJFZ5NRH0NZNM3G", "execution_id": "120740120625163"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKS9A3CAQC7N0E4RG2BP', 'p', 1, '2020-09-16 15:50:37.850014+00', '2020-09-16 15:50:37.971437+00', '2020-09-16 15:48:42.677011+00', 'EventExecutionEnds', '{"timestamp": "2020-09-16T15:48:42.677011", "event_ulid": "01EJBSRKS9A3CAQC7N0E4RG2BP", "execution_id": "120740120625159"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKS96GSA7MVX6B6PK1EH', 'p', 1, '2020-09-16 15:50:37.852765+00', '2020-09-16 15:50:37.977286+00', '2020-09-16 15:48:42.677071+00', 'EventExecutionEnds', '{"timestamp": "2020-09-16T15:48:42.677071", "event_ulid": "01EJBSRKS96GSA7MVX6B6PK1EH", "execution_id": "120740120625156"}') ON CONFLICT DO NOTHING;
INSERT INTO public.events VALUES ('01EJBSRKSANGJ64YRWMJ8STMPA', 'p', 1, '2020-09-16 15:50:37.856283+00', '2020-09-16 15:50:37.987944+00', '2020-09-16 15:48:42.677103+00', 'EventExecutionEnds', '{"timestamp": "2020-09-16T15:48:42.677103", "event_ulid": "01EJBSRKSANGJ64YRWMJ8STMPA", "execution_id": "120740120625152"}') ON CONFLICT DO NOTHING;


--
-- Data for Name: executions; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.executions VALUES ('120740120625153', '2020-09-16 15:50:37.650752+00', '2020-09-16 15:48:42.65434+00', '120740120625152', NULL, NULL, 'evaluating file ''/home/gleber/code/nix/inst/share/nix/corepkgs/derivation.nix''', '2020-09-16 15:48:42.654393+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('120740120625155', '2020-09-16 15:50:37.704277+00', '2020-09-16 15:48:42.654497+00', '120740120625154', NULL, NULL, 'evaluating file ''/home/gleber/code/nix/tests/config.nix''', '2020-09-16 15:48:42.654552+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('120740120625154', '2020-09-16 15:50:37.685742+00', '2020-09-16 15:48:42.654442+00', '120740120625152', NULL, NULL, '_main.eval', '2020-09-16 15:48:42.654606+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('120740120625158', '2020-09-16 15:50:37.794534+00', '2020-09-16 15:48:42.655037+00', '120740120625157', NULL, NULL, 'derivation ''dependencies-input-0'' being evaled', '2020-09-16 15:48:42.655563+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('120740120625160', '2020-09-16 15:50:37.834701+00', '2020-09-16 15:48:42.65589+00', '120740120625159', NULL, NULL, 'querying info about missing paths', '2020-09-16 15:48:42.655956+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('120740120625164', '2020-09-16 15:50:37.865225+00', '2020-09-16 15:48:42.65617+00', '120740120625159', NULL, NULL, 'querying info about missing paths', '2020-09-16 15:48:42.656237+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('120740120625165', '2020-09-16 15:50:37.877189+00', '2020-09-16 15:48:42.663671+00', '120740120625159', NULL, NULL, 'building ''/run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv''', '2020-09-16 15:48:42.667406+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('120740120625166', '2020-09-16 15:50:37.91161+00', '2020-09-16 15:48:42.669498+00', '120740120625159', NULL, NULL, 'building ''/run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv''', '2020-09-16 15:48:42.676858+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('120740120625163', '2020-09-16 15:50:37.858816+00', '2020-09-16 15:48:42.65614+00', '120740120625159', NULL, NULL, '', '2020-09-16 15:48:42.676923+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('120740120625162', '2020-09-16 15:50:37.852296+00', '2020-09-16 15:48:42.656109+00', '120740120625159', NULL, NULL, '', '2020-09-16 15:48:42.676953+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('120740120625161', '2020-09-16 15:50:37.846214+00', '2020-09-16 15:48:42.656079+00', '120740120625159', NULL, NULL, '', '2020-09-16 15:48:42.676981+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('120740120625159', '2020-09-16 15:50:37.828999+00', '2020-09-16 15:48:42.655857+00', '120740120625156', NULL, NULL, 'building 1 paths', '2020-09-16 15:48:42.677011+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('120740120625156', '2020-09-16 15:50:37.758284+00', '2020-09-16 15:48:42.654662+00', '120740120625152', NULL, NULL, 'preparing build of 1 derivations', '2020-09-16 15:48:42.677071+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('120740120625152', '2020-09-16 15:50:37.631811+00', '2020-09-16 15:48:42.654273+00', NULL, NULL, NULL, '_main', '2020-09-16 15:48:42.677103+00') ON CONFLICT DO NOTHING;
INSERT INTO public.executions VALUES ('120740120625157', '2020-09-16 15:50:37.780166+00', '2020-09-16 15:48:42.654716+00', '120740120625156', NULL, NULL, 'derivation ''dependencies-top'' being evaled', '2020-09-16 15:48:42.655815+00') ON CONFLICT DO NOTHING;


--
-- Data for Name: incarnations; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', '2020-09-16 15:50:37.809759+00', 'e:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', '120740120625158', 'NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', '2020-09-16 15:50:37.891361+00', 'e:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', NULL, 'NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', '2020-09-16 15:50:37.926004+00', 'e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', NULL, 'NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', '2020-09-16 15:50:37.898775+00', 'e:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', '120740120625165', 'NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', '2020-09-16 15:50:37.941249+00', 'e:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', '120740120625166', 'NSO /run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top') ON CONFLICT DO NOTHING;
INSERT INTO public.incarnations VALUES ('i:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', '2020-09-16 15:50:37.918154+00', 'e:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', '120740120625157', 'NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv') ON CONFLICT DO NOTHING;


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: tenmo
--



--
-- Data for Name: operations; Type: TABLE DATA; Schema: public; Owner: tenmo
--

INSERT INTO public.operations VALUES ('01EJBSRKQZDGTK1HAMW1J591DN', '2020-09-16 15:50:37.809759+00', '2020-09-16 15:48:42.655531+00', '120740120625158', 'w', 'e:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', 'i:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', 'NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', 'NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJBSRKRQKQ5N4XGAF0A37PPH', '2020-09-16 15:50:37.883947+00', '2020-09-16 15:48:42.663709+00', '120740120625165', 'r', 'e:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', 'i:///run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', 'NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv', 'NSO /run/user/1000/nix-test/logging-json/store/40zj9p2w3lkxkpfr3g938vapxp3fmiac-dependencies-input-0.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJBSRKRRA1TDQTCD9S2PEANF', '2020-09-16 15:50:37.891361+00', '2020-09-16 15:48:42.663742+00', '120740120625165', 'r', 'e:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', 'i:///run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', 'NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh', 'NSO /run/user/1000/nix-test/logging-json/store/a2k781ggfk1syl2an5y2gx2l8a2yy715-builder-dependencies-input-0.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJBSRKRT03J2H0A65TBQ0JKD', '2020-09-16 15:50:37.898775+00', '2020-09-16 15:48:42.666924+00', '120740120625165', 'w', 'e:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', 'i:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', 'NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', 'NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJBSRKS3DEMBMGDJWXRPR9NW', '2020-09-16 15:50:37.918154+00', '2020-09-16 15:48:42.669549+00', '120740120625166', 'r', 'e:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', 'i:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', 'NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', 'NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJBSRKS3MKYF212HDDBBT2WF', '2020-09-16 15:50:37.926004+00', '2020-09-16 15:48:42.669598+00', '120740120625166', 'r', 'e:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'i:///run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh', 'NSO /run/user/1000/nix-test/logging-json/store/q6ngyanhbcyjr17yrlbbagagrj2clzxd-simple.deps.builder.sh') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJBSRKS31Q6D7YW8R0THR0V4', '2020-09-16 15:50:37.933513+00', '2020-09-16 15:48:42.66965+00', '120740120625166', 'r', 'e:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', 'i:///run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', 'NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0', 'NSO /run/user/1000/nix-test/logging-json/store/wfchbfd39qcy4j1q13fh4mjb0wkjjvdh-dependencies-input-0') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJBSRKS7DF7731J1AZYGN9V9', '2020-09-16 15:50:37.941249+00', '2020-09-16 15:48:42.676486+00', '120740120625166', 'w', 'e:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', 'i:///run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', 'NSO /run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top', 'NSO /run/user/1000/nix-test/logging-json/store/3hknjp8dvfryb4270bc4fyd1r9jshd9c-dependencies-top') ON CONFLICT DO NOTHING;
INSERT INTO public.operations VALUES ('01EJBSRKR1QKDWMF406K37RBWG', '2020-09-16 15:50:46.366774+00', '2020-09-16 15:48:42.655784+00', '120740120625157', 'w', 'e:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', 'i:///run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', 'NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv', 'NSO /run/user/1000/nix-test/logging-json/store/sh0p2kw8ylqzjijdi3cxpl70z857mhbq-dependencies-top.drv') ON CONFLICT DO NOTHING;


--
-- Data for Name: processes; Type: TABLE DATA; Schema: public; Owner: tenmo
--



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
-- Name: incarnations incarnations_pkey; Type: CONSTRAINT; Schema: public; Owner: tenmo
--

ALTER TABLE ONLY public.incarnations
    ADD CONSTRAINT incarnations_pkey PRIMARY KEY (incarnation_id);


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

