from pathlib import Path

import pandas as pd
import pyarrow.parquet as pq
import pytest


# CONFIGURATION

BASE_DIR = Path(__file__).resolve().parent.parent
SILVER_DIR = BASE_DIR / "data" / "silver"
GOLD_DIR = BASE_DIR / "data" / "gold"

GOLD_FILES = {
    "kpi_global": "kpi_global.parquet",
    "kpi_courses": "kpi_courses.parquet",
    "kpi_paiements": "kpi_paiements.parquet",
    "kpi_satisfaction": "kpi_satisfaction.parquet",
    "kpi_tarification": "kpi_tarification.parquet",
    "top_chauffeurs": "top_chauffeurs.parquet",
    "top_societes": "top_societes.parquet",
    "courses_par_ville": "courses_par_ville.parquet",
    "revenus_par_ville": "revenus_par_ville.parquet",
    "performance_chauffeurs": "performance_chauffeurs.parquet",
    "experience_client": "experience_client.parquet",
}

VILLES = {"Dakar", "Thiès", "Mbour", "Diamniadio"}
CATEGORIES = {"Économique", "Confort", "Premium", "Familial"}


# OUTILS

def gold_path(nom):
    return GOLD_DIR / GOLD_FILES[nom]


def lire_gold(nom, colonnes=None):
    return pd.read_parquet(gold_path(nom), columns=colonnes)


def lire_silver(nom, colonnes=None):
    return pd.read_parquet(
        SILVER_DIR / f"{nom}_clean.parquet",
        columns=colonnes,
    )


# FICHIERS

@pytest.mark.parametrize("nom", GOLD_FILES)
def test_fichiers_gold_existent(nom):
    assert gold_path(nom).is_file(), f"Fichier Gold absent : {GOLD_FILES[nom]}"
    assert pq.read_metadata(gold_path(nom)).num_rows > 0


# KPI GLOBAL

def test_kpi_global_coherent_avec_silver():
    kpi = lire_gold("kpi_global").iloc[0]
    societes = lire_silver("societes_transport", ["societe_id"])
    clients = lire_silver("clients", ["client_id", "statut"])
    chauffeurs = lire_silver("chauffeurs", ["chauffeur_id", "statut"])
    vehicules = lire_silver("vehicules", ["vehicule_id"])
    courses = lire_silver(
        "courses",
        ["course_id", "statut_course", "distance_km", "duree_minutes"],
    )
    paiements = lire_silver(
        "paiements",
        ["montant_du", "montant_paye", "solde_restant"],
    )
    avis = lire_silver(
        "avis_clients",
        ["avis_id", "note_course", "note_chauffeur"],
    )

    terminees = courses[courses["statut_course"] == "Terminée"]
    annulees = courses[courses["statut_course"] == "Annulée"]

    assert kpi["nombre_societes"] == len(societes)
    assert kpi["nombre_clients"] == len(clients)
    assert kpi["clients_actifs"] == (clients["statut"] == "Actif").sum()
    assert kpi["nombre_chauffeurs"] == len(chauffeurs)
    assert kpi["chauffeurs_actifs"] == (chauffeurs["statut"] == "Actif").sum()
    assert kpi["nombre_vehicules"] == len(vehicules)
    assert kpi["nombre_courses"] == len(courses)
    assert kpi["courses_terminees"] == len(terminees)
    assert kpi["courses_annulees"] == len(annulees)
    assert kpi["nombre_avis"] == len(avis)
    assert kpi["montant_total_du"] == pytest.approx(paiements["montant_du"].sum(), abs=0.01)
    assert kpi["chiffre_affaires_encaisse"] == pytest.approx(
        paiements["montant_paye"].sum(), abs=0.01
    )
    assert kpi["solde_total_restant"] == pytest.approx(
        paiements["solde_restant"].sum(), abs=0.01
    )
    assert kpi["chiffre_affaires_encaisse"] <= kpi["montant_total_du"]


# KPI COURSES

def test_kpi_courses():
    df = lire_gold("kpi_courses")

    assert df["ville"].isin(VILLES).all()
    assert df["categorie"].isin(CATEGORIES).all()
    assert (df["nombre_courses"] > 0).all()
    assert (df["courses_terminees"] >= 0).all()
    assert (df["courses_annulees"] >= 0).all()
    assert (df["courses_terminees"] + df["courses_annulees"] <= df["nombre_courses"]).all()
    assert df["taux_annulation_pct"].between(0, 100).all()
    assert (df["distance_totale_km"] > 0).all()
    assert (df["distance_moyenne_km"] > 0).all()
    assert (df["duree_moyenne_minutes"] > 0).all()

    courses = lire_silver("courses", ["course_id"])
    assert df["nombre_courses"].sum() == len(courses)


# KPI PAIEMENTS

