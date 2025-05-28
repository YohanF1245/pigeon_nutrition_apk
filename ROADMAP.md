# Roadmap Pigeon Nutrition

## Version Actuelle
- [x] Correction des bugs liés aux TextEditingController
- [x] Amélioration de la stabilité de l'écran d'ajout de repas

## Prochaines Étapes
- [ ] Amélioration de l'interface utilisateur
- [ ] Ajout de nouvelles fonctionnalités
- [ ] Tests unitaires et d'intégration

# Roadmap v0.2.0 - Gestion des Repas

## Phase 1 : Modèles et Services ✅
- [x] Création du modèle `Repas`
  - [x] Propriétés de base (nom, date, heure)
  - [x] Liste d'aliments avec quantités
  - [x] Méthodes de calcul des nutriments totaux
- [x] Création du service `RepasService`
  - [x] CRUD pour les repas
  - [x] Méthodes de gestion du stock
  - [x] Persistance dans SQLite

## Phase 2 : Refonte de RepasScreen
- [x] Structure de base en trois sections
  - [x] Layout responsive avec contraintes de taille
  - [x] Gestion de l'état global
  - [x] Navigation entre les sections
- [x] Liste des repas (Bottom Section)
  - [x] Liste scrollable des repas
  - [x] Card design pour chaque repas
  - [x] FAB pour l'ajout de repas
- [x] Modal de détails du repas
  - [x] Vue détaillée des nutriments
  - [x] Liste des aliments composants
  - [ ] Options d'édition
- [x] Formulaire d'ajout/édition de repas
  - [x] Sélection des aliments existants
  - [x] Gestion des quantités
  - [ ] Prévisualisation des nutriments
  - [ ] Gestion des portions prédéfinies
  - [ ] Personnalisation du titre du repas

## Phase 3 : Planning Journalier (Middle Section)
- [ ] Création du widget `PlanningJournalierWidget`
  - [ ] Vue calendrier horizontale
  - [ ] Gestion du swipe gauche/droite
  - [ ] Échelle horaire verticale
- [ ] Intégration des repas dans le planning
  - [ ] Affichage des repas selon l'heure
  - [ ] Drag & drop pour le positionnement
  - [ ] Gestion des conflits horaires
- [ ] Animations et transitions fluides
  - [ ] Animation de swipe
  - [ ] Transitions entre les jours
  - [ ] Feedback visuel des interactions

## Phase 4 : Résumé Nutritionnel (Top Section)
- [ ] Création du widget `ResumeNutritionnel`
  - [ ] Affichage des macronutriments
  - [ ] Comparaison objectif/réel
  - [ ] Barres de progression
- [ ] Calculs en temps réel
  - [ ] Somme des nutriments des repas
  - [ ] Mise à jour automatique
  - [ ] Gestion des dépassements

## Phase 5 : Tests et Optimisations
- [ ] Tests utilisateur
  - [ ] Vérification des calculs
  - [ ] Test des interactions
  - [ ] Validation du workflow
- [ ] Optimisations
  - [ ] Performance des calculs
  - [ ] Gestion de la mémoire
  - [ ] Expérience utilisateur

## Phase 6 : Finalisation
- [ ] Documentation
  - [ ] Guide utilisateur
  - [ ] Documentation technique
  - [ ] Commentaires dans le code
- [ ] Préparation de la release
  - [ ] Tests finaux
  - [ ] Build de production
  - [ ] Notes de version

## Suggestions d'Améliorations
1. Ajouter des modèles de repas prédéfinis
2. Permettre la duplication de repas
3. Ajouter des statistiques hebdomadaires/mensuelles
4. Intégrer un système de rappels/notifications
5. Ajouter un mode "préparation de la semaine"
6. Permettre l'export du planning en format calendrier 