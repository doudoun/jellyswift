# Refonte du player iPad — maintenance

Ce document explique comment la refonte du player vidéo iPad est construite, ce qu'elle touche dans le code d'origine (upstream), et comment récupérer les mises à jour de Swiftfin sans la refaire.

## Principe

La refonte est **uniquement visuelle**. Chaque bouton appelle exactement la même fonction upstream que le bouton d'origine. L'état du lecteur, les pistes, la vitesse, la qualité, les épisodes, les gestes et les écrans Info / Épisodes restent gérés par upstream.

Tout le code de la refonte vit dans un dossier séparé. Upstream n'est modifié qu'à trois endroits, avec une ligne chacun, marquée `// REDESIGN:`.

## Architecture en couches

```
Logique upstream (inchangée)
  MediaSession · VideoPlayer.ViewState · MediaPlayerItem · Defaults
        │
        ▼
Adaptateur            Adapter/PlayerAdapter.swift, Adapter/UpstreamViews.swift
        │
        ▼
Composants visuels    Components/*.swift, RedesignedControls.swift
        │
        ▼
Tokens de design      RedesignTokens.swift (couleurs, tailles, rayons, icônes, animations)
```

### Fichiers créés

Dossier `Swiftfin/Views/VideoPlayer/PlayerRedesign/` (cible iOS uniquement, synchronisé automatiquement par Xcode, donc pas de modification du `project.pbxproj`) :

| Fichier | Rôle |
|---|---|
| `PlayerRedesign.swift` | Point d'entrée. `PlayerRedesign.Controls` choisit entre le nouvel overlay et l'overlay d'origine. Déclare la clé de réglage `playerRedesignEnabled` et l'interrupteur `SettingsToggle`. |
| `RedesignTokens.swift` | **Le seul fichier à modifier pour retoucher l'esthétique** : couleurs, tailles, marges, rayons, typographie, ombres, icônes SF Symbols, animations. |
| `RedesignStrings.swift` | Textes propres à la refonte (libellés VoiceOver en français, abréviations). Les textes déjà traduits par upstream viennent de `L10n`. |
| `RedesignedControls.swift` | Assemblage : fond, barre haute, timeline, rangée de contrôles, panneaux. Réutilise `VideoPlayerControlsLayout` (upstream) pour les safe areas, le tiroir Info / Épisodes, les actions « Passer l'intro » et les toasts. |
| `Adapter/PlayerAdapter.swift` | **Seul fichier qui lit l'état upstream.** Expose titre, temps, visibilité, pistes, vitesses, débits, et des actions qui appellent les fonctions upstream. |
| `Adapter/StreamFormatting.swift` | Mise en forme des libellés (`EN`, `Français`, `Dolby Digital+ 5.1 · par défaut`, `1,25×`, `6:28`). Pur affichage. |
| `Adapter/UpstreamViews.swift` | Vues upstream réutilisées telles quelles : boutons du menu « ⋯ », tiroir Info / Épisodes, actions de superposition, toast, vignette trickplay, raccourcis clavier. |
| `Components/Buttons.swift` | Pastille, bouton icône, retour visuel à l'appui. |
| `Components/TopBar.swift` | Bouton fermer rond, titre, « Saison X · Épisode Y ». |
| `Components/Timeline.swift` | Temps écoulé / restant, fil, curseur, aperçu au scrub. Le geste est le `SliderContainer` upstream (même scrub lent, mêmes marges tactiles) ; seul le dessin (`TrackStyle`) est nouveau. |
| `Components/ControlsRow.swift` | Transport (épisode précédent, −15 s, lecture/pause, +15 s, épisode suivant) et pastilles Audio, Sous-titres, Vitesse, Qualité, Remplir l'écran, « ⋯ ». |
| `Components/SettingsPanel.swift` | Panneaux custom ancrés au-dessus de leur pastille (remplacent les `Menu` natifs). |
| `Components/MoreMenu.swift` | Pastille « ⋯ » : menu natif contenant les boutons upstream sans place dédiée (PiP, verrouillage des gestes, lecture auto, décalages audio / sous-titres, chapitres, Chromecast). |
| `Components/VideoBackdrop.swift` | Voile bas, assombrissement en pause, filet de progression quand les contrôles sont masqués. |

Autres fichiers créés :

| Fichier | Rôle |
|---|---|
| `Shared/Views/VideoPlayer/PlayerRedesignTVOSShim.swift` | Donne à tvOS les mêmes noms (`PlayerRedesign.Controls`, `PlayerRedesign.isActive`) pour que les points d'accroche partagés restent sur une ligne. tvOS garde son overlay d'origine. |
| `docs/player-redesign/MAINTENANCE.md` | Ce document. |

