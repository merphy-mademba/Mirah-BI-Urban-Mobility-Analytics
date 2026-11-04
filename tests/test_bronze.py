import json

import pytest


EXPECTED = {
    "societes_transport.json": {
        "count": 4,
        "primary_key": "societe_id",
        "required": {
            "societe_id", "nom_societe", "date_lancement", "statut",
            "villes_operation", "source_system", "batch_id", "ingested_at",
        },
    },
    "clients.json": {
        "count": 100_000,
        "primary_key": "client_id",
        "required": {
            "client_id", "nom", "genre", "origine_nom_synthetique",
            "telephone", "ville", "date_inscription", "statut",
            "source_system", "batch_id", "ingested_at",
        },
    },
    "chauffeurs.json": {
        "count": 5_000,
        "primary_key": "chauffeur_id",
        "required": {
            "chauffeur_id", "societe_id", "nom", "genre",
            "origine_nom_synthetique", "telephone", "ville",
            "date_integration", "statut", "source_system", "batch_id",
            "ingested_at",
        },
    },
    "vehicules.json": {
        "count": 5_000,
        "primary_key": "vehicule_id",
        "required": {
            "vehicule_id", "chauffeur_id", "societe_id", "ville", "marque",
            "modele", "annee", "immatriculation", "categorie", "statut",
            "source_system", "batch_id", "ingested_at",
        },
    },
    "tarification.json": {
        "count": 256,
        "primary_key": "tarification_id",
        "required": {
            "tarification_id", "societe_id", "ville", "categorie",
            "distance_min_km", "distance_max_km", "prix_depart", "prix_km",
            "prix_minimum", "devise", "date_effet", "statut",
            "source_system", "batch_id", "ingested_at",
        },
    },
    "courses.json": {
        "count": 1_000_000,
        "primary_key": "course_id",
        "required": {
            "course_id", "societe_id", "client_id", "chauffeur_id",
            "vehicule_id", "tarification_id", "date_course", "heure_course",
            "annee", "mois", "ville", "point_depart", "point_arrivee",
            "distance_km", "duree_minutes", "categorie", "marque_vehicule",
            "montant_course", "devise", "statut_course", "source_system",
            "batch_id", "ingested_at",
        },
    },
    "paiements.json": {
    "count": 1_000_000,
    "primary_key": "paiement_id",
    "required": {
        "paiement_id", "course_id", "societe_id", "client_id", "montant_du",
        "montant_paye", "solde_restant", "devise", "mode_paiement", "date_paiement",
        "statut_paiement", "source_system", "batch_id", "ingested_at",
        },
    },
    "avis_clients.json": {
        "count": 300_000,
        "primary_key": "avis_id",
        "required": {
            "avis_id", "course_id", "societe_id", "client_id", "chauffeur_id",
            "note_course", "note_chauffeur", "commentaire", "date_avis",
            "source_system", "batch_id", "ingested_at",
        },
    },
}


def iter_jsonl(path):
    with path.open("r", encoding="utf-8") as file:
        for line_number, line in enumerate(file, start=1):
            if not line.strip():
                continue
            try:
                yield line_number, json.loads(line)
            except json.JSONDecodeError as error:
                pytest.fail(f"JSON invalide dans {path.name}, ligne {line_number}: {error}")


@pytest.mark.parametrize("filename", EXPECTED)
def test_bronze_file_exists(bronze_dir, filename):
    assert (bronze_dir / filename).is_file(), f"Fichier manquant : {filename}"


@pytest.mark.parametrize("filename,config", EXPECTED.items())
def test_bronze_volume_schema_and_primary_key(bronze_dir, filename, config):
    path = bronze_dir / filename
    primary_key = config["primary_key"]
    expected_columns = config["required"]
    seen_keys = set()
    count = 0

    for line_number, row in iter_jsonl(path):
        count += 1
        missing = expected_columns - row.keys()
        assert not missing, (
            f"{filename}, ligne {line_number}: colonnes manquantes {sorted(missing)}"
        )

        key = row.get(primary_key)
        assert key is not None, f"{filename}, ligne {line_number}: clé nulle"
        assert key not in seen_keys, f"{filename}: clé dupliquée {primary_key}={key}"
        seen_keys.add(key)

    assert count == config["count"], (
        f"{filename}: {count:,} lignes au lieu de {config['count']:,}"
    )
