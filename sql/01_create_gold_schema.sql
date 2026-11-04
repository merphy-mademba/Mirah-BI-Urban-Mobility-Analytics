USE [mirah_bi_urban_mobility_db];
GO
SET XACT_ABORT ON;
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'gold')
    EXEC(N'CREATE SCHEMA gold AUTHORIZATION dbo');
GO

DROP TABLE IF EXISTS gold.top_societes;
DROP TABLE IF EXISTS gold.top_chauffeurs;
DROP TABLE IF EXISTS gold.revenus_par_ville;
DROP TABLE IF EXISTS gold.performance_chauffeurs;
DROP TABLE IF EXISTS gold.kpi_tarification;
DROP TABLE IF EXISTS gold.kpi_satisfaction;
DROP TABLE IF EXISTS gold.kpi_paiements;
DROP TABLE IF EXISTS gold.kpi_global;
DROP TABLE IF EXISTS gold.kpi_courses;
DROP TABLE IF EXISTS gold.experience_client;
DROP TABLE IF EXISTS gold.courses_par_ville;
GO

CREATE TABLE gold.courses_par_ville (
    annee SMALLINT NOT NULL,
    mois TINYINT NOT NULL,
    ville NVARCHAR(50) NOT NULL,
    categorie NVARCHAR(30) NOT NULL,
    nombre_courses BIGINT NOT NULL,
    courses_terminees BIGINT NOT NULL,
    courses_annulees BIGINT NOT NULL,
    distance_totale_km DECIMAL(18,2) NOT NULL,
    duree_moyenne_minutes DECIMAL(10,2) NULL,
    CONSTRAINT PK_gold_courses_par_ville PRIMARY KEY (annee, mois, ville, categorie),
    CONSTRAINT CK_gold_courses_par_ville_mois CHECK (mois BETWEEN 1 AND 12)
);
GO

CREATE TABLE gold.experience_client (
    client_id INT NOT NULL,
    societe_id INT NOT NULL,
    nombre_avis BIGINT NOT NULL,
    note_moyenne_course DECIMAL(5,2) NULL,
    note_moyenne_chauffeur DECIMAL(5,2) NULL,
    note_globale_moyenne DECIMAL(5,2) NULL,
    ville NVARCHAR(50) NULL,
    statut NVARCHAR(30) NULL,
    nom_societe NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_gold_experience_client PRIMARY KEY (client_id, societe_id)
);
GO

CREATE TABLE gold.kpi_courses (
    annee SMALLINT NOT NULL,
    mois TINYINT NOT NULL,
    ville NVARCHAR(50) NOT NULL,
    societe_id INT NOT NULL,
    categorie NVARCHAR(30) NOT NULL,
    nombre_courses BIGINT NOT NULL,
    courses_terminees BIGINT NOT NULL,
    courses_annulees BIGINT NOT NULL,
    distance_totale_km DECIMAL(18,2) NOT NULL,
    distance_moyenne_km DECIMAL(10,2) NULL,
    duree_moyenne_minutes DECIMAL(10,2) NULL,
    montant_courses DECIMAL(18,2) NOT NULL,
    taux_annulation_pct DECIMAL(7,2) NULL,
    nom_societe NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_gold_kpi_courses PRIMARY KEY (annee, mois, ville, societe_id, categorie),
    CONSTRAINT CK_gold_kpi_courses_mois CHECK (mois BETWEEN 1 AND 12)
);
GO

CREATE TABLE gold.kpi_global (
    kpi_global_id TINYINT NOT NULL CONSTRAINT DF_gold_kpi_global_id DEFAULT 1,
    nombre_societes BIGINT NOT NULL,
    nombre_clients BIGINT NOT NULL,
    clients_actifs BIGINT NOT NULL,
    nombre_chauffeurs BIGINT NOT NULL,
    chauffeurs_actifs BIGINT NOT NULL,
    nombre_vehicules BIGINT NOT NULL,
    nombre_courses BIGINT NOT NULL,
    courses_terminees BIGINT NOT NULL,
    courses_annulees BIGINT NOT NULL,
    taux_annulation_pct DECIMAL(7,2) NULL,
    distance_totale_km DECIMAL(18,2) NOT NULL,
    distance_moyenne_km DECIMAL(10,2) NULL,
    duree_moyenne_minutes DECIMAL(10,2) NULL,
    montant_total_du DECIMAL(18,2) NOT NULL,
    chiffre_affaires_encaisse DECIMAL(18,2) NOT NULL,
    solde_total_restant DECIMAL(18,2) NOT NULL,
    nombre_avis BIGINT NOT NULL,
    note_moyenne_course DECIMAL(5,2) NULL,
    note_moyenne_chauffeur DECIMAL(5,2) NULL,
    devise CHAR(3) NOT NULL,
    CONSTRAINT PK_gold_kpi_global PRIMARY KEY (kpi_global_id),
    CONSTRAINT CK_gold_kpi_global_unique CHECK (kpi_global_id = 1)
);
GO

CREATE TABLE gold.kpi_paiements (
    annee SMALLINT NOT NULL,
    mois TINYINT NOT NULL,
    societe_id INT NOT NULL,
    mode_paiement NVARCHAR(30) NOT NULL,
    statut_paiement NVARCHAR(30) NOT NULL,
    nombre_paiements BIGINT NOT NULL,
    montant_du DECIMAL(18,2) NOT NULL,
    montant_paye DECIMAL(18,2) NOT NULL,
    solde_restant DECIMAL(18,2) NOT NULL,
    nom_societe NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_gold_kpi_paiements PRIMARY KEY (annee, mois, societe_id, mode_paiement, statut_paiement),
    CONSTRAINT CK_gold_kpi_paiements_mois CHECK (mois BETWEEN 1 AND 12)
);
GO

