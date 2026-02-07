# Pigeon Nutrition — application web

Version web de l’app Flutter, avec persistance **localStorage** et **import/export CSV** (ZIP) pour analyse de données.

## Stack

- **Vite** + **React 18** + **TypeScript**
- **React Router**
- **localStorage** (clés `pigeon_*`)
- **papaparse** + **jszip** pour CSV et export ZIP

## Commandes

```bash
cd web
npm install
npm run dev      # dev http://localhost:5173
npm run build    # build production (base /)
npm run build:gh # build pour GitHub Pages (base /pigeon_nutrition_apk/)
npm run deploy:gh # build:gh puis push dist sur branche gh-pages
npm run test     # tests en watch
npm run test:run # tests une fois
npm run test:coverage # tests + rapport de couverture (Vitest + v8)
```

## Déploiement GitHub Pages

**Idée : commit, push → le site se met à jour.**

1. Sur GitHub : **Settings → Pages** → Source = **GitHub Actions**.
2. En local : `git add .` → `git commit -m "..."` → `git push origin develop` (ou `main`).
3. L’Action build et déploie automatiquement. URL : **https://&lt;username&gt;.github.io/pigeon_nutrition_apk/**

Guide détaillé : [../docs/DEPLOI_GITHUB_PAGES.md](../docs/DEPLOI_GITHUB_PAGES.md)

Les données restent dans le navigateur (localStorage). Export ZIP = tous les CSV en un fichier pour analyse (Excel, Python, etc.).
