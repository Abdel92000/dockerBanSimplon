CREATE TABLE newtable (
    id VARCHAR(250),
    id_fantoir VARCHAR(250),
    numero INT,
    rep TEXT,
    nom_voie VARCHAR(250),
    code_postal INT,
    code_insee INT,
    nom_commune VARCHAR(250),
    code_insee_ancienne_commune VARCHAR(250),
    nom_ancienne_commune VARCHAR(250),
    x FLOAT4,
    y FLOAT4,
    lon FLOAT4,
    lat FLOAT4,
    type_position VARCHAR(50),
    alias VARCHAR(250),
    nom_ld VARCHAR(250),
    libelle_acheminement VARCHAR(255),
    nom_afnor VARCHAR(250),
    source_position VARCHAR(50),
    source_nom_voie VARCHAR(250),
    certification_commune INT,
    cad_parcelles VARCHAR(250)
);

COPY newtable
FROM '/docker-entrypoint-initdb.d/adresses-92.csv'
DELIMITER ';'
CSV HEADER;



-- =========================================================
-- création des tables normalisées BAN
-- =========================================================

-- 1) COMMUNE

CREATE TABLE commune (
    id SERIAL PRIMARY KEY,
    code_insee INT UNIQUE,
    code_poqtal VARCHAR(5) NOT NULL,
    nom_commune VARCHAR(50) UNIQUE
);


-- 2) COMMUNE_ANCIENNE

CREATE TABLE commune_ancienne (
    id SERIAL PRIMARY KEY,
    code_insee_ancienne VARCHAR(10),
    nom_ancienne_commune VARCHAR(255),
    id_commune INT NOT NULL,
    FOREIGN KEY (id_commune) REFERENCES commune(id)
);


-- 3) VOIE

CREATE TABLE voie (
    id SERIAL PRIMARY KEY,
    id_fantoir VARCHAR(50),
    nom_voie VARCHAR(250),
    nom_afnor VARCHAR(250),
    libelle_acheminement VARCHAR(255),
    source_nom_voie VARCHAR(250),
    id_commune INT NOT NULL,
    FOREIGN KEY (id_commune) REFERENCES commune(id)
);

-- 4) LIEU_DIT
CREATE TABLE lieu_dit (
    id SERIAL PRIMARY KEY,
    nom_ld VARCHAR(50)
);

-- 5) CAD_PARCELLE
CREATE TABLE cad_parcelle (
    id SERIAL PRIMARY KEY,
    cad_parcelles VARCHAR(250)
);

-- 6) ADRESSE
CREATE TABLE adresse (
    id_adresse text PRIMARY KEY,
    numero INT,
    rep TEXT,

    lat FLOAT,
    lon FLOAT,
    x FLOAT,
    y FLOAT,

    type_position VARCHAR(50),
    source_position VARCHAR(50),

    alias VARCHAR(250),
    certification_commune INT,
    libelle_acheminement VARCHAR(250),

    id_voie INT NOT NULL,
    id_lieu_dit INT,
    id_cad_parcelle INT,

    FOREIGN KEY (id_voie) REFERENCES voie(id),
    FOREIGN KEY (id_lieu_dit) REFERENCES lieu_dit(id),
    FOREIGN KEY (id_cad_parcelle) REFERENCES cad_parcelle(id)
);





TRUNCATE adresse, voie, cad_parcelle, lieu_dit, commune_ancienne, commune
RESTART IDENTITY CASCADE;

-- 1) COMMUNE

INSERT INTO commune (code_insee, code_poqtal, nom_commune)
select DISTINCT
    newtable.code_insee,
    newtable.code_postal,
    newtable.nom_commune
FROM newtable
WHERE code_insee IS NOT null
ON CONFLICT (code_insee) DO NOTHING;

-- 2) COMMUNE_ANCIENNE

INSERT INTO commune_ancienne (code_insee_ancienne, nom_ancienne_commune, id_commune)
SELECT DISTINCT
    code_insee_ancienne_commune,
    nom_ancienne_commune,
    commune.id
FROM newtable
JOIN commune ON commune.code_insee = newtable.code_insee
WHERE code_insee_ancienne_commune IS NOT NULL;

-- 3) LIEU_DIT

INSERT INTO lieu_dit (nom_ld)
SELECT DISTINCT
    nom_ld
FROM newtable
WHERE nom_ld IS NOT NULL;

-- 4) CAD_PARCELLE

INSERT INTO cad_parcelle (cad_parcelles)
SELECT DISTINCT
    cad_parcelles
FROM newtable
WHERE cad_parcelles IS NOT NULL;

-- 5) VOIE

INSERT INTO voie (id_fantoir, nom_voie, nom_afnor, libelle_acheminement, source_nom_voie, id_commune)
SELECT DISTINCT
   	newtable.id_fantoir,
    newtable.nom_voie,
    newtable.nom_afnor,
    newtable.libelle_acheminement,
    newtable.source_nom_voie,
    commune.id
FROM newtable
JOIN commune ON commune.code_insee = newtable.code_insee
WHERE id_fantoir IS NOT null;

-- 6) ADRESSE

INSERT INTO adresse (
	id_adresse,
    numero,
    rep,
    lat,
    lon,
    x,
    y,
    type_position,
    source_position,
    alias,
    certification_commune,
    id_voie,
    id_lieu_dit,
    id_cad_parcelle
)
select
	newtable.id,
    numero,
    rep,
    lat,
    lon,
    x,
    y,
    type_position,
    source_position,
    alias,
    certification_commune,
    voie.id,
    lieu_dit.id,
    cad_parcelle.id
FROM newtable
JOIN voie ON voie.id_fantoir = newtable.id_fantoir
LEFT JOIN lieu_dit ON lieu_dit.nom_ld = newtable.nom_ld
LEFT JOIN cad_parcelle ON cad_parcelle.cad_parcelles = newtable.cad_parcelles
ON CONFLICT (id_adresse) DO NOTHING;



