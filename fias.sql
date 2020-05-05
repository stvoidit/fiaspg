--
-- PostgreSQL database dump
--

-- Dumped from database version 12.2
-- Dumped by pg_dump version 12.2 (Ubuntu 12.2-2.pgdg18.04+1)

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
-- Name: btree_gin; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;


--
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: search_address(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.search_address(adr text) RETURNS TABLE(aoid uuid, address character varying, cadnum character varying, similarity real)
    LANGUAGE sql
    AS $$
	SELECT 
    f.houseid ,
    f.address ,
    f.cadnum ,
    f.address <<<-> adr AS similarity
    FROM fulladdress f 
    WHERE address IS NOT NULL
    AND lower(address) ILIKE '%' ||  regexp_replace(adr, '[\s,\.\-_*+/\n\r]', '%', 'g')  || '%'
    ORDER BY similarity asc

$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.addresses (
    aoid uuid NOT NULL,
    aoguid uuid NOT NULL,
    parentguid uuid NOT NULL,
    nextid uuid NOT NULL,
    previd uuid NOT NULL,
    formalname character varying(120),
    offname character varying(120),
    shortname character varying(10),
    aolevel integer NOT NULL,
    regioncode integer,
    areacode integer,
    autocode integer,
    citycode integer,
    ctarcode integer,
    placecode integer,
    streetcode integer,
    extracode integer,
    sextcode integer,
    plaincode character varying(15),
    code character varying(17),
    curstatus integer,
    actstatus boolean NOT NULL,
    livestatus boolean NOT NULL,
    centstatus integer,
    operstatus integer,
    okato character varying(11),
    oktmo character varying(11),
    postalcode character varying(6),
    divtype smallint,
    plancode integer
);


--
-- Name: houses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.houses (
    houseid uuid NOT NULL,
    houseguid uuid NOT NULL,
    aoguid uuid NOT NULL,
    structnum character varying(10),
    buildnum character varying(10),
    housenum character varying(20),
    strstatus integer NOT NULL,
    eststatus integer NOT NULL,
    statstatus integer NOT NULL,
    okato character varying(11),
    oktmo character varying(11),
    postalcode integer NOT NULL,
    divtype smallint NOT NULL,
    regioncode integer NOT NULL,
    cadnum character varying(100)
);


--
-- Name: fulladdress; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.fulladdress AS
 WITH citys AS (
         SELECT a2.aoid,
            a2.aoguid,
            a2.parentguid,
            a2.nextid,
            a2.previd,
            a2.formalname,
            a2.offname,
            a2.shortname,
            a2.aolevel,
            a2.regioncode,
            a2.areacode,
            a2.autocode,
            a2.citycode,
            a2.ctarcode,
            a2.placecode,
            a2.streetcode,
            a2.extracode,
            a2.sextcode,
            a2.plaincode,
            a2.code,
            a2.curstatus,
            a2.actstatus,
            a2.livestatus,
            a2.centstatus,
            a2.operstatus,
            a2.okato,
            a2.oktmo,
            a2.postalcode,
            a2.divtype,
            a2.plancode
           FROM public.addresses a2
          WHERE (a2.aolevel <= 6)
        )
 SELECT ((((((((((((h.postalcode || ', '::text) || (c.shortname)::text) || ' '::text) || (c.formalname)::text) || ', '::text) || (a.shortname)::text) || ' '::text) || (a.formalname)::text) || ', '::text) || (h.housenum)::text) ||
        CASE
            WHEN ((h.structnum)::text <> ''::text) THEN ('c'::text || (h.structnum)::text)
            ELSE ''::text
        END) ||
        CASE
            WHEN ((h.buildnum)::text <> ''::text) THEN ('к'::text || (h.buildnum)::text)
            ELSE ''::text
        END) AS address,
    h.houseid,
    h.cadnum
   FROM ((public.addresses a
     LEFT JOIN citys c ON ((c.aoguid = a.parentguid)))
     JOIN public.houses h ON ((h.aoguid = a.aoguid)))
  WHERE (a.aolevel >= 7)
  WITH NO DATA;


--
-- Name: addresses_aoguid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX addresses_aoguid_idx ON public.addresses USING btree (aoguid);


--
-- Name: addresses_aoid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX addresses_aoid_idx ON public.addresses USING btree (aoid);


--
-- Name: addresses_aolevel_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX addresses_aolevel_idx ON public.addresses USING btree (aolevel);


--
-- Name: addresses_formalname_idx_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX addresses_formalname_idx_gin ON public.addresses USING gin (formalname);


--
-- Name: addresses_regioncode_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX addresses_regioncode_idx ON public.addresses USING btree (regioncode);


--
-- Name: fulladdress_address_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fulladdress_address_idx ON public.fulladdress USING gin (address);


--
-- Name: fulladdress_address_idx_btree; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fulladdress_address_idx_btree ON public.fulladdress USING btree (address);


--
-- Name: houses_aoguid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX houses_aoguid_idx ON public.houses USING btree (aoguid);


--
-- Name: houses_houseid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX houses_houseid_idx ON public.houses USING btree (houseid);


--
-- Name: houses_regioncode_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX houses_regioncode_idx ON public.houses USING btree (regioncode);


--
-- PostgreSQL database dump complete
--

