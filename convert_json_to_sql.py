import json

input_file = 'commandes.json'
output_file = 'commandes_insert.sql'

batch_size = 1000  # Regrouper par lots pour optimiser la taille et la vitesse
batch = []

with open(output_file, 'w', encoding='utf-8') as f_out:
f_out.write('BEGIN;\n')
f_out.write(
    'INSERT INTO commandes (commande_id, restaurant_id, client_id, montant,'
    ' devise, statut_commande, canal_commande, date_commande) VALUES\n'
)

with open(input_file, 'r', encoding='utf-8') as f_in:
    first = True
    for line in f_in:
    obj = json.loads(line)
    val_str = (
        f"({obj['commande_id']}, {obj['restaurant_id']},"
        f" {obj['client_id']}, {obj['montant']}, '{obj['devise']}',"
        f" '{obj['statut_commande']}', '{obj['canal_commande']}',"
        f" '{obj['date_commande']}')"
    )
    batch.append(val_str)

    if len(batch) >= batch_size:
        f_out.write(',\n'.join(batch) + ';\n')
        batch = []
        f_out.write('INSERT INTO commandes (...) VALUES\n')  # Répéter si besoin

    if batch:
    f_out.write(',\n'.join(batch) + ';\n')

f_out.write('COMMIT;\n')