# Tests unitaires — app web

## Stack

- **Vitest** (exécution, mocks, couverture)
- **React Testing Library** + **@testing-library/user-event** (composants React)
- **jsdom** (environnement navigateur)
- **@vitest/coverage-v8** (rapport de couverture)

## Commandes

| Commande | Description |
|----------|-------------|
| `npm run test` | Lance Vitest en mode watch |
| `npm run test:run` | Exécute les tests une fois (CI) |
| `npm run test:coverage` | Exécute les tests et génère le rapport de couverture (dossier `coverage/`) |

## Organisation

- Fichiers de test : à côté du code (ex. `nutrition.test.ts`, `AppContext.test.tsx`) ou dans `src/test/setup.ts` pour la config globale.
- **Setup** : `src/test/setup.ts` enregistre `@testing-library/jest-dom` pour les matchers (`toBeInTheDocument()`, etc.).

## Cibles couvertes

- **Utils** : `nutrition.ts` (nutrimentsRepas, macrosPourDate, nutritionHistory)
- **Services** : `storage.ts`, `openFoodFacts.ts`, `csv.ts` (export/import CSV et ZIP, avec mocks localStorage / fetch)
- **Context** : `AppContext.tsx` (provider, setters, useApp hors provider)
- **Composants** : `Layout`, `AlimentForm`, `RepasForm`, `BarcodeScannerModal` (avec mocks html5-qrcode, openFoodFacts)
- **Pages** : rendu de chaque page via `TestApp` (MemoryRouter + AppProvider + routes)

## Objectif couverture

On vise une couverture élevée (objectif 100 % des lignes/branches utiles). Les fichiers exclus du rapport sont : `src/main.tsx`, `src/types/**`, `src/test/**`, fichiers `.d.ts`.

## Mocks courants

- **localStorage** : `vi.stubGlobal('localStorage', { getItem, setItem, ... })` dans les tests qui lisent/écrivent le storage.
- **fetch** : `vi.stubGlobal('fetch', vi.fn())` pour Open Food Facts.
- **html5-qrcode** : `vi.mock('html5-qrcode', () => ({ Html5Qrcode: class Mock... }))` dans les tests du scanner.
- **BarcodeScannerModal** : mock en composant simple (boutons Fermer / Simuler scan) dans les tests d’AlimentForm.
