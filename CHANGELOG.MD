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
- Graphique des écarts nutritionnels dans le tableau de bord :
  - Visualisation des écarts entre consommation et objectifs
  - Affichage des 7 derniers jours minimum
  - Défilement horizontal pour voir l'historique
  - Code couleur cohérent avec l'application
  - Légende des nutriments
  - Hauteur optimisée (30% de l'écran)
- Optimisation majeure des performances de la base de données :
  - Réduction des temps de verrouillage lors des opérations sur l'agenda
  - Utilisation de transactions optimisées pour les mises à jour multiples
  - Regroupement des opérations de mise à jour du stock en lots (batch)
  - Déplacement des lectures hors des transactions pour réduire les temps de verrouillage
  - Élimination des appels imbriqués aux services dans les transactions
- Suppression sécurisée des aliments avec confirmation détaillée :
  - Affichage des valeurs nutritionnelles de l'aliment
  - Liste des repas impactés par la suppression
  - Avertissement visuel sur l'impact de la suppression
  - Suppression en cascade des repas et jours associés
  - Nettoyage automatique des références dans l'agenda
- Confirmation détaillée lors de la suppression d'un repas de l'agenda avec affichage de l'impact nutritionnel
- Avertissement lors de la suppression d'un aliment utilisé dans des repas
- Suppression automatique des repas liés à un aliment supprimé
- Gestion complète des repas :
  - Édition des repas existants avec mise à jour des valeurs nutritionnelles
  - Suppression sécurisée des repas avec confirmation détaillée
  - Avertissement lors de la suppression d'un repas utilisé dans l'agenda
  - Mise à jour automatique de l'agenda lors de la suppression d'un repas
- Améliorations du graphique des écarts nutritionnels (LineChart) :
  - Possibilité d'afficher les labels Y (graduations) à gauche **et** à droite du graphique pour une meilleure lisibilité, même lors du scroll horizontal.
  - Centrage automatique du graphique et meilleure gestion des marges pour éviter que la courbe soit collée aux bords.
  - Ajout d'un sélecteur de période (7, 14, 30 jours) pour l'affichage de l'historique.
  - Gestion des jours sans données : les deltas sont affichés à zéro pour éviter les chutes visuelles.
  - Correction de l'alignement entre les labels Y et la grille du graphique.
  - Refactoring pour garantir la synchronisation des labels Y avec la grille, quel que soit le scroll.

### Améliorations
- Refonte complète du système de calcul des macronutriments :
  - Centralisation des calculs dans le modèle `ParametresNutritionnels`
  - Amélioration de la cohérence entre les valeurs affichées et stockées
  - Optimisation des calculs automatiques selon l'objectif :
    - Perte de poids : 2.2g/kg de protéines, 30% lipides
    - Maintien : 1.8g/kg de protéines, 25% lipides
    - Prise de masse : 1.7g/kg de protéines, 20% lipides
  - Calcul automatique des glucides en fonction des calories restantes
  - Meilleure gestion du mode manuel vs automatique
  - Synchronisation des pourcentages et grammes
- Optimisation de la plage horaire de l'agenda (6h-23h)
- Correction des noms de colonnes dans la base de données
- Amélioration de la gestion des suppressions :
  - Suppression en cascade des repas lors de la suppression d'un aliment
  - Nettoyage automatique des références dans l'agenda
  - Transaction unique pour garantir l'intégrité des données
- Correction de la quantité d'achat par défaut dans la liste de courses
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
- Correction du rafraîchissement dynamique du dashboard après modification des paramètres nutritionnels :
  - Suppression du `final` sur la liste `_screens` pour permettre la réaffectation
  - Forçage de la reconstruction du dashboard après sauvegarde des paramètres

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

