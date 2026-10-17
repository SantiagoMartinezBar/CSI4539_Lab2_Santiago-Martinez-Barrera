# CSI4539 — Laboratoire 2

Ce dépôt regroupe les fichiers utilisés pour le laboratoire portant sur les erreurs de mémoire, l'analyse de programmes vulnérables et la défense par le typage.

Les sources SEED fournies avec le laboratoire sont conservées séparément dans `materials/`. Le reste du dépôt est organisé afin de distinguer clairement le code défensif, le corpus de tests, les traces expérimentales, le journal de travail et le rapport.

## Préparation et vérification

La préparation du dépôt et les vérifications automatisées peuvent être lancées depuis la racine avec :

```sh
make setup
```

Cette commande utilise un conteneur Debian temporaire afin d'obtenir un environnement de compilation reproductible sans dépendre directement des paquets installés sur la machine hôte.

Elle effectue notamment les opérations suivantes :

- installation des outils de compilation nécessaires dans le conteneur;
- compilation de la routine Ada;
- génération du corpus de tests;
- vérification du comportement aux limites de 100 et 101 octets;
- génération du rapport au format PDF.

Les programmes vulnérables fournis dans les archives SEED restent séparés de cette procédure de vérification.

Lors du premier lancement, un accès réseau peut être nécessaire afin de télécharger les paquets requis par le conteneur.

Les principales étapes peuvent également être exécutées séparément :

```sh
make verify-safe
make report
```

## Défense par le typage

Le dossier `defense/` contient une implémentation Ada utilisant des types et sous-types bornés afin de représenter explicitement la capacité du tampon.

La routine limite les données acceptées à 100 octets. Une entrée dépassant cette taille est détectée avant la copie dans le tampon borné et provoque un rejet contrôlé.

Deux cas limites sont notamment utilisés pendant la vérification :

- une entrée de 100 octets est acceptée;
- une entrée de 101 octets est rejetée proprement.

La gestion de `Constraint_Error` permet également de conserver un comportement contrôlé lorsque les contraintes définies par les types ne sont pas respectées.

## Corpus de tests

Le dossier `corpus/` contient huit entrées de test inertes correspondant à différentes tailles utiles pour les expériences du laboratoire.

Ces fichiers couvrent notamment les valeurs situées autour de la limite du tampon ainsi que plusieurs tailles associées aux scénarios étudiés dans les exercices SEED.

Le corpus permet de conserver des entrées reproductibles plutôt que de recréer manuellement les mêmes données à chaque exécution.

## Traces expérimentales

Le dossier `traces/` est utilisé pour regrouper les résultats produits pendant les différentes expériences du laboratoire.

Les traces y sont séparées selon les essais T1 à T8 afin de conserver les sorties de débogage, les observations sur les protections mémoire, les désassemblages et les résultats associés aux programmes étudiés.

Cette organisation permet de relier plus facilement les résultats expérimentaux aux sections correspondantes du rapport.

## Organisation du dépôt

| Chemin | Contenu |
|---|---|
| `materials/` | Sources SEED et fichiers fournis avec le laboratoire |
| `defense/` | Routine Ada utilisant des types bornés |
| `corpus/` | Entrées de test reproductibles |
| `traces/` | Résultats et traces des expériences T1 à T8 |
| `report/` | Sources du rapport et version PDF générée |
| `JOURNAL.md` | Journal des décisions, séances et contributions |
| `Makefile` | Commandes de préparation, vérification et génération du rapport |

## Rapport

Le dossier `report/` contient le rapport principal du laboratoire ainsi que les fichiers nécessaires à sa génération.

Le rapport couvre notamment :

- l'organisation de la pile;
- les débordements de tampon;
- le shellcode;
- les mécanismes ASLR, StackGuard et NX;
- l'approche return-to-libc;
- l'analyse avec GDB et `objdump`;
- l'influence des options de compilation;
- la défense par le typage en Ada;
- l'extension du scénario vers le serveur fourni.

Le PDF peut être régénéré à l'aide de :

```sh
make report
```
