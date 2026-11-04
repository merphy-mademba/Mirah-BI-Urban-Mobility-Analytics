# Rapport de validation Bronze

- Projet : MIRAH-BI Urban Mobility Analytics Sénégal
- Généré le : 2026-10-28T12:37:37
- Statut global des tests : **VALIDÉ**

## Volumétrie

| Fichier | Attendu | Obtenu | Statut |
|---|---:|---:|---|
| `societes_transport.json` | 4 | 4 | OK |
| `clients.json` | 100,000 | 100,000 | OK |
| `chauffeurs.json` | 5,000 | 5,000 | OK |
| `vehicules.json` | 5,000 | 5,000 | OK |
| `tarification.json` | 256 | 256 | OK |
| `courses.json` | 1,000,000 | 1,000,000 | OK |
| `paiements.json` | 1,000,000 | 1,000,000 | OK |
| `avis_clients.json` | 300,000 | 300,000 | OK |

## Contrôles exécutés

- Présence et lisibilité des fichiers JSON Lines
- Volumétrie attendue
- Présence des colonnes obligatoires
- Unicité et non-nullité des clés primaires
- Intégrité référentielle
- Cohérence des villes, sociétés, chauffeurs, véhicules et tarifs
- Règles métier des courses, paiements et avis

## Résultat Pytest

```text
.....................                                                    [100%]
21 passed in 108.89s (0:01:48)
```