## Fichiers upstream modifiés

Retrouver toutes les modifications : `git grep -n "REDESIGN:" -- ':!Swiftfin/Views/VideoPlayer/PlayerRedesign' ':!docs'`

| Fichier | Modification | Raison |
|---|---|---|
| `Shared/Views/VideoPlayer/VideoPlayer.swift` | `PlaybackControls()` remplacé par `PlayerRedesign.Controls()` | Point d'injection unique de l'overlay. `PlayerRedesign.Controls` affiche l'overlay d'origine quand l'interrupteur est coupé. |
| `Shared/Views/VideoPlayer/Container/VideoPlayer+Container.swift` | Une condition ajoutée à `shouldPresentDimOverlay` | Upstream assombrit l'image de 50 % dès que les contrôles s'affichent. La refonte dessine son propre voile (dégradé bas, 45 % en pause). L'assombrissement upstream reste actif quand un écran Info / Épisodes est ouvert. |
| `Shared/Views/SettingsView/ExperimentalSettingsView.swift` | `PlayerRedesign.SettingsToggle()` ajouté dans le bloc iOS | Interrupteur « Nouveau lecteur (iPad) » dans Réglages › Expérimental. |

### Autres personnalisations du fork (hors refonte)

Ces commits sont sur `main` (voir « Branches » plus bas). `Info.plist` porte le marqueur `FORK:` ; les fichiers JSON n'acceptent pas de commentaire.

| Fichier | Modification | Raison |
|---|---|---|
| `README.md` | Encadré ajouté tout en haut | Explique que Jellyswift est un fork non officiel pour refondre le player iPad. En cas de conflit, garder l'encadré au-dessus du contenu upstream. |
| `Swiftfin/Resources/Info.plist` | `CFBundleDisplayName` : `$(PRODUCT_NAME)` remplacé par `Jellyswift` | Nom affiché sur l'écran d'accueil, pour ne pas confondre avec l'app officielle. `PRODUCT_NAME` (nom du module Swift) n'est pas touché. Conflit possible seulement si upstream modifie cette ligne : garder `Jellyswift`. |
| `Swiftfin/Resources/AppIcons/AppIcon-dark-blue.icon/` | Ajout de `Assets/Jellyswift.png` ; dans `icon.json`, `"image-name"` passe de `Glyph.svg` à `Jellyswift.png` | Icône principale de l'app (« Bleu » est l'icône par défaut upstream). `Glyph.svg` est conservé pour limiter les conflits. Pas de modification du `project.pbxproj`. |
| `Swiftfin/Resources/Assets.xcassets/AppIcon-dark-blue.imageset/` | `AppIcon-dark-blue.svg` remplacé par `Jellyswift.png` dans `Contents.json` | Aperçu de l'icône dans Réglages › Icône de l'app. L'ancien SVG est supprimé (sinon Xcode avertit d'un fichier non assigné). En cas de conflit « modifié / supprimé » sur ce SVG : garder la suppression. |

L'icône source (1024 × 1024, recadrée sur le carré arrondi, sans transparence) est `AppIcon-dark-blue.icon/Assets/Jellyswift.png`. Pour la changer, remplacer ce fichier et l'aperçu `Jellyswift.png` de l'imageset (512 × 512). Dans le sélecteur d'icônes de l'app, elle garde le libellé « Bleu ».

## Dépendances upstream de l'adaptateur

Ce sont les API qui peuvent casser lors d'une mise à jour. Toutes sont utilisées dans `Adapter/` et `RedesignedControls.swift` uniquement.

**`MediaSession`** : `item`, `playbackItem`, `player`, `queue` (`previousItem`, `nextItem`), `playbackRequestStatus`, `setPlaybackRequestStatus(status:)`, `activity`, `playbackState.isBuffering`, `canControlPlayback`, `canSeek`, `seconds`, `seek(by:)`, `rate`, `effectiveRate`, `playNewItem(intent:)`, `setBitrate(bitrate:)`, `setResolution(resolution:)`, `isRemotePlayback`, `stop()`, `state`.

**`VideoPlayer.ViewState`** : `visibleElements` (`.toolbar`, `.playbackButtons`, `.dimming`, `.supplements`), `presentation`, `isPresentingProgress`, `isPresentingControls`, `isPresentingSupplement`, `selectedSupplementID`, `isScrubbing`, `scrubbedSeconds`, `beginScrub()`, `commitScrub()`, `cancelScrub()`, `isVideoEnlarged`, `toggleAspectFillBehavior()`, `setInteraction(.menu(_:), active:)`, `presentGuestSupplement(_:)`, `supplements`, `isTabletop`, `systemInsets`, `playbackButtonsInsets`, `supplementHeight`, `supplementVisibleHeight`, `toastProxy`.

