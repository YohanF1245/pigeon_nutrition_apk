# Déployer l’app web sur GitHub Pages

L’app web (dossier `web/`) est une SPA React. Avec l’**Action GitHub** configurée, il suffit de **commit + push** pour que le site se mette à jour.

---

## En résumé : commit, push, c’est en ligne

1. **Une fois** : active GitHub Pages (voir ci‑dessous).
2. Ensuite : à chaque **push** sur `main` ou `develop`, l’Action build l’app et la déploie. Aucune commande à lancer en local.

---

## 1. Activer GitHub Pages (une seule fois)

1. Ouvre le dépôt sur GitHub.
2. **Settings** → **Pages** (menu de gauche).
3. Sous **Build and deployment** :
   - **Source** : choisis **GitHub Actions** (pas « Deploy from a branch »).
4. Enregistre.

La première fois que tu pousseras du code sur `main` ou `develop`, l’Action `.github/workflows/deploy-pages.yml` s’exécutera et déploiera le site.

---

## 2. Déployer : commit + push

```bash
git add .
git commit -m "feat(web): mise à jour de l'app"
git push origin develop
```

(Remplace `develop` par `main` si c’est ta branche par défaut.)

Quelques minutes après le push, le site est à jour à :

**https://&lt;username&gt;.github.io/pigeon_nutrition_apk/**

---

## Option : déploiement manuel (sans Action)

Si tu préfères déployer à la main (sans Action) :

1. Dans **Settings → Pages**, mets **Source** sur **Deploy from a branch**, branche **gh-pages**, dossier **/ (root)**.
2. En local : `cd web && npm install && npm run deploy:gh` après chaque modification à mettre en ligne.

---

## Détails techniques

- **Workflow** : `.github/workflows/deploy-pages.yml` se déclenche sur push vers `main` ou `develop`, fait `npm ci` puis `npm run build:gh` dans `web/`, puis déploie le contenu de `web/dist` via l’environnement **github_pages**.
- **Base URL** : dans `web/vite.config.ts`, `base` vaut `'/pigeon_nutrition_apk/'` pour ce dépôt. Ne pas changer sans adapter l’URL.

---

## En cas de problème

- **Page blanche ou 404** : vérifier que **Settings → Pages** utilise bien **GitHub Actions** comme source.
- **Assets en 404** : l’URL du site doit être `.../pigeon_nutrition_apk/` (avec le slash final).
- **L’Action ne se lance pas** : vérifier que le push est bien sur `main` ou `develop`, et que le fichier `.github/workflows/deploy-pages.yml` est bien commité.
