---
title: "Laboratoire 2 — Attaques mémoire et défense par le typage"
author: "Santiago Martinez Barrera"
date: "16 octobre 2026"
geometry: margin=2.3cm
papersize: a4
fontsize: 11pt
colorlinks: true
header-includes:
  - |
    ```{=latex}
    \usepackage{longtable}
    \usepackage{booktabs}
    \usepackage{graphicx}
    ```
---

# 1. Introduction et modèle de menace

Ce laboratoire porte sur les vulnérabilités de mémoire dans les programmes C, principalement les débordements de tampon sur la pile, ainsi que sur plusieurs techniques permettant d'en comprendre l'exploitation et les contre-mesures.

Toutes les manipulations sont limitées aux programmes fournis dans le cadre du cours et à l'environnement SEED ou aux conteneurs isolés associés au laboratoire. Aucun essai n'est dirigé vers un système externe.

Les principaux éléments à protéger sont l'intégrité du flot d'exécution, les données présentes dans la mémoire du processus, les privilèges associés au programme et la disponibilité du service. Dans les différents scénarios étudiés, `badfile`, l'entrée standard ainsi que les données reçues par le serveur TCP doivent être considérés comme des entrées non fiables.

La cause principale du débordement étudié dans ce laboratoire est l'utilisation d'une copie non bornée. Une fonction comme `strcpy` ne connaît pas la capacité du tampon de destination. Si la chaîne source dépasse cette capacité, la copie continue au-delà du tampon et peut modifier d'autres éléments du cadre de pile, notamment les données de contrôle utilisées lorsque la fonction retourne.

Le laboratoire permet donc d'étudier non seulement la vulnérabilité elle-même, mais également les différentes conditions nécessaires pour la rendre exploitable et l'effet de mécanismes comme ASLR, StackGuard et NX.

# 2. Organisation de la pile et contre-mesures

## 2.1 Cadre d'appel et débordement de pile

Lorsqu'une fonction C est appelée, un cadre de pile est créé afin de stocker ses variables locales ainsi que les informations nécessaires au retour vers la fonction appelante.

Un tampon local déclaré dans cette fonction est donc situé dans le même cadre de pile que plusieurs données sensibles au contrôle du programme. Si une opération de copie dépasse les limites du tampon, les octets supplémentaires peuvent atteindre ces données.

L'analyse avec GDB sert à déterminer précisément l'organisation du cadre de pile du binaire utilisé. Les éléments particulièrement importants sont :

- l'adresse du début du tampon;
- la position du pointeur de cadre;
- la position de l'adresse de retour sauvegardée;
- la distance entre le début du tampon et les données de contrôle.

Cette distance est essentielle puisqu'elle détermine la quantité de données nécessaire avant d'atteindre l'adresse de retour.

Il est important de ne pas considérer cette valeur comme universelle. Elle dépend notamment de l'architecture, du compilateur, des options de compilation et du code exact du programme. Pour cette raison, une valeur obtenue sur une machine ne doit pas simplement être réutilisée sur une autre.

## 2.2 Effet des mécanismes de protection

Plusieurs protections courantes modifient directement la faisabilité d'une exploitation mémoire.

### ASLR

ASLR, ou Address Space Layout Randomization, modifie l'emplacement de différentes régions mémoire entre les exécutions.

Une exploitation qui dépend d'une adresse constante devient donc beaucoup moins fiable puisque cette adresse peut changer lorsque le programme est relancé.

ASLR ne corrige cependant pas le débordement. La copie hors limites existe toujours; ce sont principalement les hypothèses faites sur les adresses qui deviennent moins prévisibles.

### StackGuard

StackGuard ajoute une valeur de contrôle, généralement appelée canari, entre certaines variables locales et les données de contrôle de la pile.

Avant que la fonction retourne, cette valeur est vérifiée. Si elle a été modifiée, le programme peut détecter qu'une corruption de pile a eu lieu et s'arrêter avant d'utiliser une adresse de retour potentiellement altérée.

