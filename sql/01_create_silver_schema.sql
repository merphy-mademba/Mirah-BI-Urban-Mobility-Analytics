USE [mirah_bi_urban_mobility_db];
GO
SET XACT_ABORT ON;
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name=N'silver') EXEC(N'CREATE SCHEMA silver AUTHORIZATION dbo');
GO
DROP TABLE IF EXISTS silver.avis_clients;
DROP TABLE IF EXISTS silver.paiements;
DROP TABLE IF EXISTS silver.courses;
DROP TABLE IF EXISTS silver.tarification;
DROP TABLE IF EXISTS silver.vehicules;
DROP TABLE IF EXISTS silver.chauffeurs;
DROP TABLE IF EXISTS silver.clients;
DROP TABLE IF EXISTS silver.societes_transport;
GO
CREATE TABLE silver.societes_transport (
 societe_id INT NOT NULL, nom_societe NVARCHAR(100) NOT NULL, date_lancement DATE NOT NULL,
 statut NVARCHAR(20) NOT NULL, villes_operation NVARCHAR(500) NOT NULL,
 CONSTRAINT PK_silver_societes PRIMARY KEY(societe_id), CONSTRAINT UQ_silver_societes_nom UNIQUE(nom_societe)
);
CREATE TABLE silver.clients (
 client_id INT NOT NULL, nom NVARCHAR(150) NOT NULL, genre NVARCHAR(20) NOT NULL,
 origine_nom_synthetique NVARCHAR(50) NULL, telephone VARCHAR(20) NOT NULL, ville NVARCHAR(50) NOT NULL,
 date_inscription DATE NOT NULL, statut NVARCHAR(20) NOT NULL,
 CONSTRAINT PK_silver_clients PRIMARY KEY(client_id)
);
CREATE TABLE silver.chauffeurs (
 chauffeur_id INT NOT NULL, societe_id INT NOT NULL, nom NVARCHAR(150) NOT NULL, genre NVARCHAR(20) NOT NULL,
 origine_nom_synthetique NVARCHAR(50) NULL, telephone VARCHAR(20) NOT NULL, ville NVARCHAR(50) NOT NULL,
 date_integration DATE NOT NULL, statut NVARCHAR(20) NOT NULL,
 CONSTRAINT PK_silver_chauffeurs PRIMARY KEY(chauffeur_id),
 CONSTRAINT FK_silver_chauffeurs_societe FOREIGN KEY(societe_id) REFERENCES silver.societes_transport(societe_id)
);
CREATE TABLE silver.vehicules (
 vehicule_id INT NOT NULL, chauffeur_id INT NOT NULL, societe_id INT NOT NULL, ville NVARCHAR(50) NOT NULL,
 marque NVARCHAR(80) NOT NULL, modele NVARCHAR(80) NOT NULL, annee SMALLINT NOT NULL,
 immatriculation VARCHAR(30) NOT NULL, categorie NVARCHAR(30) NOT NULL, statut NVARCHAR(30) NOT NULL,
 CONSTRAINT PK_silver_vehicules PRIMARY KEY(vehicule_id),
 CONSTRAINT FK_silver_vehicules_chauffeur FOREIGN KEY(chauffeur_id) REFERENCES silver.chauffeurs(chauffeur_id),
 CONSTRAINT FK_silver_vehicules_societe FOREIGN KEY(societe_id) REFERENCES silver.societes_transport(societe_id),
 CONSTRAINT UQ_silver_vehicules_immat UNIQUE(immatriculation)
);
CREATE TABLE silver.tarification (
 tarification_id INT NOT NULL, societe_id INT NOT NULL, ville NVARCHAR(50) NOT NULL, categorie NVARCHAR(30) NOT NULL,
 distance_min_km DECIMAL(8,2) NOT NULL, distance_max_km DECIMAL(8,2) NOT NULL, prix_depart DECIMAL(12,2) NOT NULL,
 prix_km DECIMAL(12,2) NOT NULL, prix_minimum DECIMAL(12,2) NOT NULL, devise CHAR(3) NOT NULL,
 date_effet DATE NOT NULL, statut NVARCHAR(20) NOT NULL,
 CONSTRAINT PK_silver_tarification PRIMARY KEY(tarification_id),
 CONSTRAINT FK_silver_tarification_societe FOREIGN KEY(societe_id) REFERENCES silver.societes_transport(societe_id),
 CONSTRAINT CK_silver_tarification_distance CHECK(distance_min_km >= 0 AND distance_max_km > distance_min_km),
 CONSTRAINT CK_silver_tarification_prix CHECK(prix_depart >= 0 AND prix_km >= 0 AND prix_minimum >= 0),
 CONSTRAINT CK_silver_tarification_devise CHECK(devise='XOF')
);
CREATE TABLE silver.courses (
 course_id INT NOT NULL, societe_id INT NOT NULL, client_id INT NOT NULL, chauffeur_id INT NOT NULL,
 vehicule_id INT NOT NULL, tarification_id INT NOT NULL, date_course DATE NOT NULL, heure_course TIME(0) NOT NULL,
 annee SMALLINT NOT NULL, mois TINYINT NOT NULL, ville NVARCHAR(50) NOT NULL, point_depart NVARCHAR(100) NOT NULL,
 point_arrivee NVARCHAR(100) NOT NULL, distance_km DECIMAL(8,2) NOT NULL, duree_minutes INT NOT NULL,
 categorie NVARCHAR(30) NOT NULL, marque_vehicule NVARCHAR(80) NOT NULL, montant_course DECIMAL(12,2) NOT NULL,
 devise CHAR(3) NOT NULL, statut_course NVARCHAR(30) NOT NULL,
 CONSTRAINT PK_silver_courses PRIMARY KEY(course_id),
 CONSTRAINT FK_silver_courses_societe FOREIGN KEY(societe_id) REFERENCES silver.societes_transport(societe_id),
 CONSTRAINT FK_silver_courses_client FOREIGN KEY(client_id) REFERENCES silver.clients(client_id),
 CONSTRAINT FK_silver_courses_chauffeur FOREIGN KEY(chauffeur_id) REFERENCES silver.chauffeurs(chauffeur_id),
 CONSTRAINT FK_silver_courses_vehicule FOREIGN KEY(vehicule_id) REFERENCES silver.vehicules(vehicule_id),
 CONSTRAINT FK_silver_courses_tarification FOREIGN KEY(tarification_id) REFERENCES silver.tarification(tarification_id),
 CONSTRAINT CK_silver_courses_mois CHECK(mois BETWEEN 1 AND 12),
 CONSTRAINT CK_silver_courses_distance CHECK(distance_km > 0),
 CONSTRAINT CK_silver_courses_duree CHECK(duree_minutes > 0),
 CONSTRAINT CK_silver_courses_montant CHECK(montant_course >= 0), CONSTRAINT CK_silver_courses_devise CHECK(devise='XOF')
);
CREATE TABLE silver.paiements (
 paiement_id INT NOT NULL, course_id INT NOT NULL, societe_id INT NOT NULL, client_id INT NOT NULL,
 montant_du DECIMAL(12,2) NOT NULL, montant_paye DECIMAL(12,2) NOT NULL, solde_restant DECIMAL(12,2) NOT NULL,
 devise CHAR(3) NOT NULL, mode_paiement NVARCHAR(30) NOT NULL, date_paiement DATETIME2(0) NOT NULL,
 statut_paiement NVARCHAR(30) NOT NULL,
 CONSTRAINT PK_silver_paiements PRIMARY KEY(paiement_id), CONSTRAINT UQ_silver_paiement_course UNIQUE(course_id),
 CONSTRAINT FK_silver_paiements_course FOREIGN KEY(course_id) REFERENCES silver.courses(course_id),
 CONSTRAINT FK_silver_paiements_societe FOREIGN KEY(societe_id) REFERENCES silver.societes_transport(societe_id),
 CONSTRAINT FK_silver_paiements_client FOREIGN KEY(client_id) REFERENCES silver.clients(client_id),
 CONSTRAINT CK_silver_paiements_montants CHECK(montant_du >= 0 AND montant_paye >= 0 AND solde_restant >= 0),
 CONSTRAINT CK_silver_paiements_devise CHECK(devise='XOF')
);
CREATE TABLE silver.avis_clients (
 avis_id INT NOT NULL, course_id INT NOT NULL, societe_id INT NOT NULL, client_id INT NOT NULL, chauffeur_id INT NOT NULL,
 note_course TINYINT NOT NULL, note_chauffeur TINYINT NOT NULL, commentaire NVARCHAR(1000) NULL, date_avis DATETIME2(0) NOT NULL,
 CONSTRAINT PK_silver_avis PRIMARY KEY(avis_id), CONSTRAINT UQ_silver_avis_course UNIQUE(course_id),
 CONSTRAINT FK_silver_avis_course FOREIGN KEY(course_id) REFERENCES silver.courses(course_id),
 CONSTRAINT FK_silver_avis_societe FOREIGN KEY(societe_id) REFERENCES silver.societes_transport(societe_id),
 CONSTRAINT FK_silver_avis_client FOREIGN KEY(client_id) REFERENCES silver.clients(client_id),
 CONSTRAINT FK_silver_avis_chauffeur FOREIGN KEY(chauffeur_id) REFERENCES silver.chauffeurs(chauffeur_id),
 CONSTRAINT CK_silver_avis_notes CHECK(note_course BETWEEN 1 AND 5 AND note_chauffeur BETWEEN 1 AND 5)
);
GO
CREATE INDEX IX_silver_courses_date ON silver.courses(date_course);
CREATE INDEX IX_silver_courses_societe ON silver.courses(societe_id);
CREATE INDEX IX_silver_courses_chauffeur ON silver.courses(chauffeur_id);
CREATE INDEX IX_silver_courses_ville ON silver.courses(ville);
CREATE INDEX IX_silver_paiements_date ON silver.paiements(date_paiement);
CREATE INDEX IX_silver_avis_chauffeur ON silver.avis_clients(chauffeur_id);
GO
SELECT s.name schema_name,t.name table_name,SUM(p.rows) row_count FROM sys.tables t
JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN(0,1)
WHERE s.name=N'silver' GROUP BY s.name,t.name ORDER BY t.name;
GO
