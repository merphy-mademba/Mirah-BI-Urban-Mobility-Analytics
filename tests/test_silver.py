from pathlib import Path

import pandas as pd
import pyarrow.parquet as pq
import pytest


# CONFIGURATION

BASE_DIR = Path(__file__).resolve().parent.parent
SILVER_DIR = BASE_DIR / "data" / "silver"

VILLES = {
    "Dakar",
    "Thiès",
    "Mbour",
    "Diamniadio",
}

CATEGORIES = {
    "Économique",
    "Confort",
    "Premium",
    "Familial",
}

MODES_PAIEMENT = {
    "Wave",
    "Orange Money",
    "Free Money",
    "Espèces",
}

EXPECTED = {
    "societes_transport": {
        "file": "societes_transport_clean.parquet",
        "count": 4,
        "pk": "societe_id",
    },
    "clients": {
        "file": "clients_clean.parquet",
        "count": 100_000,
        "pk": "client_id",
    },
    "chauffeurs": {
        "file": "chauffeurs_clean.parquet",
        "count": 5_000,
        "pk": "chauffeur_id",
    },
    "vehicules": {
        "file": "vehicules_clean.parquet",
        "count": 5_000,
        "pk": "vehicule_id",
    },
    "tarification": {
        "file": "tarification_clean.parquet",
        "count": 256,
        "pk": "tarification_id",
    },
    "courses": {
        "file": "courses_clean.parquet",
        "count": 1_000_000,
        "pk": "course_id",
    },
    "paiements": {
        "file": "paiements_clean.parquet",
        "count": 1_000_000,
        "pk": "paiement_id",
    },
    "avis_clients": {
        "file": "avis_clients_clean.parquet",
        "count": 300_000,
        "pk": "avis_id",
    },
}


# OUTILS

def chemin_silver(nom):
    return SILVER_DIR / EXPECTED[nom]["file"]


def lire_silver(nom, columns=None):
    return pd.read_parquet(
        chemin_silver(nom),
        columns=columns,
    )


# FICHIERS

@pytest.mark.parametrize("nom", EXPECTED)
def test_fichier_silver_existe(nom):
    assert chemin_silver(nom).is_file(), (
        f"Fichier Silver absent : "
        f"{EXPECTED[nom]['file']}"
    )


@pytest.mark.parametrize("nom,config", EXPECTED.items())
def test_volumetrie_silver(nom, config):
    metadata = pq.read_metadata(
        chemin_silver(nom)
    )

    assert metadata.num_rows == config["count"], (
        f"{nom} : {metadata.num_rows:,} lignes "
        f"au lieu de {config['count']:,}"
    )


# CLÉS PRIMAIRES

@pytest.mark.parametrize("nom,config", EXPECTED.items())
def test_cles_primaires(nom, config):
    cle = config["pk"]

    df = lire_silver(
        nom,
        columns=[cle],
    )

    assert df[cle].notna().all(), (
        f"{nom}.{cle} contient des valeurs nulles"
    )

    assert df[cle].is_unique, (
        f"{nom}.{cle} contient des doublons"
    )


# COLONNE TECHNIQUE

@pytest.mark.parametrize("nom", EXPECTED)
def test_silver_processed_at(nom):
    schema = pq.read_schema(
        chemin_silver(nom)
    )

    assert "silver_processed_at" in schema.names


# CLIENTS

def test_clients():
    df = lire_silver(
        "clients",
        columns=[
            "client_id",
            "genre",
            "ville",
            "date_inscription",
        ],
    )

    assert df["ville"].isin(VILLES).all()
    assert df["genre"].isin({"F", "M"}).all()
    assert df["date_inscription"].notna().all()


# CHAUFFEURS

def test_chauffeurs():
    df = lire_silver(
        "chauffeurs",
        columns=[
            "chauffeur_id",
            "societe_id",
            "genre",
            "ville",
            "date_integration",
        ],
    )

    assert df["ville"].isin(VILLES).all()
    assert df["genre"].isin({"F", "M"}).all()
    assert df["date_integration"].notna().all()