def test_kpi_paiements():
    df = lire_gold("kpi_paiements")
    silver = lire_silver(
        "paiements",
        ["paiement_id", "montant_du", "montant_paye", "solde_restant"],
    )

    assert (df["nombre_paiements"] > 0).all()
    assert (df["montant_du"] >= 0).all()
    assert (df["montant_paye"] >= 0).all()
    assert (df["solde_restant"] >= 0).all()
    assert (df["montant_paye"] <= df["montant_du"]).all()
    assert df["nombre_paiements"].sum() == len(silver)
    assert df["montant_du"].sum() == pytest.approx(silver["montant_du"].sum(), abs=0.05)
    assert df["montant_paye"].sum() == pytest.approx(silver["montant_paye"].sum(), abs=0.05)
    assert df["solde_restant"].sum() == pytest.approx(silver["solde_restant"].sum(), abs=0.05)


# SATISFACTION

def test_kpi_satisfaction():
    df = lire_gold("kpi_satisfaction")
    avis = lire_silver("avis_clients", ["avis_id"])

    assert (df["nombre_avis"] > 0).all()
    assert df["note_moyenne_course"].between(1, 5).all()
    assert df["note_moyenne_chauffeur"].between(1, 5).all()
    assert df["note_globale_moyenne"].between(1, 5).all()
    assert df["taux_satisfaction_pct"].between(0, 100).all()
    assert df["nombre_avis"].sum() == len(avis)


# TARIFICATION

def test_kpi_tarification():
    df = lire_gold("kpi_tarification")

    assert df["ville"].isin(VILLES).all()
    assert df["categorie"].isin(CATEGORIES).all()
    assert (df["prix_depart_moyen"] > 0).all()
    assert (df["prix_km_moyen"] > 0).all()
    assert (df["prix_minimum_moyen"] > 0).all()
    assert (df["distance_max_couverte_km"] > 0).all()


# CHAUFFEURS

def test_performance_chauffeurs():
    df = lire_gold("performance_chauffeurs")
    chauffeurs = lire_silver("chauffeurs", ["chauffeur_id"])

    assert len(df) == len(chauffeurs)
    assert df["chauffeur_id"].is_unique
    assert (df["nombre_courses"] >= 0).all()
    assert (df["distance_totale_km"] >= 0).all()
    assert (df["duree_totale_minutes"] >= 0).all()
    assert (df["revenu_genere"] >= 0).all()
    assert df.loc[df["note_moyenne_chauffeur"].notna(), "note_moyenne_chauffeur"].between(1, 5).all()


def test_top_chauffeurs():
    df = lire_gold("top_chauffeurs")

    assert (df["nombre_courses"] >= 20).all()
    assert df["note_moyenne_chauffeur"].between(1, 5).all()
    assert df.groupby(["ville", "nom_societe"]).size().le(10).all()


# SOCIÉTÉS

def test_top_societes():
    df = lire_gold("top_societes")

    assert len(df) == 4
    assert df["societe_id"].is_unique
    assert df["part_courses_pct"].sum() == pytest.approx(100.0, abs=0.05)
    assert df["taux_annulation_pct"].between(0, 100).all()
    assert (df["chiffre_affaires_encaisse"] <= df["montant_du"]).all()
    assert (df["solde_restant"] >= 0).all()
    assert df["note_globale_moyenne"].between(1, 5).all()


# VILLES ET REVENUS

def test_courses_par_ville():
    df = lire_gold("courses_par_ville")
    courses = lire_silver("courses", ["course_id"])

    assert df["ville"].isin(VILLES).all()
    assert df["categorie"].isin(CATEGORIES).all()
    assert df["nombre_courses"].sum() == len(courses)
    assert (df["distance_totale_km"] > 0).all()


def test_revenus_par_ville():
    df = lire_gold("revenus_par_ville")
    paiements = lire_silver(
        "paiements",
        ["montant_du", "montant_paye", "solde_restant"],
    )

    assert df["ville"].isin(VILLES).all()
    assert df["categorie"].isin(CATEGORIES).all()
    assert (df["montant_du"] >= 0).all()
    assert (df["chiffre_affaires_encaisse"] >= 0).all()
    assert (df["solde_restant"] >= 0).all()
    assert (df["chiffre_affaires_encaisse"] <= df["montant_du"]).all()
    assert df["montant_du"].sum() == pytest.approx(paiements["montant_du"].sum(), abs=0.05)
    assert df["chiffre_affaires_encaisse"].sum() == pytest.approx(
        paiements["montant_paye"].sum(), abs=0.05
    )


# EXPÉRIENCE CLIENT

def test_experience_client():
    df = lire_gold("experience_client")

    assert df["client_id"].notna().all()
    assert (df["nombre_avis"] > 0).all()
    assert df["note_moyenne_course"].between(1, 5).all()
    assert df["note_moyenne_chauffeur"].between(1, 5).all()
    assert df["note_globale_moyenne"].between(1, 5).all()