**`MediaPlayerItem`** : `audioStreams`, `selectedAudioStreamIndex`, `subtitleStreams`, `secondarySubtitleStreams`, `subtitlesEnabled`, `subtitleTrackIndex(secondary:)`, `setSubtitleTrack(index:secondary:)`, `setSubtitlesEnabled(_:)`, `supportsSecondarySubtitles`, `configuration.requestedBitrate`, `configuration.maxResolution`, `mediaSource`, `baseItem`, `resumingIntent(at:)`, `previewImageProvider`.

**Vues et types réutilisés** : `VideoPlayerControlsLayout`, `SliderContainer` / `SliderContainerStyle`, `VideoPlayer.UIContainerViewController.SupplementContainerView`, `VideoPlayer.OverlayActions`, `OverlayToastContent`, `VideoPlayer.PlaybackControls.PreviewImageView`, `VideoPlayer.KeyCommandsModifier`, `VideoPlayer.PlaybackControls.Toolbar.ActionButtons.*` (boutons du menu « ⋯ » et `PlaybackSettings.isAvailable(for:)`), `PlaybackAdjustmentSupplement.playbackSpeed(range:)`, `EmptyHitTestView`.

**Réglages** : `Defaults[.VideoPlayer.jumpBackwardInterval]`, `jumpForwardInterval`, `Playback.rates`, `barActionButtons`, `menuActionButtons`, `Experimental.chromecast`.

**Logique copiée à revérifier** : `PlayerAdapter.isMoreActionAvailable(_:)` reprend les filtres de `ActionButtons.resolvedActionButtons` (upstream). Si upstream ajoute un bouton ou change un filtre, mettre ce filtre à jour, ainsi que le `switch` de `UpstreamAction` dans `UpstreamViews.swift`.

## Interrupteur

- Réglages › Expérimental › **Nouveau lecteur (iPad)**. Activé par défaut. Stocké dans `UserDefaults(suiteName: "swiftfinApp")`, clé `playerRedesignEnabled`.
- Désactivé, ou sur iPhone, le player affiche l'overlay d'origine sans aucune différence. La seule autre modification active est l'assombrissement, qui ne change que si la refonte est active.

## Branches

Repo : https://github.com/doudoun/jellyswift (fork de `jellyfin/Swiftfin`).

| Branche | Contenu | Mise à jour |
|---|---|---|
| `main` | Upstream + identité du fork (README, nom Jellyswift, icône) | **Merge** d'upstream : pas de réécriture d'historique, le bouton GitHub « Sync fork » marche aussi. |
| `player-redesign` | `main` + commits de la refonte, petits et atomiques | **Rebase** sur `main` : les commits de la refonte restent groupés au-dessus. **C'est cette branche qu'on compile pour l'iPad.** |

## Procédure de mise à jour

Pré-requis, une seule fois (à faire valider avant de toucher aux remotes) :

```bash
git remote add upstream https://github.com/jellyfin/Swiftfin.git
git config rerere.enabled true   # git rejoue les résolutions de conflit déjà faites
```

À chaque mise à jour :

1. Mettre à jour `main` du fork.
   ```bash
   git fetch upstream --tags
   git switch main
   git merge upstream/main      # ou un tag de release : git merge vX.Y.Z
   git push origin main
   ```
   Conflits possibles seulement sur les fichiers de la section « Autres personnalisations du fork ».
2. Rejouer la refonte sur la nouvelle base, d'abord sur une branche jetable.
   ```bash
   git switch -c player-redesign-try player-redesign
   git rebase main
   ```
3. Conflits attendus, et seulement à ces endroits :
   - `VideoPlayer.swift` : garder la ligne `PlayerRedesign.Controls() // REDESIGN:` à la place de l'appel à l'overlay, quel que soit son nouveau nom.
   - `VideoPlayer+Container.swift` : remettre la condition `// REDESIGN:` sur la propriété qui gère l'assombrissement.
   - `ExperimentalSettingsView.swift` : remettre la ligne `PlayerRedesign.SettingsToggle()` dans le bloc iOS.
   Puis `git add <fichier>` et `git rebase --continue`.
4. Compiler. Si la compilation casse dans `PlayerRedesign/`, corriger d'abord `Adapter/PlayerAdapter.swift` et `Adapter/UpstreamViews.swift` (voir la liste des dépendances ci-dessus). Upstream exige un Xcode qui fournit le SDK iOS 27.1 ou plus récent (`reservedRegions` dans `VideoPlayer+LayoutView.swift`).
   ```bash
   xcodebuild -project Swiftfin.xcodeproj -scheme Swiftfin \
     -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
     -skipMacroValidation -skipPackagePluginValidation build CODE_SIGNING_ALLOWED=NO
   ```
