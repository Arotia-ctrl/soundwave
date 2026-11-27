# SOUNDWAVE

*Your music. Your vibe. Your library.*

Lecteur musical Android (Flutter) qui lit, organise et analyse la musique
stockée sur le téléphone. Tout fonctionne hors ligne : aucune musique ni donnée
n'est envoyée à un serveur.

## Fonctionnalités

- Lecture : play/pause, suivant/précédent, barre de progression, shuffle, repeat,
  file d'attente, mini-player, lecture en arrière-plan, notification et écran
  verrouillé, reprise après fermeture.
- Bibliothèque : morceaux, artistes, albums, tri, recherche, pochettes,
  regroupement des collaborations (« Ninho feat. Niska » → Ninho).
- Identification : métadonnées du fichier, sinon analyse du nom de fichier
  (« Artiste - Titre.mp3 »).
- Playlists : création, renommage, réorganisation, favoris, et playlists
  automatiques (Favorites, Recently Played, Most Played, Recently Added).
- Analyse audio : BPM, énergie, volume, plage dynamique, brillance du son,
  catégories Soft / Non-soft / À confirmer et Slow / Fast, avec correction manuelle.
- Réglages : permissions, scan, reprise de lecture, analyse automatique,
  historique, réinitialisation des données.

## Prérequis

- Flutter (version stable récente) et son SDK Android
- Un téléphone Android (débogage USB activé) ou un émulateur

## Installation et lancement

```
flutter pub get
flutter analyze
flutter test
flutter run
```

## Construire l'APK

```
flutter build apk --release
```

Le fichier est créé dans `build/app/outputs/flutter-apk/app-release.apk`.
Copie-le sur le téléphone puis ouvre-le pour l'installer (autoriser les sources
inconnues si Android le demande). Par défaut, l'APK est signé avec la clé de
debug : suffisant pour installer sur ton téléphone, mais une vraie clé de
signature est nécessaire pour une publication sur le Play Store.

## Structure du projet

```
lib/
  core/         thème, base de données, utilitaires, navigation
  features/
    player/       lecture, file d'attente, reprise
    library/      bibliothèque, favoris, historique
    scanner/      lecture de MediaStore (via le module natif)
    metadata/     lecture des noms de fichiers
    analyzer/     analyse audio (mesures brutes, résultats, contrôleur)
    classification/ règles Soft / Non-soft et Slow / Fast
    playlists/    playlists utilisateur et automatiques
    discover/     catégories et filtres combinables
    settings/     réglages et maintenance des données
  shared/       modèles et composants communs
android/app/src/main/kotlin/com/ares/soundwave/
  MainActivity.kt   canaux natifs (bibliothèque, pochettes, permissions, analyse)
  MediaLibrary.kt   lecture de MediaStore et des pochettes
  AudioAnalyzer.kt  décodage audio et calcul des mesures
```

Chaque fonctionnalité suit la séparation `data` (sources, dépôts), `domain`
(règles métier) et `presentation` (écrans et composants).

## Base de données

SQLite (`sqflite`), fichier `soundwave.db`, version 3. Les mises à jour passent
par des migrations dans `lib/core/database/app_database.dart` : ne jamais
supprimer une table existante sans migration.

Tables : `playlists`, `playlist_tracks`, `favorites`, `listening_history`,
`analysis_results`, `user_preferences`. Les morceaux eux-mêmes sont lus depuis
MediaStore et ne sont pas dupliqués.

## Régler la classification Soft / Non-soft

Les seuils sont des valeurs de départ. Ils se trouvent dans
`lib/features/classification/domain/classifier.dart` :

- `slowBelowBpm` : en dessous, le morceau est Slow
- `softAtLeast` / `nonSoftAtMost` : zone Soft, zone Non-soft, et entre les deux « À confirmer »
- les pondérations du calcul de `softScore`

Après modification : relancer l'app, puis **Settings > Recalculer les catégories**
(aucune réanalyse des fichiers nécessaire, les mesures sont déjà stockées).
Les mesures d'un morceau sont visibles dans son menu ⋮ > « Analyse et catégorie ».
Les corrections manuelles ne sont jamais écrasées.

## Confidentialité

L'application lit uniquement les fichiers audio via MediaStore, ne modifie
jamais un fichier original et n'envoie rien en ligne.

## Limites connues

- La détection Instrumental (absence de voix) n'est pas implémentée.
- Le BPM est une estimation, parfois au double ou à la moitié du vrai tempo.
- Le genre n'est lu qu'à partir d'Android 11.
- Un seul thème (Dark Purple) pour l'instant.