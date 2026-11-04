from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def project_root():
    return Path(__file__).resolve().parent.parent


@pytest.fixture(scope="session")
def bronze_dir(project_root):
    path = project_root / "data" / "bronze"
    assert path.exists(), f"Dossier Bronze introuvable : {path}"
    return path
