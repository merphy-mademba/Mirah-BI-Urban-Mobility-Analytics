import json


FILES = {
    "societes": "societes_transport.json",
    "clients": "clients.json",
    "chauffeurs": "chauffeurs.json",
    "vehicules": "vehicules.json",
    "tarifs": "tarification.json",
    "courses": "courses.json",
    "paiements": "paiements.json",
    "avis": "avis_clients.json",
}


def iter_rows(path):
    with path.open("r", encoding="utf-8") as file:
        for line in file:
            if line.strip():
                yield json.loads(line)


def load_ids(path, key):
    return {row[key] for row in iter_rows(path)}


def test_reference_tables(bronze_dir):
    societes = load_ids(bronze_dir / FILES["societes"], "societe_id")
    clients = load_ids(bronze_dir / FILES["clients"], "client_id")
    chauffeurs = load_ids(bronze_dir / FILES["chauffeurs"], "chauffeur_id")
    vehicules = load_ids(bronze_dir / FILES["vehicules"], "vehicule_id")
    tarifs = load_ids(bronze_dir / FILES["tarifs"], "tarification_id")

    for row in iter_rows(bronze_dir / FILES["chauffeurs"]):
        assert row["societe_id"] in societes

    for row in iter_rows(bronze_dir / FILES["vehicules"]):
        assert row["chauffeur_id"] in chauffeurs
        assert row["societe_id"] in societes

    for row in iter_rows(bronze_dir / FILES["tarifs"]):
        assert row["societe_id"] in societes

    for row in iter_rows(bronze_dir / FILES["courses"]):
        assert row["societe_id"] in societes
        assert row["client_id"] in clients
        assert row["chauffeur_id"] in chauffeurs
        assert row["vehicule_id"] in vehicules
        assert row["tarification_id"] in tarifs


def test_course_children(bronze_dir):
    course_ids = load_ids(bronze_dir / FILES["courses"], "course_id")
    client_ids = load_ids(bronze_dir / FILES["clients"], "client_id")
    chauffeur_ids = load_ids(bronze_dir / FILES["chauffeurs"], "chauffeur_id")
    societe_ids = load_ids(bronze_dir / FILES["societes"], "societe_id")

    for row in iter_rows(bronze_dir / FILES["paiements"]):
        assert row["course_id"] in course_ids
        assert row["client_id"] in client_ids
        assert row["societe_id"] in societe_ids

    for row in iter_rows(bronze_dir / FILES["avis"]):
        assert row["course_id"] in course_ids
        assert row["client_id"] in client_ids
        assert row["chauffeur_id"] in chauffeur_ids
        assert row["societe_id"] in societe_ids
