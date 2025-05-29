# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - En développement

### En cours
- Système de gestion des repas
  - Interface divisée en trois sections :
    - Liste des repas réutilisables (35% de la hauteur)
    - Agenda interactif (50% de la hauteur)
    - Vue des macronutriments journaliers
  - Fonctionnalités de l'agenda :
    - Planification horaire des repas par glisser-déposer
    - Sauvegarde des données nutritionnelles par journée
  - Gestion des repas avec impact sur le stock
  - Détails nutritionnels complets par repas

### Ajouté
- Suppression sécurisée des aliments avec confirmation détaillée :
  - Affichage des valeurs nutritionnelles de l'aliment
  - Liste des repas impactés par la suppression
  - Avertissement visuel sur l'impact de la suppression
- Confirmation détaillée lors de la suppression d'un repas de l'agenda avec affichage de l'impact nutritionnel
- Avertissement lors de la suppression d'un aliment utilisé dans des repas
- Suppression automatique des repas liés à un aliment supprimé

### Améliorations
- Optimisation de l'agenda :
  - Plage horaire réduite de 6h à 23h pour une meilleure lisibilité
  - Format d'affichage des heures uniformisé (ex: "06:00" au lieu de "6:00")
- Amélioration de l'icône d'ajustement du stock pour plus de clarté
- Amélioration de la visualisation et de l'édition des repas
  - Ajout des boutons d'édition et de suppression dans la vue détaillée
  - Affichage complet des nutriments pour chaque aliment (calories, protéines, lipides, glucides)
  - Vue comparative des valeurs nutritionnelles (quantité sélectionnée vs 100g)
  - Indication visuelle des éléments interactifs
  - Affichage des pourcentages par rapport aux objectifs journaliers
  - Support de la modification d'un repas existant
- Optimisation de l'affichage des aliments dans un repas
  - Réorganisation des informations nutritionnelles sur une ligne dédiée
  - Ajout d'une icône pour accéder aux détails de l'aliment
  - Simplification et amélioration de la boîte de dialogue des détails
  - Affichage des pourcentages par rapport aux objectifs journaliers

### Corrections
- Correction de la quantité d'achat par défaut dans la liste de courses :
  - 1 unité pour les aliments gérés par portion (boîte, unité...)
  - 1000 pour les aliments gérés par masse (grammes, ml...)
- Correction de l'overflow des valeurs nutritionnelles dans la vue détaillée des aliments d'un repas

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

## [Non publié]

### Ajouté
- Nouveau modèle `JourRepas` pour gérer les repas journaliers
- Service `JourRepasService` pour la gestion des repas journaliers
- Icône d'œil dans l'interface pour indiquer l'interactivité des repas

### Modifié
- Amélioration de l'interface de gestion des repas journaliers
- Optimisation de l'initialisation de la base de données
- Optimisation du service d'arrière-plan
- Meilleure gestion des aliments supprimés dans l'affichage des repas

### Corrigé
- Correction des problèmes de chargement infini de l'application
- Correction de l'affichage des détails des repas
- Correction de la superposition des repas dans l'agenda
- Amélioration de la réactivité des interactions tactiles

## [1.0.0] - 2024-01-XX

### Initial Release
- Première version de l'application