CREATE TABLE gold.kpi_satisfaction (
    annee SMALLINT NOT NULL,
    mois TINYINT NOT NULL,
    societe_id INT NOT NULL,
    nombre_avis BIGINT NOT NULL,
    note_moyenne_course DECIMAL(5,2) NULL,
    note_moyenne_chauffeur DECIMAL(5,2) NULL,
    note_globale_moyenne DECIMAL(5,2) NULL,
    avis_satisfaits BIGINT NOT NULL,
    taux_satisfaction_pct DECIMAL(7,2) NULL,
    nom_societe NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_gold_kpi_satisfaction PRIMARY KEY (annee, mois, societe_id),
    CONSTRAINT CK_gold_kpi_satisfaction_mois CHECK (mois BETWEEN 1 AND 12)
);
GO

CREATE TABLE gold.kpi_tarification (
    societe_id INT NOT NULL,
    ville NVARCHAR(50) NOT NULL,
    categorie NVARCHAR(30) NOT NULL,
    prix_depart_moyen DECIMAL(18,2) NOT NULL,
    prix_km_moyen DECIMAL(18,2) NOT NULL,
    prix_minimum_moyen DECIMAL(18,2) NOT NULL,
    distance_max_couverte_km DECIMAL(10,2) NOT NULL,
    nom_societe NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_gold_kpi_tarification PRIMARY KEY (societe_id, ville, categorie)
);
GO

CREATE TABLE gold.performance_chauffeurs (
    chauffeur_id INT NOT NULL,
    nom NVARCHAR(150) NOT NULL,
    societe_id INT NOT NULL,
    ville NVARCHAR(50) NOT NULL,
    statut NVARCHAR(30) NOT NULL,
    nombre_courses BIGINT NOT NULL,
    distance_totale_km DECIMAL(18,2) NOT NULL,
    duree_totale_minutes BIGINT NOT NULL,
    revenu_genere DECIMAL(18,2) NOT NULL,
    nombre_avis BIGINT NOT NULL,
    note_moyenne_chauffeur DECIMAL(5,2) NULL,
    nom_societe NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_gold_performance_chauffeurs PRIMARY KEY (chauffeur_id)
);
GO

CREATE TABLE gold.revenus_par_ville (
    annee SMALLINT NOT NULL,
    mois TINYINT NOT NULL,
    ville NVARCHAR(50) NOT NULL,
    categorie NVARCHAR(30) NOT NULL,
    societe_id INT NOT NULL,
    montant_du DECIMAL(18,2) NOT NULL,
    chiffre_affaires_encaisse DECIMAL(18,2) NOT NULL,
    solde_restant DECIMAL(18,2) NOT NULL,
    nom_societe NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_gold_revenus_par_ville PRIMARY KEY (annee, mois, ville, categorie, societe_id),
    CONSTRAINT CK_gold_revenus_par_ville_mois CHECK (mois BETWEEN 1 AND 12)
);
GO

CREATE TABLE gold.top_chauffeurs (
    chauffeur_id INT NOT NULL,
    nom NVARCHAR(150) NOT NULL,
    societe_id INT NOT NULL,
    ville NVARCHAR(50) NOT NULL,
    statut NVARCHAR(30) NOT NULL,
    nombre_courses BIGINT NOT NULL,
    distance_totale_km DECIMAL(18,2) NOT NULL,
    duree_totale_minutes BIGINT NOT NULL,
    revenu_genere DECIMAL(18,2) NOT NULL,
    nombre_avis BIGINT NOT NULL,
    note_moyenne_chauffeur DECIMAL(5,2) NULL,
    nom_societe NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_gold_top_chauffeurs PRIMARY KEY (chauffeur_id)
);
GO

CREATE TABLE gold.top_societes (
    societe_id INT NOT NULL,
    nom_societe NVARCHAR(100) NOT NULL,
    nombre_courses BIGINT NOT NULL,
    courses_terminees BIGINT NOT NULL,
    courses_annulees BIGINT NOT NULL,
    montant_du DECIMAL(18,2) NOT NULL,
    chiffre_affaires_encaisse DECIMAL(18,2) NOT NULL,
    solde_restant DECIMAL(18,2) NOT NULL,
    nombre_avis BIGINT NOT NULL,
    note_globale_moyenne DECIMAL(5,2) NULL,
    part_courses_pct DECIMAL(7,2) NULL,
    taux_annulation_pct DECIMAL(7,2) NULL,
    CONSTRAINT PK_gold_top_societes PRIMARY KEY (societe_id)
);
GO

CREATE INDEX IX_gold_kpi_courses_societe ON gold.kpi_courses(societe_id);
CREATE INDEX IX_gold_kpi_courses_ville ON gold.kpi_courses(ville);
CREATE INDEX IX_gold_kpi_paiements_societe ON gold.kpi_paiements(societe_id);
CREATE INDEX IX_gold_performance_societe ON gold.performance_chauffeurs(societe_id);
CREATE INDEX IX_gold_revenus_ville ON gold.revenus_par_ville(ville);
GO

SELECT s.name AS schema_name, t.name AS table_name, SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
WHERE s.name = N'gold'
GROUP BY s.name, t.name
ORDER BY t.name;
GO