Il s'agit donc d'un mécanisme de détection qui rend plus difficile la modification silencieuse du flot de contrôle.

### NX

NX permet de marquer certaines régions mémoire comme non exécutables.

Dans le cas d'une pile non exécutable, il est toujours possible qu'une vulnérabilité permette d'y écrire des données, mais le processeur refuse normalement d'interpréter directement ces données comme des instructions.

Cette protection réduit donc l'efficacité des attaques reposant sur l'exécution directe de code placé dans la pile.

Elle ne supprime cependant pas la possibilité de rediriger le flot d'exécution vers du code qui existe déjà ailleurs dans le processus.

### Shell et privilèges

Dans un environnement Set-UID, le comportement du shell appelé par un programme est également important.

Certains shells réduisent volontairement leurs privilèges lorsqu'ils détectent qu'ils sont lancés dans un contexte privilégié. Cela peut empêcher qu'une exploitation conserve automatiquement les privilèges du programme vulnérable.

Cette distinction explique pourquoi le comportement observé peut varier selon le shell utilisé dans l'environnement.

# 3. Exploitation des vulnérabilités mémoire

## 3.1 Shellcode

Le shellcode constitue une petite séquence d'instructions directement représentée sous forme d'octets machine.

Les variantes 32 bits et 64 bits ne sont pas interchangeables puisque l'architecture influence les registres disponibles, la convention d'appel et la façon dont les appels système sont effectués.

Dans le cadre de ce laboratoire, une attention particulière doit également être portée aux octets nuls.

Les fonctions de manipulation de chaînes C interprètent `0x00` comme un terminateur. La présence d'un octet nul dans une charge utile peut donc provoquer l'arrêt prématuré d'une copie effectuée avec une fonction comme `strcpy`.

Le shellcode doit donc être analysé non seulement comme un programme assembleur, mais également comme une séquence d'octets devant survivre aux fonctions utilisées pour transporter cette séquence jusqu'au tampon vulnérable.

## 3.2 Débordements locaux N1 à N3

Les exercices N1 à N3 illustrent plusieurs variantes d'un même problème : une entrée contrôlée dépasse la taille disponible dans un tampon local.

L'objectif principal n'est pas seulement de produire une entrée longue, mais de comprendre exactement où chaque partie de cette entrée se retrouve dans la pile.

Une charge utile de débordement peut être divisée conceptuellement en plusieurs parties :

1. les données qui remplissent le tampon;
2. les données qui couvrent l'espace situé entre le tampon et les informations de contrôle;
3. la valeur qui remplace les données utilisées par le flot d'exécution;
4. les données supplémentaires nécessaires au scénario étudié.

Le niveau N2 ajoute une difficulté supplémentaire puisque certaines informations ne sont pas directement connues.

Dans ce cas, il faut raisonner à partir des propriétés observables du programme plutôt que simplement recopier une valeur prédéterminée.

Ces exercices démontrent qu'un débordement de tampon exploitable dépend fortement de la disposition réelle de la mémoire.

Une différence relativement faible dans la taille d'un cadre de pile, les options de compilation ou l'architecture peut suffire à rendre une charge utile construite pour un autre environnement inutilisable.

## 3.3 Return-to-libc

L'approche return-to-libc est particulièrement utile pour comprendre les limites d'une protection comme NX.

Si la pile ne peut pas être exécutée, une stratégie consistant simplement à y placer du code puis à transférer l'exécution vers ce code peut échouer.

Return-to-libc utilise une autre approche : plutôt que d'exécuter de nouvelles instructions placées dans une zone de données, le flot de contrôle est redirigé vers des fonctions qui sont déjà présentes dans l'espace mémoire du processus.

L'exploitation repose donc toujours sur la corruption du flot de contrôle, mais elle n'exige pas nécessairement que la pile soit exécutable.

Cette distinction montre pourquoi NX est une protection importante mais pas suffisante à elle seule.

