//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

// REDESIGN: User-facing strings specific to the redesign.
// Strings that upstream already localizes are taken from `L10n` instead.
// These live here, not in Localizable.strings, so upstream translation
// updates never conflict with the fork.

// swiftlint:disable hard_coded_display_string

extension PlayerRedesign {

    enum Strings {

        static let settingsToggle = "Nouveau lecteur (iPad)"

        static let close = "Fermer"
        static let play = "Lecture"
        static let pause = "Pause"
        static let previousEpisode = "Épisode précédent"
        static let nextEpisode = "Épisode suivant"
        static let fillScreen = "Remplir l'écran"
        static let fitScreen = "Adapter à l'écran"
        static let more = "Plus d'options"

        static let audio = "Audio"
        static let subtitles = "Sous-titres"
        static let speed = "Vitesse"
        static let quality = "Qualité"

        static let none = "Aucun"
        static let subtitlesOffShort = "Non"
        static let automatic = "Automatique"
        static let automaticShort = "Auto"
        static let maximumShort = "Max"
        static let isDefault = "par défaut"
        static let forced = "forcé"

        static let bitrate = "Débit"
        static let resolution = "Résolution"
        static let version = "Version"
        static let primaryTrack = "Piste principale"
        static let secondaryTrack = "Piste secondaire"

        static func jumpBackward(_ seconds: Int) -> String {
            "Reculer de \(seconds) secondes"
        }

        static func jumpForward(_ seconds: Int) -> String {
            "Avancer de \(seconds) secondes"
        }

        static func seasonEpisode(season: Int, episode: Int) -> String {
            "Saison \(season) · Épisode \(episode)"
        }

        /// VoiceOver label for a settings pill, e.g. "Audio, English".
        static func pill(_ title: String, value: String) -> String {
            "\(title), \(value)"
        }
    }
}

// swiftlint:enable hard_coded_display_string
