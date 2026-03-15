CREATE DATABASE "TIVDB"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'th_TH.UTF-8'
    LC_CTYPE = 'th_TH.UTF-8'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

\c TIVDB

CREATE TABLE public.property_listing (
    url           text                  NOT NULL,
    topic         text                  NOT NULL,
    source        text                  NOT NULL,
    type          character varying(50),
    status        character varying(20),
    street        text,
    subdistrict   text,
    district      text,
    province      text,
    price         numeric(15,2),
    landsize      numeric(10,2),
    usablearea    numeric(10,2),
    bedcount      integer,
    bathroomcount integer,
    parkingcount  integer,
    announceddate date,
    recorddate    date DEFAULT now(),
    CONSTRAINT property_listing_pkey PRIMARY KEY (url),
    CONSTRAINT property_listing_price_check CHECK (price >= 0),
    CONSTRAINT property_listing_landsize_check CHECK (landsize >= 0),
    CONSTRAINT property_listing_usablearea_check CHECK (usablearea >= 0),
    CONSTRAINT property_listing_bedcount_check CHECK (bedcount >= 0),
    CONSTRAINT property_listing_bathroomcount_check CHECK (bathroomcount >= 0),
    CONSTRAINT property_listing_parkingcount_check CHECK (parkingcount >= 0)
);