# VÉHICULES

def test_vehicules():
    df = lire_silver(
        "vehicules",
        columns=[
            "vehicule_id",
            "chauffeur_id",
            "societe_id",
            "ville",
            "categorie",
            "annee",
        ],
    )

    assert df["ville"].isin(VILLES).all()
    assert df["categorie"].isin(CATEGORIES).all()
    assert df["annee"].between(
        2015,
        2026,
    ).all()


# TARIFICATION

def test_tarification():
    df = lire_silver(
        "tarification",
        columns=[
            "societe_id",
            "ville",
            "categorie",
            "distance_min_km",
            "distance_max_km",
            "prix_depart",
            "prix_km",
            "prix_minimum",
        ],
    )

    assert df["ville"].isin(VILLES).all()

    assert df["categorie"].isin(
        CATEGORIES
    ).all()

    assert (
        df["distance_min_km"] >= 0
    ).all()

    assert (
        df["distance_max_km"]
        >= df["distance_min_km"]
    ).all()

    assert (df["prix_depart"] >= 0).all()
    assert (df["prix_km"] >= 0).all()
    assert (df["prix_minimum"] >= 0).all()


# COURSES

def test_courses_regles_metier():
    colonnes = [
        "course_id",
        "societe_id",
        "client_id",
        "chauffeur_id",
        "vehicule_id",
        "tarification_id",
        "date_course",
        "ville",
        "point_depart",
        "point_arrivee",
        "distance_km",
        "duree_minutes",
        "categorie",
        "montant_course",
        "annee",
        "mois",
        "jour",
        "trimestre",
    ]

    fichier = chemin_silver("courses")

    for batch in pq.ParquetFile(
        fichier
    ).iter_batches(
        batch_size=100_000,
        columns=colonnes,
    ):
        df = batch.to_pandas()

        assert df["ville"].isin(
            VILLES
        ).all()

        assert df["categorie"].isin(
            CATEGORIES
        ).all()

        assert (
            df["point_depart"]
            != df["point_arrivee"]
        ).all()

        assert (
            df["distance_km"] > 0
        ).all()

        assert (
            df["duree_minutes"] > 0
        ).all()

        assert (
            df["montant_course"] >= 0
        ).all()

        assert df["date_course"].notna().all()

        assert (
            df["annee"]
            == df["date_course"].dt.year
        ).all()

        assert (
            df["mois"]
            == df["date_course"].dt.month
        ).all()

        assert (
            df["jour"]
            == df["date_course"].dt.day
        ).all()

        assert df["trimestre"].between(
            1,
            4,
        ).all()


# PAIEMENTS

def test_paiements(): 
    colonnes = [ 
        "paiement_id", 
        "course_id", 
        "societe_id", 
        "client_id", 
        "montant_du", 
        "montant_paye", 
        "solde_restant", 
        "mode_paiement", 
        "date_paiement", 
        "statut_paiement", 
    ] 
    
    for batch in pq.ParquetFile(
        chemin_silver("paiements")
    ).iter_batches( 
        batch_size=100_000, 
        columns=colonnes, 
    ): 
        
        df = batch.to_pandas() 
        
        assert df["mode_paiement"].isin(
            MODES_PAIEMENT 
        ).all() 
        
        assert ( 
            df["montant_du"] >= 0 
        ).all() 
        
        assert (
            df["montant_paye"] >= 0 
        ).all() 
        
        assert (
            df["solde_restant"] >= 0 
        ).all() 
        
        assert (
            df["montant_paye"] 
            <= df["montant_du"] 
        ).all() 
        
        solde_attendu = (
            df["montant_du"] 
            - df["montant_paye"] 
        ).round(2) 
        
        assert (
            df["solde_restant"].round(2) 
            == solde_attendu 
        ).all() 
        
        paiements_reussis = (
            df["statut_paiement"] 
            == "Réussi" 
        ) 
        
        assert ( 
            df.loc[ 
                paiements_reussis, 
                "montant_paye", 
            ] 
            == df.loc[ 
                paiements_reussis, 
                "montant_du", 
            ] 
        ).all() 
        
        assert (
            df.loc[
                paiements_reussis, 
                "solde_restant",
            ] 
            == 0 
        ).all() 
        
        paiements_non_reussis = (
            df["statut_paiement"] 
            .isin(
                {  
                    "En attente", 
                    "Annulé", 
                } 
            ) 
        ) 
        
        assert (
            df.loc[
                paiements_non_reussis, 
                "montant_paye",
                ] 
            == 0 
            ).all() 
        
        assert df[ 
                "date_paiement"
            ].notna().all()


