USE [mirah_bi_urban_mobility_db];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT '=== 1. VOLUMES BRONZE / SILVER ===';
SELECT couche, table_name, lignes
FROM (
    SELECT 'bronze' couche, 'societes_transport' table_name, COUNT_BIG(*) lignes FROM bronze.societes_transport
    UNION ALL SELECT 'silver','societes_transport',COUNT_BIG(*) FROM silver.societes_transport
    UNION ALL SELECT 'bronze','clients',COUNT_BIG(*) FROM bronze.clients
    UNION ALL SELECT 'silver','clients',COUNT_BIG(*) FROM silver.clients
    UNION ALL SELECT 'bronze','chauffeurs',COUNT_BIG(*) FROM bronze.chauffeurs
    UNION ALL SELECT 'silver','chauffeurs',COUNT_BIG(*) FROM silver.chauffeurs
    UNION ALL SELECT 'bronze','vehicules',COUNT_BIG(*) FROM bronze.vehicules
    UNION ALL SELECT 'silver','vehicules',COUNT_BIG(*) FROM silver.vehicules
    UNION ALL SELECT 'bronze','tarification',COUNT_BIG(*) FROM bronze.tarification
    UNION ALL SELECT 'silver','tarification',COUNT_BIG(*) FROM silver.tarification
    UNION ALL SELECT 'bronze','courses',COUNT_BIG(*) FROM bronze.courses
    UNION ALL SELECT 'silver','courses',COUNT_BIG(*) FROM silver.courses
    UNION ALL SELECT 'bronze','paiements',COUNT_BIG(*) FROM bronze.paiements
    UNION ALL SELECT 'silver','paiements',COUNT_BIG(*) FROM silver.paiements
    UNION ALL SELECT 'bronze','avis_clients',COUNT_BIG(*) FROM bronze.avis_clients
    UNION ALL SELECT 'silver','avis_clients',COUNT_BIG(*) FROM silver.avis_clients
) v
ORDER BY table_name, couche;
GO

PRINT '=== 2. DOUBLONS SUR CLES SILVER ===';
SELECT 'societes_transport' table_name, COUNT_BIG(*) doublons FROM (SELECT societe_id FROM silver.societes_transport GROUP BY societe_id HAVING COUNT(*) > 1) d
UNION ALL SELECT 'clients',COUNT_BIG(*) FROM (SELECT client_id FROM silver.clients GROUP BY client_id HAVING COUNT(*) > 1) d
UNION ALL SELECT 'chauffeurs',COUNT_BIG(*) FROM (SELECT chauffeur_id FROM silver.chauffeurs GROUP BY chauffeur_id HAVING COUNT(*) > 1) d
UNION ALL SELECT 'vehicules',COUNT_BIG(*) FROM (SELECT vehicule_id FROM silver.vehicules GROUP BY vehicule_id HAVING COUNT(*) > 1) d
UNION ALL SELECT 'tarification',COUNT_BIG(*) FROM (SELECT tarification_id FROM silver.tarification GROUP BY tarification_id HAVING COUNT(*) > 1) d
UNION ALL SELECT 'courses',COUNT_BIG(*) FROM (SELECT course_id FROM silver.courses GROUP BY course_id HAVING COUNT(*) > 1) d
UNION ALL SELECT 'paiements',COUNT_BIG(*) FROM (SELECT paiement_id FROM silver.paiements GROUP BY paiement_id HAVING COUNT(*) > 1) d
UNION ALL SELECT 'avis_clients',COUNT_BIG(*) FROM (SELECT avis_id FROM silver.avis_clients GROUP BY avis_id HAVING COUNT(*) > 1) d;
GO

PRINT '=== 3. ORPHELINS SILVER ===';
SELECT 'chauffeurs -> societes' controle, COUNT_BIG(*) anomalies
FROM silver.chauffeurs c LEFT JOIN silver.societes_transport s ON s.societe_id=c.societe_id WHERE s.societe_id IS NULL
UNION ALL SELECT 'vehicules -> chauffeurs',COUNT_BIG(*) FROM silver.vehicules v LEFT JOIN silver.chauffeurs c ON c.chauffeur_id=v.chauffeur_id WHERE c.chauffeur_id IS NULL
UNION ALL SELECT 'vehicules -> societes',COUNT_BIG(*) FROM silver.vehicules v LEFT JOIN silver.societes_transport s ON s.societe_id=v.societe_id WHERE s.societe_id IS NULL
UNION ALL SELECT 'tarification -> societes',COUNT_BIG(*) FROM silver.tarification t LEFT JOIN silver.societes_transport s ON s.societe_id=t.societe_id WHERE s.societe_id IS NULL
UNION ALL SELECT 'courses -> clients',COUNT_BIG(*) FROM silver.courses c LEFT JOIN silver.clients x ON x.client_id=c.client_id WHERE x.client_id IS NULL
UNION ALL SELECT 'courses -> chauffeurs',COUNT_BIG(*) FROM silver.courses c LEFT JOIN silver.chauffeurs x ON x.chauffeur_id=c.chauffeur_id WHERE x.chauffeur_id IS NULL
UNION ALL SELECT 'courses -> vehicules',COUNT_BIG(*) FROM silver.courses c LEFT JOIN silver.vehicules x ON x.vehicule_id=c.vehicule_id WHERE x.vehicule_id IS NULL
UNION ALL SELECT 'courses -> tarification',COUNT_BIG(*) FROM silver.courses c LEFT JOIN silver.tarification x ON x.tarification_id=c.tarification_id WHERE x.tarification_id IS NULL
UNION ALL SELECT 'paiements -> courses',COUNT_BIG(*) FROM silver.paiements p LEFT JOIN silver.courses c ON c.course_id=p.course_id WHERE c.course_id IS NULL
UNION ALL SELECT 'avis -> courses',COUNT_BIG(*) FROM silver.avis_clients a LEFT JOIN silver.courses c ON c.course_id=a.course_id WHERE c.course_id IS NULL;
GO

