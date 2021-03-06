--
-- PostgreSQL database dump
--

-- Dumped from database version 12.2 (Ubuntu 12.2-2.pgdg18.04+1)
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
-- Name: search_by_lvl(text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.search_by_lvl(addr text, lvl integer) RETURNS text
    LANGUAGE sql
    AS $$ WITH result_string AS (
    SELECT
        concat_address AS part
        , (similarity(
            concat_address
            , addr
        ) + word_similarity(
            concat_address
            , addr
        ) + strict_word_similarity(
            concat_address
            , addr
        )) AS similarity
    FROM
        addresses a
    WHERE
        a.aolevel = lvl
    AND (
    concat_address  <% addr
    OR
    concat_address % addr 
    OR
    concat_address %> addr 
    )
)
SELECT
    part
FROM
    result_string rs
WHERE
    rs.similarity = (
        SELECT
            max(similarity)
        FROM
            result_string
    )
LIMIT 1

$$;


--
-- Name: search_guid(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.search_guid(addr text) RETURNS TABLE(houseid uuid, address text, avg_percent real)
    LANGUAGE sql
    AS $$
WITH primary_selection AS (
SELECT DISTINCT a.aoguid, a.parentguid, a.shortname, a.offname, a.aolevel  FROM addresses a 
INNER JOIN houses h ON h.aoguid = a.aoguid 
WHERE (addr %> concat_ws(' ',a.shortname , a.offname)) IS TRUE 
AND a.aolevel >= 6
), secondary_selection AS (
SELECT * FROM addresses a2 
WHERE a2.aoguid IN (SELECT parentguid FROM primary_selection)
AND (addr %> a2.offname) IS TRUE 

), houses_selection as (
    SELECT 
    concat_ws(' ',ss.shortname , ss.offname) AS city,
    concat_ws(' ',ps.shortname , ps.offname) AS street,
 h.houseid, trim(concat_ws(' ',
CASE WHEN h.housenum IS NOT NULL THEN concat_ws(' ', e.shortname, h.housenum) ELSE '' END,
CASE WHEN h.buildnum IS NOT NULL THEN concat('к ', h.buildnum ) ELSE '' END,
CASE WHEN h.structnum IS NOT NULL THEN concat('стр ', h.structnum) ELSE '' END
)) AS house
 FROM secondary_selection ss
INNER JOIN primary_selection ps ON ps.parentguid = ss.aoguid
INNER JOIN houses h ON h.aoguid = ps.aoguid 
INNER JOIN eststats e ON e.estatid = h.eststatus 
), founded AS (
SELECT
hs.houseid,
fa.address,
(word_similarity(fa.address , addr ) + similarity(fa.address , addr ) + strict_word_similarity(fa.address , addr)) / 3 AS avg_percent
FROM houses_selection hs
INNER JOIN fulladdresses fa ON fa.houseid = hs.houseid

)

SELECT 
DISTINCT ON (f.address)
f.houseid
,f.address
,f.avg_percent::float4
FROM founded AS f
WHERE f.avg_percent = (SELECT max(avg_percent) FROM founded)
LIMIT 1 --TODO: временный костыль

$$;


--
-- Name: search_guid_by_street(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.search_guid_by_street(addr text) RETURNS TABLE(houseid uuid, address text, avg_percent real)
    LANGUAGE sql
    AS $$
WITH primary_selection AS (
SELECT DISTINCT a.aoguid, a.parentguid, a.shortname, a.offname, a.aolevel  FROM addresses a 
INNER JOIN houses h ON h.aoguid = a.aoguid 
WHERE (addr %> concat_ws(' ',a.shortname , a.offname)) IS TRUE 
AND a.aolevel > 6
), houses_selection as (
    SELECT 
    concat_ws(' ',ps.shortname , ps.offname) AS street,
 h.houseid, trim(concat_ws(' ',
CASE WHEN h.housenum IS NOT NULL THEN concat_ws(' ', e.shortname, h.housenum) ELSE '' END,
CASE WHEN h.buildnum IS NOT NULL THEN concat('к ', h.buildnum ) ELSE '' END,
CASE WHEN h.structnum IS NOT NULL THEN concat('стр ', h.structnum) ELSE '' END
)) AS house
 FROM primary_selection ps
INNER JOIN houses h ON h.aoguid = ps.aoguid 
INNER JOIN eststats e ON e.estatid = h.eststatus 
), founded AS (
SELECT
hs.houseid,
fa.address,
(word_similarity(fa.address , addr ) + similarity(fa.address , addr ) + strict_word_similarity(fa.address , addr)) / 3 AS avg_percent
FROM houses_selection hs
INNER JOIN fulladdresses fa ON fa.houseid = hs.houseid

)

SELECT 
DISTINCT ON (f.address)
f.houseid
,f.address
,f.avg_percent::float4
FROM founded AS f
WHERE f.avg_percent = (SELECT max(avg_percent) FROM founded)
LIMIT 1 --TODO: временный костыль

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
    plancode integer,
    concat_address character varying(200)
);


--
-- Name: addresses_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.addresses_1 AS
 SELECT addresses.aoid,
    addresses.aoguid,
    addresses.parentguid,
    addresses.nextid,
    addresses.previd,
    addresses.formalname,
    addresses.offname,
    addresses.shortname,
    addresses.aolevel,
    addresses.regioncode,
    addresses.areacode,
    addresses.autocode,
    addresses.citycode,
    addresses.ctarcode,
    addresses.placecode,
    addresses.streetcode,
    addresses.extracode,
    addresses.sextcode,
    addresses.plaincode,
    addresses.code,
    addresses.curstatus,
    addresses.actstatus,
    addresses.livestatus,
    addresses.centstatus,
    addresses.operstatus,
    addresses.okato,
    addresses.oktmo,
    addresses.postalcode,
    addresses.divtype,
    addresses.plancode
   FROM public.addresses
  WHERE (addresses.aolevel = 1);


--
-- Name: addresses_3; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.addresses_3 AS
 SELECT addresses.aoid,
    addresses.aoguid,
    addresses.parentguid,
    addresses.nextid,
    addresses.previd,
    addresses.formalname,
    addresses.offname,
    addresses.shortname,
    addresses.aolevel,
    addresses.regioncode,
    addresses.areacode,
    addresses.autocode,
    addresses.citycode,
    addresses.ctarcode,
    addresses.placecode,
    addresses.streetcode,
    addresses.extracode,
    addresses.sextcode,
    addresses.plaincode,
    addresses.code,
    addresses.curstatus,
    addresses.actstatus,
    addresses.livestatus,
    addresses.centstatus,
    addresses.operstatus,
    addresses.okato,
    addresses.oktmo,
    addresses.postalcode,
    addresses.divtype,
    addresses.plancode
   FROM public.addresses
  WHERE (addresses.aolevel = 3);


--
-- Name: addresses_4; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.addresses_4 AS
 SELECT addresses.aoid,
    addresses.aoguid,
    addresses.parentguid,
    addresses.nextid,
    addresses.previd,
    addresses.formalname,
    addresses.offname,
    addresses.shortname,
    addresses.aolevel,
    addresses.regioncode,
    addresses.areacode,
    addresses.autocode,
    addresses.citycode,
    addresses.ctarcode,
    addresses.placecode,
    addresses.streetcode,
    addresses.extracode,
    addresses.sextcode,
    addresses.plaincode,
    addresses.code,
    addresses.curstatus,
    addresses.actstatus,
    addresses.livestatus,
    addresses.centstatus,
    addresses.operstatus,
    addresses.okato,
    addresses.oktmo,
    addresses.postalcode,
    addresses.divtype,
    addresses.plancode
   FROM public.addresses
  WHERE (addresses.aolevel = 4);


--
-- Name: addresses_5; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.addresses_5 AS
 SELECT addresses.aoid,
    addresses.aoguid,
    addresses.parentguid,
    addresses.nextid,
    addresses.previd,
    addresses.formalname,
    addresses.offname,
    addresses.shortname,
    addresses.aolevel,
    addresses.regioncode,
    addresses.areacode,
    addresses.autocode,
    addresses.citycode,
    addresses.ctarcode,
    addresses.placecode,
    addresses.streetcode,
    addresses.extracode,
    addresses.sextcode,
    addresses.plaincode,
    addresses.code,
    addresses.curstatus,
    addresses.actstatus,
    addresses.livestatus,
    addresses.centstatus,
    addresses.operstatus,
    addresses.okato,
    addresses.oktmo,
    addresses.postalcode,
    addresses.divtype,
    addresses.plancode
   FROM public.addresses
  WHERE (addresses.aolevel = 5);


--
-- Name: addresses_6; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.addresses_6 AS
 SELECT addresses.aoid,
    addresses.aoguid,
    addresses.parentguid,
    addresses.nextid,
    addresses.previd,
    addresses.formalname,
    addresses.offname,
    addresses.shortname,
    addresses.aolevel,
    addresses.regioncode,
    addresses.areacode,
    addresses.autocode,
    addresses.citycode,
    addresses.ctarcode,
    addresses.placecode,
    addresses.streetcode,
    addresses.extracode,
    addresses.sextcode,
    addresses.plaincode,
    addresses.code,
    addresses.curstatus,
    addresses.actstatus,
    addresses.livestatus,
    addresses.centstatus,
    addresses.operstatus,
    addresses.okato,
    addresses.oktmo,
    addresses.postalcode,
    addresses.divtype,
    addresses.plancode
   FROM public.addresses
  WHERE (addresses.aolevel = 6);


--
-- Name: addresses_65; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.addresses_65 AS
 SELECT addresses.aoid,
    addresses.aoguid,
    addresses.parentguid,
    addresses.nextid,
    addresses.previd,
    addresses.formalname,
    addresses.offname,
    addresses.shortname,
    addresses.aolevel,
    addresses.regioncode,
    addresses.areacode,
    addresses.autocode,
    addresses.citycode,
    addresses.ctarcode,
    addresses.placecode,
    addresses.streetcode,
    addresses.extracode,
    addresses.sextcode,
    addresses.plaincode,
    addresses.code,
    addresses.curstatus,
    addresses.actstatus,
    addresses.livestatus,
    addresses.centstatus,
    addresses.operstatus,
    addresses.okato,
    addresses.oktmo,
    addresses.postalcode,
    addresses.divtype,
    addresses.plancode
   FROM public.addresses
  WHERE (addresses.aolevel = 65);


--
-- Name: addresses_7; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.addresses_7 AS
 SELECT addresses.aoid,
    addresses.aoguid,
    addresses.parentguid,
    addresses.nextid,
    addresses.previd,
    addresses.formalname,
    addresses.offname,
    addresses.shortname,
    addresses.aolevel,
    addresses.regioncode,
    addresses.areacode,
    addresses.autocode,
    addresses.citycode,
    addresses.ctarcode,
    addresses.placecode,
    addresses.streetcode,
    addresses.extracode,
    addresses.sextcode,
    addresses.plaincode,
    addresses.code,
    addresses.curstatus,
    addresses.actstatus,
    addresses.livestatus,
    addresses.centstatus,
    addresses.operstatus,
    addresses.okato,
    addresses.oktmo,
    addresses.postalcode,
    addresses.divtype,
    addresses.plancode
   FROM public.addresses
  WHERE (addresses.aolevel = 7);


--
-- Name: eststats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eststats (
    estatid integer NOT NULL,
    name character varying NOT NULL,
    shortname character varying NOT NULL
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
-- Name: fulladdresses; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.fulladdresses AS
 SELECT h.houseid,
    concat(
        CASE
            WHEN (a7.shortname IS NOT NULL) THEN (concat_ws(' '::text, a7.shortname, a7.offname) || ', '::text)
            ELSE ''::text
        END,
        CASE
            WHEN (a6.shortname IS NOT NULL) THEN (concat_ws(' '::text, a6.shortname, a6.offname) || ', '::text)
            ELSE ''::text
        END,
        CASE
            WHEN (a5.shortname IS NOT NULL) THEN (concat_ws(' '::text, a5.shortname, a5.offname) || ', '::text)
            ELSE ''::text
        END,
        CASE
            WHEN (a4.shortname IS NOT NULL) THEN (concat_ws(' '::text, a4.shortname, a4.offname) || ', '::text)
            ELSE ''::text
        END,
        CASE
            WHEN (a3.shortname IS NOT NULL) THEN (concat_ws(' '::text, a3.shortname, a3.offname) || ', '::text)
            ELSE ''::text
        END,
        CASE
            WHEN (a2.shortname IS NOT NULL) THEN (concat_ws(' '::text, a2.shortname, a2.offname) || ', '::text)
            ELSE ''::text
        END,
        CASE
            WHEN (a1.shortname IS NOT NULL) THEN (concat_ws(' '::text, a1.shortname, a1.offname) || ', '::text)
            ELSE ''::text
        END, btrim(concat(
        CASE
            WHEN (h.housenum IS NOT NULL) THEN concat(' ', e.shortname, h.housenum, ' ')
            ELSE ''::text
        END,
        CASE
            WHEN (h.buildnum IS NOT NULL) THEN concat('к ', h.buildnum, ' ')
            ELSE ''::text
        END,
        CASE
            WHEN (h.structnum IS NOT NULL) THEN concat('стр ', h.structnum)
            ELSE ''::text
        END))) AS address,
    btrim(concat(
        CASE
            WHEN (h.housenum IS NOT NULL) THEN concat(' ', e.shortname, h.housenum, ' ')
            ELSE ''::text
        END,
        CASE
            WHEN (h.buildnum IS NOT NULL) THEN concat('к ', h.buildnum, ' ')
            ELSE ''::text
        END,
        CASE
            WHEN (h.structnum IS NOT NULL) THEN concat('стр ', h.structnum)
            ELSE ''::text
        END)) AS house
   FROM ((((((((public.houses h
     JOIN public.eststats e ON ((e.estatid = h.eststatus)))
     JOIN public.addresses a1 ON ((a1.aoguid = h.aoguid)))
     LEFT JOIN public.addresses a2 ON ((a2.aoguid = a1.parentguid)))
     LEFT JOIN public.addresses a3 ON ((a3.aoguid = a2.parentguid)))
     LEFT JOIN public.addresses a4 ON ((a4.aoguid = a3.parentguid)))
     LEFT JOIN public.addresses a5 ON ((a5.aoguid = a4.parentguid)))
     LEFT JOIN public.addresses a6 ON ((a6.aoguid = a5.parentguid)))
     LEFT JOIN public.addresses a7 ON ((a7.aoguid = a6.parentguid)))
  WITH NO DATA;


--
-- Name: socrbase; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.socrbase (
    level integer NOT NULL,
    socrname character varying NOT NULL,
    scname character varying NOT NULL,
    code integer NOT NULL
);


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

CREATE INDEX addresses_aolevel_idx ON public.addresses USING btree (aolevel, shortname);


--
-- Name: addresses_formalname_idx_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX addresses_formalname_idx_gin ON public.addresses USING gin (formalname);


--
-- Name: addresses_idx_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX addresses_idx_gin ON public.fulladdresses USING gin (address);


--
-- Name: addresses_offname_idx_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX addresses_offname_idx_gin ON public.addresses USING gin (offname);


--
-- Name: addresses_parentguid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX addresses_parentguid_idx ON public.addresses USING btree (parentguid);


--
-- Name: addresses_regioncode_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX addresses_regioncode_idx ON public.addresses USING btree (regioncode);


--
-- Name: concat_addr_idx_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX concat_addr_idx_gin ON public.addresses USING gin (concat_address);


--
-- Name: eststats_estatid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX eststats_estatid_idx ON public.eststats USING btree (estatid);


--
-- Name: fulladdresses_houseid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fulladdresses_houseid_idx ON public.fulladdresses USING btree (houseid);


--
-- Name: house_idx_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX house_idx_gin ON public.fulladdresses USING gin (house);


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
-- Name: shortname_idx_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX shortname_idx_gin ON public.addresses USING gin (shortname);


--
-- Name: socrbase_level_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX socrbase_level_idx ON public.socrbase USING btree (level, scname);


--
-- PostgreSQL database dump complete
--

