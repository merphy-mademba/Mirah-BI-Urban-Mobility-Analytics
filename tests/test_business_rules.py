import json
from datetime import datetime


VILLES = {"Dakar", "Thiès", "Mbour", "Diamniadio"}
CATEGORIES = {"Économique", "Confort", "Premium", "Familial"}
MODES_PAIEMENT = {"Wave", "Orange Money", "Free Money", "Espèces"}
STATUTS_COURSE = {"Terminée", "Annulée", "En cours"}


def iter_rows(path):
    with path.open("r", encoding="utf-8") as file:
        for line in file:
            if line.strip():
                yield json.loads(line)


def load_map(path, key, fields):
    return {
        row[key]: {field: row[field] for field in fields}
        for row in iter_rows(path)
    }


def test_course_city_and_entity_consistency(bronze_dir):
    clients = load_map(
        bronze_dir / "clients.json", "client_id", ["ville", "date_inscription"]
    )
    chauffeurs = load_map(
        bronze_dir / "chauffeurs.json",
        "chauffeur_id",
        ["ville", "societe_id", "date_integration"],
    )
    vehicules = load_map(
        bronze_dir / "vehicules.json",
        "vehicule_id",
        ["ville", "societe_id", "chauffeur_id", "categorie", "marque"],
    )
    tarifs = load_map(
        bronze_dir / "tarification.json",
        "tarification_id",
        ["ville", "societe_id", "categorie", "distance_min_km", "distance_max_km"],
    )

    for row in iter_rows(bronze_dir / "courses.json"):
        client = clients[row["client_id"]]
        chauffeur = chauffeurs[row["chauffeur_id"]]
        vehicule = vehicules[row["vehicule_id"]]
        tarif = tarifs[row["tarification_id"]]

        assert row["ville"] in VILLES
        assert row["ville"] == client["ville"]
        assert row["ville"] == chauffeur["ville"] == vehicule["ville"] == tarif["ville"]
        assert row["societe_id"] == chauffeur["societe_id"]
        assert row["societe_id"] == vehicule["societe_id"] == tarif["societe_id"]
        assert row["chauffeur_id"] == vehicule["chauffeur_id"]
        assert row["categorie"] == vehicule["categorie"] == tarif["categorie"]
        assert row["marque_vehicule"] == vehicule["marque"]
        assert row["point_depart"] != row["point_arrivee"]
        assert row["distance_km"] > 0
        assert row["duree_minutes"] > 0
        assert row["montant_course"] >= 0
        assert row["categorie"] in CATEGORIES
        assert row["statut_course"] in STATUTS_COURSE
        assert tarif["distance_min_km"] <= row["distance_km"] <= tarif["distance_max_km"]

        date_course = datetime.fromisoformat(row["date_course"])
        assert date_course.date() >= datetime.fromisoformat(client["date_inscription"]).date()
        assert date_course.date() >= datetime.fromisoformat(chauffeur["date_integration"]).date()

        if row["statut_course"] == "Annulée":
            assert row["montant_course"] == 0


def test_payment_rules(bronze_dir):
    courses = load_map(
        bronze_dir / "courses.json",
        "course_id",
        ["statut_course", "montant_course", "societe_id", "client_id"],
    )

    for payment in iter_rows(bronze_dir / "paiements.json"):
        course = courses[payment["course_id"]]
        assert payment["mode_paiement"] in MODES_PAIEMENT
        assert payment["societe_id"] == course["societe_id"]
        assert payment["client_id"] == course["client_id"]
        assert payment["montant_du"] >= 0
        assert payment["montant_paye"] >= 0
        assert payment["solde_restant"] >= 0

        assert payment["montant_paye"] <= payment["montant_du"]

        assert payment["solde_restant"] == round(
            payment["montant_du"] - payment["montant_paye"],
            2,
    )

        if payment["statut_paiement"] == "Réussi":
            assert course["statut_course"] == "Terminée"
            assert payment["montant_du"] == course["montant_course"]
            assert payment["montant_paye"] == course["montant_course"]
            assert payment["solde_restant"] == 0

        elif payment["statut_paiement"] in {"En attente",}:
            assert payment["montant_paye"] == 0

        elif payment["statut_paiement"] == "Annulé":
            assert course["statut_course"] == "Annulée"
            assert payment["montant_du"] == 0
            assert payment["montant_paye"] == 0
            assert payment["solde_restant"] == 0


def test_review_rules(bronze_dir):
        courses = load_map(
            bronze_dir / "courses.json",
            "course_id",
        ["statut_course", "societe_id", "client_id", "chauffeur_id", "date_course"],
    )

        for review in iter_rows(bronze_dir / "avis_clients.json"):
            course = courses[review["course_id"]]
            assert course["statut_course"] == "Terminée"
            assert review["societe_id"] == course["societe_id"]
            assert review["client_id"] == course["client_id"]
            assert review["chauffeur_id"] == course["chauffeur_id"]
            assert 1 <= review["note_course"] <= 5
            assert 1 <= review["note_chauffeur"] <= 5
            assert datetime.fromisoformat(review["date_avis"]).date() >= datetime.fromisoformat(
            course["date_course"]).date()
