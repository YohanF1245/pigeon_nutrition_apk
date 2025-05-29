# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - En développement

### En cours
- Système de gestion des repas
  - Interface en trois parties (macros/planning/liste des repas)
  - Vue des macronutriments journaliers avec objectifs
  - Calendrier interactif avec planification horaire
  - Gestion des repas avec impact sur le stock
  - Détails nutritionnels complets par repas

### Corrections
- Correction de la quantité d'achat par défaut dans la liste de courses :
  - 1 unité pour les aliments gérés par portion (boîte, unité...)
  - 1000 pour les aliments gérés par masse (grammes, ml...)

## [Non Publié]

### Ajouté
- Suppression sécurisée des aliments avec confirmation
- Avertissement lors de la suppression d'un aliment utilisé dans des repas
- Suppression automatique des repas liés à un aliment supprimé

### Corrections
- Correction de la quantité d'achat par défaut dans la liste de courses :
  - 1 unité pour les aliments gérés par portion (boîte, unité...)
  - 1000 pour les aliments gérés par masse (grammes, ml...)

## [0.1.2] - 2024-03-22

### Ajouté
- Système d'export/import de la base de données
  - Export de la base SQLite vers un fichier partageable
  - Import d'une base de données existante avec vérifications de sécurité
  - Interface utilisateur intégrée dans les paramètres de l'application

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

## [Non Publié]

### Corrections de Bugs
- Correction du bug de TextEditingController dans l'écran d'ajout de repas
  - Amélioration de la gestion du cycle de vie des contrôleurs
  - Prévention des erreurs de disposition des contrôleurs 