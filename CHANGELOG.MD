# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2024-03-21

### Ajouté
- Possibilité d'éditer la quantité à acheter directement dans la liste de courses
- Bouton de validation des achats qui met à jour automatiquement les stocks

### Améliorations
- Refonte du système de liste de courses
- Optimisation de la gestion d'état pour une meilleure réactivité de l'interface

### Corrections
- Suppression des labels redondants "Stock (en xxx)" pour éviter les surcharges visuelles
- Correction de la taille des labels dans la liste de courses pour éviter l'overflow
- Correction du compteur d'articles dans l'icône du panier qui ne se mettait pas à jour après validation des achats
- Correction du flash du compteur lors de la validation des achats

## [0.1.0] - Version initiale

### Ajouté
- Système de gestion des aliments
- Gestion des stocks
- Calcul des valeurs nutritionnelles
- Interface utilisateur de base 