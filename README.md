# Pigeon Nutrition App

Application Flutter pour la gestion de la nutrition des pigeons de compétition.

## Prérequis

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Android Studio](https://developer.android.com/studio) (pour l'émulateur Android)
- [Git](https://git-scm.com/downloads)
- [VS Code](https://code.visualstudio.com/) (recommandé)

## Installation

1. Cloner le dépôt :
```bash
git clone https://github.com/YohanF1245/pigeon_nutrition_apk.git
cd pigeon_nutrition_apk
```

2. Installer les dépendances :
```bash
flutter pub get
```

## Développement

### Configuration de l'émulateur Android

1. Ouvrir Android Studio
2. Aller dans "Tools" > "Device Manager"
3. Cliquer sur "Create Device"
4. Sélectionner un téléphone (ex: Pixel 6)
5. Télécharger et sélectionner une image système Android (recommandé: API 33)
6. Finaliser la création et démarrer l'émulateur

### Démarrer l'émulateur depuis la ligne de commande

1. Lister les émulateurs disponibles :
```bash
flutter emulators
```

2. Démarrer un émulateur spécifique :
```bash
flutter emulators --launch <emulator_id>
```

### Lancer l'application

1. Sur l'émulateur :
```bash
flutter run
```

2. En mode release (optimisé) :
```bash
flutter run --release
```

### Utiliser un appareil physique Android

1. Activer le mode développeur sur votre téléphone :
   - Aller dans "Paramètres" > "À propos du téléphone"
   - Appuyer 7 fois sur "Numéro de build"
   - Le message "Vous êtes maintenant un développeur" apparaît

2. Activer le débogage USB :
   - Retourner dans "Paramètres"
   - Aller dans "Options pour les développeurs"
   - Activer "Débogage USB"

3. Connecter le téléphone via USB :
   - Accepter l'autorisation de débogage sur le téléphone
   - Vérifier que le téléphone est détecté :
   ```bash
   flutter devices
   ```

4. Lancer l'application :
```bash
flutter run
```

## Commandes utiles

### Flutter

- Vérifier la configuration Flutter :
```bash
flutter doctor
```

- Nettoyer le projet :
```bash
flutter clean
```

- Mettre à jour les dépendances :
```bash
flutter pub upgrade
```

### Git

- Créer une nouvelle branche :
```bash
git checkout -b feature/nom-feature
```

- Commiter des changements (convention Angular) :
```bash
git commit -m "type(scope): description" -m "details"
```
Types : feat, fix, docs, style, refactor, test, chore

- Pousser les changements :
```bash
git push origin nom-branche
```

## Débogage

- Voir les logs en temps réel :
```bash
flutter logs
```

- Activer les outils de performance :
```bash
flutter run --profile
```

## Build pour production

### Android APK
```bash
flutter build apk
```
L'APK sera disponible dans `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle
```bash
flutter build appbundle
```
Le bundle sera disponible dans `build/app/outputs/bundle/release/app-release.aab`

## Problèmes courants

1. **L'émulateur ne démarre pas**
   - Vérifier que la virtualisation est activée dans le BIOS
   - Réinstaller les outils Android SDK

2. **Le téléphone n'est pas détecté**
   - Réinstaller les drivers USB
   - Essayer un autre câble USB
   - Redémarrer l'ordinateur et le téléphone

3. **Erreurs de build**
   - Exécuter `flutter clean`
   - Supprimer le dossier `.dart_tool`
   - Réexécuter `flutter pub get`

## Contribution

1. Créer une branche depuis `develop`
2. Faire les modifications
3. Commiter avec la convention Angular
4. Créer une Pull Request vers `develop`

## Support

Pour toute question ou problème :
- Ouvrir une issue sur GitHub
- Contacter l'équipe de développement

le projet possede quatre grande parties : 

1 gestion des aliments, des macro nutriments et du stock de nourriture.

chaque aliment possede des valeurs nutrionnelles pour 100 g.
certains aliments on une conversion d'unité (une boite, un oeuf, une tranche etc ...)
les aliments peuvent ou non s'auto decrease (exemple je consomme 4 oeuf par jour)
les aliments ont un seuil limite 
les aliments ont un nombre d'acaht( j'achete une boite de 12 ou 6 oeuf par exemple)
je peux generer des liste de courses avec tout les produits sous le seuil d'alerte

2 generer des repas, ajouter ses repas dans un planing journalier qui va calculer mes macro d'un jour précis

3 calculer mes entrainements, trois types cardio / muscu / divers (marche ou velo)

pour le cardio tracker temps, distance, calories brulees
pour la muscu generer des exercices avec type, nombre de rep, nombre de series

4 tracking du poids et des données impendometre. poids, taux graisse, eau etc ...
