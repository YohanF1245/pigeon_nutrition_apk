# Conversion Pigeon Nutrition : app Flutter → application web

## Contexte

- **Actuel :** app Flutter/Dart pour Android (SQLite + SharedPreferences, Open Food Facts, graphiques, notifications).
- **Cible :** application web statique hébergeable sur **GitHub Pages**, avec **localStorage** et **import/export CSV** pour analyse de données.

---

## Stacks recommandées

### Option 1 : **React + Vite** (recommandé)

- **Pourquoi :** écosystème riche, beaucoup de libs (graphiques, CSV, UI), Vite génère un build statique parfait pour GitHub Pages. Base de devs importante.
- **Stack concrète :**
  - **Vite** (build) + **React 18**
  - **localStorage** (ou **idb** / IndexedDB si le volume de données grossit)
  - **Export CSV :** génération côté client (pas de lib obligatoire, ou `papaparse` / `csv-stringify`)
  - **Import CSV :** lecture fichier (File API) + parsing (ex. `papaparse`) puis merge dans le state / localStorage
- **Déploiement :** `npm run build` → dossier `dist/` publié sur la branche `gh-pages` ou dans `/docs` avec `base: '/pigeon_nutrition_apk/'` dans `vite.config`.

### Option 2 : **Vue 3 + Vite**

- Même idée : SPA statique, localStorage, CSV. Moins de boilerplate que React, très adapté à une app de formulaires et tableaux.
- Même workflow GitHub Pages (build → `dist` → push `gh-pages` ou `/docs`).

### Option 3 : **Svelte + Vite**

- Bundle plus léger, moins de runtime. Idéal pour une app légère et rapide. Même schéma de déploiement.

**Recommandation :** **React + Vite** pour la conversion, sauf si tu es déjà à l’aise avec Vue ou Svelte — dans ce cas, les trois options sont valides pour “le plus simple vers GitHub Pages”.

---

## Pourquoi GitHub Pages (et pas seulement Vercel)

- **Gratuit,** sans compte serveur.
- **100 % statique :** pas de backend, pas de Node en prod. Données uniquement dans le navigateur (localStorage / IndexedDB).
- **Import/export CSV :** tout se fait côté client (lecture fichier, écriture blob + téléchargement). Aucun serveur nécessaire.
- **Data analyse :** l’utilisateur exporte en CSV et analyse dans Excel, Google Sheets, Python, R, etc. L’app web n’a pas besoin de faire l’analyse.

Vercel convient aussi (même build statique), mais pour “le plus simple” et “GitHub Page c’est le must”, GitHub Pages est le choix logique.

---

## Persistance : localStorage + Import/Export CSV

### Stockage

- **localStorage** pour tout (aliments, repas, jours_repas, entraînements, mesures, paramètres nutritionnels).
- Clés du type : `pigeon_aliments`, `pigeon_repas`, `pigeon_jours_repas`, `pigeon_entrainements`, `pigeon_mesures`, `pigeon_parametres`.
- Si le volume devient important (milliers d’entrées), migrer vers **IndexedDB** (ex. avec `idb`) en gardant la même API métier.

### Export CSV

- **Plusieurs CSV** (un par entité) pour faciliter l’analyse :
  - `aliments.csv` : id, nom, unite, prixUnitaire, devise, gestionStock, quantiteStock, seuilAlerte, calories, proteines, lipides, glucides, …
  - `repas.csv` : id, nom, createdAt
  - `repas_aliments.csv` : repasId, alimentId, quantite
  - `jours_repas.csv` : id, date, repasId, heure, minute
  - `entrainements.csv` : id, date, type, dureeMinutes, champs spécifiques (distance, caloriesBrulees, activite, ou JSON des exercices)
  - `mesures.csv` : id, date, poids, tauxGraisse, …
  - `parametres.csv` : id, poids, taille, age, sexe, niveauActivite, objectif, objectifProteines, …
- **Option :** un **ZIP** contenant tous les CSV (une seule action “Exporter tout”).
- **Bouton “Télécharger CSV”** (ou “Exporter”) qui génère les fichiers à partir du state / localStorage.

### Import CSV

- **Écran ou modal “Importer”** : choix de fichier(s) CSV (ou un ZIP à décompresser côté client avec une lib type `jszip`).
- **Règles :**
  - **Merge** : ajouter / mettre à jour les enregistrements (clé = id ou combinaison de champs).
  - **Option “Remplacer”** : vider les données concernées puis importer.
- Validation basique (colonnes attendues, types) et rapport d’erreurs (lignes ignorées, champs manquants).
- Après import : recharger le state et sauver dans localStorage.

---

## Schéma de conversion (résumé)

| Flutter / actuel        | Web cible                          |
|-------------------------|------------------------------------|
| SQLite + SharedPreferences | localStorage (ou IndexedDB plus tard) |
| Provider                 | React Context / Zustand / Jotai   |
| Écrans (screens/)        | Pages / routes React (React Router) |
| Modèles Dart             | Objets JS/TS + types TypeScript   |
| Open Food Facts (HTTP)   | `fetch()` vers la même API        |
| Barcode scanner          | Option : input texte (code-barres) ou Web API si dispo |
| fl_chart                 | Chart.js, Recharts, ou Lightweight Charts |
| Notifications            | Option : Web Notifications (navigator) ou à ignorer en v1 |

---

## Plan d’action proposé

1. **Scaffold projet** : Vite + React + TypeScript, Router, structure dossiers (`src/store`, `src/services/storage`, `src/services/csv`, `src/pages`, `src/components`).
2. **Modèles & storage** : définir les types TS (Aliment, Repas, JourRepas, Entrainement, Mesures, Parametres) et un service unique qui lit/écrit dans localStorage.
3. **Écrans principaux** : Dashboard, Aliments, Repas, Entrainements, Mesures, Parametres (formulaires + listes).
4. **Export CSV** : génération des CSV par entité + option ZIP.
5. **Import CSV** : upload, parsing, validation, merge/replace, sauvegarde localStorage.
6. **Open Food Facts** : appel API par code-barres (saisie manuelle en v1).
7. **Config GitHub Pages** : `base` dans Vite, script ou action pour déployer `dist/` sur `gh-pages` ou `docs/`.

Si tu veux, on peut détailler la structure du projet (fichiers, exemples de code pour localStorage et CSV) ou partir sur un squelette de repo (Vite + React + TS + premier écran + export/import CSV).