5. Faire les tests manuels ci-dessous.
6. Si tout passe, déplacer la branche : `git switch player-redesign && git reset --hard player-redesign-try`, puis `git push --force-with-lease origin player-redesign`. Supprimer la branche jetable.

## Tests manuels après chaque mise à jour

Sur iPad, en paysage, avec un épisode de série qui a plusieurs pistes audio et sous-titres :

- [ ] Toucher l'image affiche / masque les contrôles ; masquage auto en lecture, jamais en pause.
- [ ] Double-tap gauche / droite : −15 s / +15 s (geste upstream).
- [ ] Lecture / pause ; l'icône et le libellé VoiceOver changent.
- [ ] −15 s / +15 s ; épisode précédent / suivant (désactivés en début / fin de file).
- [ ] Glisser sur le fil : curseur agrandi, temps mis à jour, aperçu trickplay (ou puce de temps seule) ; descendre le doigt active le scrub lent ; relâcher reprend à la bonne position.
- [ ] Pastille Audio : liste des pistes, la sélection change la piste et la pastille (`EN`, `FR`).
- [ ] Pastille Sous-titres : « Aucun » coupe ; une piste active ; la pastille suit.
- [ ] Pastille Vitesse : la vitesse change ; « Personnalisée » ouvre l'écran upstream.
- [ ] Pastille Qualité : débit, résolution (et version si plusieurs) ; la lecture reprend au même endroit.
- [ ] Un seul panneau ouvert à la fois ; tap à l'extérieur le ferme ; les contrôles ne se masquent pas tant qu'il est ouvert.
- [ ] Remplir l'écran / adapter.
- [ ] Menu « ⋯ » : PiP, verrouillage des gestes, lecture auto, décalages, chapitres.
- [ ] Onglets Info / Épisodes sous la rangée ; glisser vers le haut ouvre le tiroir ; le bouton fermer devient une flèche vers le bas.
- [ ] « Passer l'intro » apparaît au bon endroit.
- [ ] Pause : image assombrie, contrôles visibles.
- [ ] Contrôles masqués : filet de progression collé au bas de l'image, qui avance.
- [ ] Fin d'épisode : passage au suivant (lecture auto).
- [ ] Fermer le player ; reprise au bon endroit en relançant.
- [ ] Couper l'interrupteur : l'overlay d'origine revient à l'identique.
- [ ] iPhone : overlay d'origine.

## Si une mise à jour casse le player

1. **Repli immédiat** : Réglages › Expérimental › couper « Nouveau lecteur (iPad) ». L'overlay d'origine revient sans recompiler.
2. **La compilation casse** : regarder d'abord `Adapter/PlayerAdapter.swift`, puis `Adapter/UpstreamViews.swift`, puis `RedesignedControls.swift` (signature de `VideoPlayerControlsLayout`). Les composants visuels ne lisent que l'adaptateur.
3. **Un bouton ne fait plus la bonne chose** : comparer l'action dans `PlayerAdapter.swift` avec le bouton upstream correspondant dans `Shared/Views/VideoPlayer/Components/Toolbar/ActionButtons/` ou `Swiftfin/Views/VideoPlayer/PlaybackControls/`, et recopier le nouvel appel.
4. **Upstream a refondu le player en profondeur** (nouveau point d'injection, `ViewState` renommé) : en dernier recours, mettre `default: false` à `playerRedesignEnabled` dans `PlayerRedesign.swift` pour publier une version sans la refonte, le temps de réadapter l'adaptateur.

## Écarts assumés avec la maquette

- **Sous-titres** : ils ne remontent pas au-dessus des contrôles et ne disparaissent pas en pause. Ils sont dessinés par le moteur vidéo (mpv / AVPlayer) ; les déplacer serait un changement de comportement dans du code upstream sensible.
- **Masquage automatique** : délai upstream (5 s), pas 4 s.
- **Zone « chargée » de la timeline** : upstream n'expose pas la valeur du buffer ; elle n'est pas dessinée.
- **Info / Épisodes** : fonctionnement upstream conservé (onglets sous la rangée de contrôles, tiroir qui monte), à la demande de l'utilisateur. Le groupe gauche de la maquette n'est donc pas dessiné.
- **Scrub** : upstream masque tout sauf la barre pendant le glissement ; la refonte garde l'overlay visible si le glissement part des contrôles (choix visuel, aucun état modifié).
- **Vitesses** : la liste vient du réglage de l'app, pas d'une liste figée.
- **Police** : SF Pro (système) à la place d'Inter. Tailles fixes, pas de Dynamic Type sur l'overlay (place limitée sur la rangée).
