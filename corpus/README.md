# Corpus d'entrées mémoire

J'utilise ce corpus pour vérifier les bornes sans exécuter de charge utile. Je conserve chaque cas comme un fichier distinct afin de pouvoir le rejouer avec la routine Ada et avec les programmes du laboratoire dans l'environnement SEED isolé.

| Fichier | Intention | Résultat que je vérifie avec la défense Ada |
|---|---|---|
| `01-short.txt` | Entrée normale courte | Je vérifie qu'elle est acceptée. |
| `02-format-markers.txt` | Marqueurs de format non fiables | Je vérifie qu'ils restent des données ordinaires. |
| `03-boundary-99.txt` | Valeur juste sous la limite | Je vérifie qu'elle est acceptée. |
| `04-boundary-100.txt` | Valeur à la limite | Je vérifie qu'elle est acceptée. |
| `05-overflow-101.txt` | Premier octet hors limite | Je vérifie qu'un `Constraint_Error` est traité. |
| `06-overflow-160.txt` | Taille du niveau local L2 | Je vérifie un rejet sûr. |
| `07-overflow-200.txt` | Taille d'un niveau 64 bits | Je vérifie un rejet sûr. |
| `08-overflow-517.txt` | Taille maximale lue par `stack.c` | Je vérifie un rejet sûr. |

Je génère les fichiers sans fin de ligne avec `python3 corpus/generate.py`. Les nombres dans les noms correspondent donc exactement au nombre d'octets. Je garde les charges inertes : elles couvrent des limites et des marqueurs de format, mais elles ne contiennent ni shellcode ni adresse de retour.
