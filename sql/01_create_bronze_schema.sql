USE [mirah_bi_urban_mobility_db];
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name=N'bronze') EXEC(N'CREATE SCHEMA bronze AUTHORIZATION dbo');
GO
DROP TABLE IF EXISTS bronze.avis_clients;
DROP TABLE IF EXISTS bronze.paiements;
DROP TABLE IF EXISTS bronze.courses;
DROP TABLE IF EXISTS bronze.tarification;
DROP TABLE IF EXISTS bronze.vehicules;
DROP TABLE IF EXISTS bronze.chauffeurs;
DROP TABLE IF EXISTS bronze.clients;
DROP TABLE IF EXISTS bronze.societes_transport;
GO
CREATE TABLE bronze.societes_transport (
 societe_id NVARCHAR(100) NULL, nom_societe NVARCHAR(255) NULL, date_lancement NVARCHAR(100) NULL,
 statut NVARCHAR(100) NULL, villes_operation NVARCHAR(MAX) NULL, source_system NVARCHAR(100) NULL,
 batch_id NVARCHAR(100) NULL, ingested_at NVARCHAR(100) NULL
);
CREATE TABLE bronze.clients (
 client_id NVARCHAR(100) NULL, nom NVARCHAR(255) NULL, genre NVARCHAR(50) NULL,
 origine_nom_synthetique NVARCHAR(100) NULL, telephone NVARCHAR(100) NULL, ville NVARCHAR(100) NULL,
 date_inscription NVARCHAR(100) NULL, statut NVARCHAR(100) NULL, source_system NVARCHAR(100) NULL,
 batch_id NVARCHAR(100) NULL, ingested_at NVARCHAR(100) NULL
);
CREATE TABLE bronze.chauffeurs (
 chauffeur_id NVARCHAR(100) NULL, societe_id NVARCHAR(100) NULL, nom NVARCHAR(255) NULL, genre NVARCHAR(50) NULL,
 origine_nom_synthetique NVARCHAR(100) NULL, telephone NVARCHAR(100) NULL, ville NVARCHAR(100) NULL,
 date_integration NVARCHAR(100) NULL, statut NVARCHAR(100) NULL, source_system NVARCHAR(100) NULL,
 batch_id NVARCHAR(100) NULL, ingested_at NVARCHAR(100) NULL
);
CREATE TABLE bronze.vehicules (
 vehicule_id NVARCHAR(100) NULL, chauffeur_id NVARCHAR(100) NULL, societe_id NVARCHAR(100) NULL,
 ville NVARCHAR(100) NULL, marque NVARCHAR(100) NULL, modele NVARCHAR(100) NULL, annee NVARCHAR(50) NULL,
 immatriculation NVARCHAR(100) NULL, categorie NVARCHAR(100) NULL, statut NVARCHAR(100) NULL,
 source_system NVARCHAR(100) NULL, batch_id NVARCHAR(100) NULL, ingested_at NVARCHAR(100) NULL
);
CREATE TABLE bronze.tarification (
 tarification_id NVARCHAR(100) NULL, societe_id NVARCHAR(100) NULL, ville NVARCHAR(100) NULL,
 categorie NVARCHAR(100) NULL, distance_min_km NVARCHAR(100) NULL, distance_max_km NVARCHAR(100) NULL,
 prix_depart NVARCHAR(100) NULL, prix_km NVARCHAR(100) NULL, prix_minimum NVARCHAR(100) NULL, devise NVARCHAR(50) NULL,
 date_effet NVARCHAR(100) NULL, statut NVARCHAR(100) NULL, source_system NVARCHAR(100) NULL,
 batch_id NVARCHAR(100) NULL, ingested_at NVARCHAR(100) NULL
);
CREATE TABLE bronze.courses (
 course_id NVARCHAR(100) NULL, societe_id NVARCHAR(100) NULL, client_id NVARCHAR(100) NULL,
 chauffeur_id NVARCHAR(100) NULL, vehicule_id NVARCHAR(100) NULL, tarification_id NVARCHAR(100) NULL,
 date_course NVARCHAR(100) NULL, heure_course NVARCHAR(100) NULL, annee NVARCHAR(50) NULL, mois NVARCHAR(50) NULL,
 ville NVARCHAR(100) NULL, point_depart NVARCHAR(255) NULL, point_arrivee NVARCHAR(255) NULL,
 distance_km NVARCHAR(100) NULL, duree_minutes NVARCHAR(100) NULL, categorie NVARCHAR(100) NULL,
 marque_vehicule NVARCHAR(100) NULL, montant_course NVARCHAR(100) NULL, devise NVARCHAR(50) NULL,
 statut_course NVARCHAR(100) NULL, source_system NVARCHAR(100) NULL, batch_id NVARCHAR(100) NULL,
 ingested_at NVARCHAR(100) NULL
);
CREATE TABLE bronze.paiements (
 paiement_id NVARCHAR(100) NULL, course_id NVARCHAR(100) NULL, societe_id NVARCHAR(100) NULL,
 client_id NVARCHAR(100) NULL, montant_du NVARCHAR(100) NULL, montant_paye NVARCHAR(100) NULL,
 solde_restant NVARCHAR(100) NULL, devise NVARCHAR(50) NULL, mode_paiement NVARCHAR(100) NULL,
 date_paiement NVARCHAR(100) NULL, statut_paiement NVARCHAR(100) NULL, source_system NVARCHAR(100) NULL,
 batch_id NVARCHAR(100) NULL, ingested_at NVARCHAR(100) NULL
);
CREATE TABLE bronze.avis_clients (
 avis_id NVARCHAR(100) NULL, course_id NVARCHAR(100) NULL, societe_id NVARCHAR(100) NULL,
 client_id NVARCHAR(100) NULL, chauffeur_id NVARCHAR(100) NULL, note_course NVARCHAR(50) NULL,
 note_chauffeur NVARCHAR(50) NULL, commentaire NVARCHAR(MAX) NULL, date_avis NVARCHAR(100) NULL,
 source_system NVARCHAR(100) NULL, batch_id NVARCHAR(100) NULL, ingested_at NVARCHAR(100) NULL
);
GO
SELECT s.name schema_name,t.name table_name,SUM(p.rows) row_count FROM sys.tables t
JOIN sys.schemas s ON s.schema_id=t.schema_id JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN(0,1)
WHERE s.name=N'bronze' GROUP BY s.name,t.name ORDER BY t.name;
GO
