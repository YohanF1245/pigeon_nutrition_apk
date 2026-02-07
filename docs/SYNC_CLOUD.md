# Options de synchronisation cloud (PC / téléphone)

L’app web actuelle stocke tout dans le **localStorage** du navigateur. L’import/export CSV (ou ZIP) sert de sauvegarde et d’analyse, mais ne synchronise pas automatiquement entre plusieurs appareils (PC, téléphone, etc.).

Voici les options réalistes pour faire de la **sync cloud** entre plusieurs “localStorage” (ou équivalent).

---

## 1. Backend minimal + auth (recommandé pour une vraie sync)

**Principe :** un petit backend stocke les données par utilisateur. Chaque appareil se connecte (login), lit/écrit les mêmes données.

| Option | Hébergement | Auth | Coût typique |
|--------|-------------|------|----------------|
| **Supabase** | Hébergé | Email, magic link, OAuth | Gratuit jusqu’à un certain volume |
| **Firebase (Firestore)** | Hébergé | Email, anonyme, OAuth | Gratuit (quota free) |
| **Vercel + API Routes + DB** | Vercel + DB (ex. Vercel Postgres, Neon, Upstash) | À ajouter (ex. Supabase Auth, Auth0) | Gratuit / pas cher |
| **Backend perso** (Node, etc.) | Railway, Render, Fly.io | À coder | ~5–10 €/mois |

**Flow type :**

- Au chargement : si connecté → `GET /api/data` (ou équivalent) → remplacer ou merger avec le localStorage.
- À chaque modification : `PUT /api/data` (ou PATCH) avec le JSON complet (ou des deltas).
- Gestion des conflits : **last-write-wins** (simple) ou **merge** (ex. fusion des listes par `id`, date de modification).

**Avantage :** une seule source de vérité, sync en quasi temps réel si tu fais un petit polling ou WebSocket.  
**Inconvénient :** il faut héberger un backend (ou utiliser Supabase/Firebase) et gérer l’auth.

---

## 2. Supabase (bon compromis)

- **Base Postgres** + **Auth** (email, magic link, Google, etc.) + **Realtime** (optionnel).
- Tu peux stocker tout le blob JSON par user dans une table `user_data (user_id, data jsonb, updated_at)`.
- L’app reste déployable en statique (GitHub Pages) ; elle appelle l’API Supabase depuis le navigateur (avec la clé publique + session utilisateur).

**Sync :** au login, tu récupères `data`, tu l’injectes dans le state / localStorage. À chaque changement, tu fais un `UPDATE` sur cette ligne. Sur l’autre appareil, au chargement (ou via Realtime), tu récupères la même ligne.

---

## 3. Firebase Firestore

- Pas de serveur à coder : SDK JS, Auth (email, anonyme, Google), Firestore pour les documents.
- Tu stockes par exemple un document par user : `users/{userId}/appData` avec un champ de type “map” ou string JSON.
- **Offline** : Firestore gère le cache local et la re-sync quand la connexion revient.

**Sync :** même idée : lecture au chargement, écriture à chaque modification. Firestore s’occupe de la cohérence multi-appareils.

---

## 4. Sync “manuelle” améliorée (sans backend)

Sans serveur, une “sync” reste limitée à un **flux manuel** :

- **Export** sur l’appareil A → fichier ZIP/JSON.
- **Transfert** (mail, Drive, AirDrop, etc.) vers l’appareil B.
- **Import** sur l’appareil B (remplacer ou fusionner).

Tu peux améliorer l’UX :

- Bouton **“Télécharger la sauvegarde”** (ZIP ou JSON) + **“Restaurer depuis un fichier”**.
- Option **“Fusionner avec les données actuelles”** à l’import (déjà en place avec le ZIP).

C’est une bonne **sécurité / sauvegarde**, mais ce n’est pas une sync automatique entre PC et téléphone.

---

## 5. Stockage “cloud” type Drive/Dropbox (avancé, sans backend perso)

- **OAuth** Google ou Dropbox, puis lecture/écriture d’un fichier dédié (ex. `pigeon_nutrition_backup.json`) dans le Drive ou le dossier de l’utilisateur.
- L’app lit ce fichier au chargement (si connecté) et peut proposer “Sauvegarder dans le cloud” / “Charger depuis le cloud”.

**Limites :** pas de vrai multi-appareil temps réel (il faut un “Charger” explicite sur l’autre appareil), quotas API, et mise en place un peu plus lourde. Intéressant surtout pour une **sauvegarde cloud** plutôt que pour une sync automatique.

---

## Recommandation rapide

- **Pas de backend, pas d’auth :** garder **import/export** (ZIP/CSV) comme “sync manuelle” et sauvegarde.
- **Vraie sync PC / téléphone :** ajouter un **petit backend + auth** :
  - **Supabase** (Postgres + Auth + option Realtime) est un bon premier pas.
  - **Firebase** convient aussi si tu préfères l’écosystème Google.

En pratique, pour Pigeon Nutrition :

1. Créer un projet Supabase (ou Firebase).
2. Table (ou collection) : une ligne (ou un doc) par user, avec un champ JSON pour tout le state (aliments, repas, etc.) + `updated_at`.
3. Dans l’app : écran **Connexion** (email + magic link ou OAuth), puis au chargement si connecté → récupérer ce JSON et l’injecter dans le state / localStorage ; à chaque modification → envoyer le JSON (ou un diff) au backend.
4. Optionnel : petit indicateur “Synchronisé à …” et bouton “Rafraîchir depuis le cloud”.

Tu restes déployable en statique (GitHub Pages) ; seules les appels API et les clés publiques changent.