PRINT '=== 4. REGLES METIER SILVER ===';
SELECT 'notes hors 1-5' controle, COUNT_BIG(*) anomalies FROM silver.avis_clients WHERE note_course NOT BETWEEN 1 AND 5 OR note_chauffeur NOT BETWEEN 1 AND 5
UNION ALL SELECT 'montants paiements negatifs',COUNT_BIG(*) FROM silver.paiements WHERE montant_du < 0 OR montant_paye < 0 OR solde_restant < 0
UNION ALL SELECT 'distance course <= 0',COUNT_BIG(*) FROM silver.courses WHERE distance_km <= 0
UNION ALL SELECT 'duree course <= 0',COUNT_BIG(*) FROM silver.courses WHERE duree_minutes <= 0
UNION ALL SELECT 'devise course <> XOF',COUNT_BIG(*) FROM silver.courses WHERE devise <> 'XOF'
UNION ALL SELECT 'devise paiement <> XOF',COUNT_BIG(*) FROM silver.paiements WHERE devise <> 'XOF'
UNION ALL SELECT 'solde incoherent',COUNT_BIG(*) FROM silver.paiements WHERE ABS((montant_du - montant_paye) - solde_restant) > 0.02;
GO

PRINT '=== 5. VOLUMES GOLD ===';
SELECT t.name table_name, SUM(p.rows) lignes
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id=t.schema_id
JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN (0,1)
WHERE s.name='gold'
GROUP BY t.name
ORDER BY t.name;
GO

PRINT '=== 6. COHERENCE KPI GLOBAL ===';
SELECT
    CASE WHEN nombre_societes=(SELECT COUNT_BIG(*) FROM silver.societes_transport) THEN 'OK' ELSE 'ECHEC' END societes,
    CASE WHEN nombre_clients=(SELECT COUNT_BIG(*) FROM silver.clients) THEN 'OK' ELSE 'ECHEC' END clients,
    CASE WHEN nombre_chauffeurs=(SELECT COUNT_BIG(*) FROM silver.chauffeurs) THEN 'OK' ELSE 'ECHEC' END chauffeurs,
    CASE WHEN nombre_vehicules=(SELECT COUNT_BIG(*) FROM silver.vehicules) THEN 'OK' ELSE 'ECHEC' END vehicules,
    CASE WHEN nombre_courses=(SELECT COUNT_BIG(*) FROM silver.courses) THEN 'OK' ELSE 'ECHEC' END courses,
    CASE WHEN nombre_avis=(SELECT COUNT_BIG(*) FROM silver.avis_clients) THEN 'OK' ELSE 'ECHEC' END avis
FROM gold.kpi_global;
GO

PRINT '=== 7. RESULTAT FINAL ===';
DECLARE @anomalies BIGINT = 0;
SELECT @anomalies = @anomalies + COUNT_BIG(*) FROM (SELECT client_id FROM silver.clients GROUP BY client_id HAVING COUNT(*)>1) x;
SELECT @anomalies = @anomalies + COUNT_BIG(*) FROM silver.courses c LEFT JOIN silver.clients x ON x.client_id=c.client_id WHERE x.client_id IS NULL;
SELECT @anomalies = @anomalies + COUNT_BIG(*) FROM silver.courses c LEFT JOIN silver.chauffeurs x ON x.chauffeur_id=c.chauffeur_id WHERE x.chauffeur_id IS NULL;
SELECT @anomalies = @anomalies + COUNT_BIG(*) FROM silver.courses c LEFT JOIN silver.vehicules x ON x.vehicule_id=c.vehicule_id WHERE x.vehicule_id IS NULL;
SELECT @anomalies = @anomalies + COUNT_BIG(*) FROM silver.paiements WHERE montant_du < 0 OR montant_paye < 0 OR solde_restant < 0;
SELECT @anomalies = @anomalies + COUNT_BIG(*) FROM silver.avis_clients WHERE note_course NOT BETWEEN 1 AND 5 OR note_chauffeur NOT BETWEEN 1 AND 5;
SELECT CASE WHEN @anomalies=0 THEN 'VALIDATION SQL SERVER : OK' ELSE CONCAT('VALIDATION SQL SERVER : ECHEC | anomalies=',@anomalies) END resultat;
GO