La vulnérabilité fondamentale reste la capacité d'écrire au-delà de la limite d'un objet mémoire et d'atteindre des données utilisées pour contrôler l'exécution.

# 4. Analyse avec les outils de bas niveau

## 4.1 Désassemblage avec objdump

`objdump` permet d'observer la représentation assembleur du programme compilé et de relier les instructions du code source aux instructions réellement exécutées par le processeur.

Dans une fonction vulnérable, trois régions sont particulièrement intéressantes.

### Prologue

Le prologue prépare le cadre de pile utilisé par la fonction.

Selon l'architecture et les options de compilation, il peut notamment sauvegarder un ancien pointeur de cadre et réserver de l'espace pour les variables locales.

### Appel de la fonction de copie

Le désassemblage permet ensuite d'identifier le passage des arguments et l'appel à la fonction responsable de la copie non bornée.

Cette observation est importante puisque le code assembleur montre ce que le programme fait réellement après compilation, indépendamment de la représentation plus abstraite du code C.

### Épilogue et retour

À la fin de la fonction, l'épilogue restaure l'état du cadre d'appel avant d'exécuter le retour vers la fonction appelante.

C'est précisément à cette étape qu'une adresse de retour corrompue devient pertinente.

## 4.2 Influence des options de compilation

Les options de compilation peuvent changer de manière importante la structure du programme obtenu.

### Protection de pile

Lorsqu'une protection de pile est activée, du code supplémentaire apparaît afin de créer puis vérifier un canari.

Sans cette protection, cette vérification supplémentaire n'est pas présente.

### Optimisation

Une compilation avec `-O0` conserve généralement une structure plus directement associée au code source, ce qui facilite souvent l'analyse pédagogique.

Avec `-O2`, le compilateur peut réorganiser ou supprimer certaines opérations, utiliser les registres différemment et modifier la structure du cadre de pile.

Le même programme C peut donc produire un désassemblage sensiblement différent selon le niveau d'optimisation.

### Pile exécutable et NX

L'état exécutable de la pile modifie directement le type de stratégie qui peut être utilisé.

Une pile exécutable permet théoriquement l'exécution directe d'instructions placées dans cette région, tandis que NX empêche cette utilisation et pousse vers des techniques réutilisant du code déjà présent.

# 5. Défense par le typage

Une version défensive en Ada a également été ajoutée afin de comparer l'approche d'un langage permettant de représenter plus explicitement certaines limites.

Le tampon est représenté par un type dont les index valides vont de 1 à 100.

La longueur courante utilise un sous-type limité aux valeurs comprises entre 0 et 100.

Cette conception permet de représenter directement certaines propriétés que le programme C vulnérable ne faisait pas respecter.

Les propriétés principales sont les suivantes :

1. `Length` reste toujours entre 0 et 100;
2. `Data` n'est indexé qu'avec un index appartenant au domaine prévu;
3. une entrée dépassant 100 octets est rejetée avant la copie;
4. le fichier est fermé même si une exception survient;
5. une entrée invalide provoque un code de sortie d'échec exploitable par les tests automatisés.

Deux cas limites ont été vérifiés.

L'entrée `corpus/04-boundary-100.txt`, qui contient exactement 100 octets, est acceptée.

L'entrée `corpus/05-overflow-101.txt`, qui contient 101 octets, est rejetée proprement avant qu'une copie hors limites puisse avoir lieu.

Le comportement obtenu illustre directement la différence entre une frontière mémoire implicite et une frontière représentée dans les types et contrôlée avant l'opération sensible.

Cette approche ne signifie toutefois pas qu'un programme Ada est automatiquement sécurisé.

Il reste nécessaire de vérifier les conversions, les appels à des bibliothèques externes, les allocations et les différentes interfaces d'entrée.

Le principal avantage montré ici est que certaines contraintes peuvent être intégrées directement à la représentation des données plutôt que dépendre uniquement de conventions respectées manuellement par le programmeur.

# 6. Corpus de tests