# AVIS CLIENTS

def test_avis_clients():
    colonnes = [
        "avis_id",
        "course_id",
        "client_id",
        "chauffeur_id",
        "note_course",
        "note_chauffeur",
        "note_globale",
        "date_avis",
    ]

    for batch in pq.ParquetFile(
        chemin_silver("avis_clients")
    ).iter_batches(
        batch_size=100_000,
        columns=colonnes,
    ):
        df = batch.to_pandas()

        assert df["note_course"].between(
            1,
            5,
        ).all()

        assert df["note_chauffeur"].between(
            1,
            5,
        ).all()

        note_attendue = (
            (
                df["note_course"]
                + df["note_chauffeur"]
            )
            / 2
        ).round(2)

        assert (
            df["note_globale"]
            == note_attendue
        ).all()

        assert df["date_avis"].notna().all()


# INTÉGRITÉ RÉFÉRENTIELLE

def test_integrite_referentielle_silver():
    societes = set(
        lire_silver(
            "societes_transport",
            ["societe_id"],
        )["societe_id"]
    )

    clients = set(
        lire_silver(
            "clients",
            ["client_id"],
        )["client_id"]
    )

    chauffeurs = set(
        lire_silver(
            "chauffeurs",
            ["chauffeur_id"],
        )["chauffeur_id"]
    )

    vehicules = set(
        lire_silver(
            "vehicules",
            ["vehicule_id"],
        )["vehicule_id"]
    )

    tarifs = set(
        lire_silver(
            "tarification",
            ["tarification_id"],
        )["tarification_id"]
    )

    colonnes = [
        "societe_id",
        "client_id",
        "chauffeur_id",
        "vehicule_id",
        "tarification_id",
    ]

    for batch in pq.ParquetFile(
        chemin_silver("courses")
    ).iter_batches(
        batch_size=100_000,
        columns=colonnes,
    ):
        df = batch.to_pandas()

        assert df["societe_id"].isin(
            societes
        ).all()

        assert df["client_id"].isin(
            clients
        ).all()

        assert df["chauffeur_id"].isin(
            chauffeurs
        ).all()

        assert df["vehicule_id"].isin(
            vehicules
        ).all()

        assert df["tarification_id"].isin(
            tarifs
        ).all()


# RELATION PAIEMENTS / COURSES

def test_paiements_courses():
    course_ids = set(
        lire_silver(
            "courses",
            ["course_id"],
        )["course_id"]
    )

    for batch in pq.ParquetFile(
        chemin_silver("paiements")
    ).iter_batches(
        batch_size=100_000,
        columns=["course_id"],
    ):
        df = batch.to_pandas()

        assert df["course_id"].isin(
            course_ids
        ).all()


# RELATION AVIS / COURSES

def test_avis_courses():
    course_ids = set(
        lire_silver(
            "courses",
            ["course_id"],
        )["course_id"]
    )

    for batch in pq.ParquetFile(
        chemin_silver("avis_clients")
    ).iter_batches(
        batch_size=100_000,
        columns=["course_id"],
    ):
        df = batch.to_pandas()

        assert df["course_id"].isin(
            course_ids
        ).all()