Un corpus de huit cas a été préparé dans le dossier `corpus/`.

Il contient notamment des entrées simples, des valeurs situées autour de la limite du tampon ainsi que plusieurs tailles associées aux scénarios étudiés dans le laboratoire.

Le corpus peut être régénéré à l'aide de la commande :

`python3 corpus/generate.py`

La génération automatique des fichiers permet de conserver des tailles déterministes et facilite la reproduction des essais.

Les cas de 100 et 101 octets constituent notamment une vérification claire de la frontière imposée par la version défensive.

Le premier représente la plus grande entrée valide, tandis que le second représente la plus petite entrée devant être rejetée.

# 7. Extension au serveur

La dernière partie du laboratoire transpose le problème vers un serveur fonctionnant dans l'environnement Docker isolé fourni.

Dans le scénario local, l'entrée utilisée par le programme provient directement d'un fichier.

Dans le scénario serveur, cette entrée arrive par une connexion TCP.

Cette différence ne change pas la nature fondamentale de la vulnérabilité.

Dans les deux cas, des données contrôlées par une source externe peuvent atteindre une opération mémoire qui ne respecte pas correctement la capacité de son tampon.

Le contexte réseau ajoute toutefois plusieurs éléments.

Le processus vulnérable n'est plus nécessairement lancé directement par l'utilisateur qui produit l'entrée. Les données doivent traverser le protocole réseau et être reçues par le serveur avant d'atteindre la fonction vulnérable.

L'environnement d'exécution du serveur peut également différer du programme local, ce qui signifie que les adresses mémoire, les identifiants de processus et certaines hypothèses sur l'état du programme ne doivent pas être considérés comme identiques.

L'intérêt principal de cette partie est donc de montrer que la même erreur de programmation peut devenir une surface d'attaque distante lorsqu'elle se trouve derrière une interface réseau.

# 8. Travail d'équipe et reproductibilité

Les décisions liées au laboratoire sont consignées dans `JOURNAL.md`.

L'historique Git permet également de retrouver l'évolution du dépôt et les modifications apportées aux différents fichiers.

Ces éléments servent principalement à assurer la reproductibilité du travail et à conserver une trace des changements apportés au cours du laboratoire.

Les scripts, le corpus et l'organisation des traces ont été conçus afin que les expériences puissent être répétées dans le même environnement plutôt que dépendre uniquement d'observations manuelles.

# 9. Conclusion

Ce laboratoire montre qu'un débordement de tampon relativement simple peut affecter directement le flot d'exécution d'un programme lorsque les données sont copiées sans respecter la capacité du tampon de destination.

L'analyse de la pile explique pourquoi les données de contrôle peuvent être atteintes. Le shellcode montre comment des instructions peuvent être représentées directement sous forme d'octets. Return-to-libc illustre ensuite qu'empêcher l'exécution de la pile ne suffit pas nécessairement à supprimer toutes les possibilités de détournement du flot de contrôle.

Les mécanismes ASLR, StackGuard et NX apportent chacun une protection différente. ASLR réduit la prévisibilité des adresses, StackGuard cherche à détecter certaines corruptions de pile et NX empêche l'exécution directe de certaines régions mémoire.

Aucun de ces mécanismes ne remplace toutefois la correction de la cause initiale.

La partie Ada met particulièrement bien ce point en évidence. En imposant une limite explicite de 100 octets et en rejetant l'entrée avant la copie lorsqu'elle dépasse cette limite, le programme évite directement le comportement qui crée la vulnérabilité.

L'approche la plus solide reste donc de combiner une validation correcte des entrées, des opérations mémoire bornées et les mécanismes de protection fournis par le compilateur et le système d'exploitation.

# Références

- Énoncé et archives SEED fournis dans le cadre du cours.
- W. Du, documentation et matériel SEED Labs.
- Documentation des outils de compilation et de débogage utilisés dans l'environnement du laboratoire.
- Documentation Ada/AdaCore utilisée pour la partie consacrée au typage défensif.