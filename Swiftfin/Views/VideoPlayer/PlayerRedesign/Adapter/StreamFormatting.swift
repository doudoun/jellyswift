//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// REDESIGN: Turns upstream track data into the short labels of the redesign
// ("EN", "Français", "Dolby Digital+ 5.1 · par défaut", "1,25×").
// Display only: no state is read or written here.

extension PlayerRedesign {

    enum StreamFormatting {

        private static func language(of stream: MediaStream) -> Locale.Language? {
            guard let code = stream.language?.nilIfBlank, code.lowercased() != "und" else { return nil }

            return Locale.Language(identifier: code)
        }

        /// Two-letter uppercase code, e.g. "EN".
        static func shortLanguage(_ stream: MediaStream) -> String {
            if let alpha2 = language(of: stream)?.languageCode?.identifier(.alpha2) {
                return alpha2.uppercased()
            }

            if let code = stream.language?.nilIfBlank, code.lowercased() != "und" {
                return String(code.prefix(3)).uppercased()
            }

            return String(languageName(stream).prefix(2)).uppercased()
        }

        /// Localized language name, e.g. "Français", "English" (system language).
        static func languageName(_ stream: MediaStream) -> String {
            if let code = language(of: stream)?.languageCode?.identifier,
               let name = Locale.current.localizedString(forLanguageCode: code) {
                return name.localizedCapitalized
            }

            if let name = stream.localizedLanguage?.nilIfBlank ?? stream.title?.nilIfBlank {
                return name
            }

            return stream.displayTitle ?? L10n.unknown
        }

        static func audioDetail(_ stream: MediaStream) -> String? {
            var parts: [String] = []

            let format = [codecName(stream.codec, profile: stream.profile), stream.channelLayout.map(channelName)]
                .compactMap(\.self)
                .joined(separator: " ")

            if format.isNotEmpty {
                parts.append(format)
            }

            if stream.isDefault == true {
                parts.append(Strings.isDefault)
            }

            return parts.isEmpty ? nil : parts.joined(separator: " · ")
        }

        static func subtitleTitle(_ stream: MediaStream) -> String {
            var title = languageName(stream)

            if stream.isForced == true {
                title += " \(Strings.forced)"
            }

            if stream.isHearingImpaired == true {
                title += " SDH"
            }

            return title
        }

        static func subtitleDetail(_ stream: MediaStream) -> String? {
            var parts: [String] = []

            if let title = stream.title?.nilIfBlank,
               title.localizedCaseInsensitiveCompare(languageName(stream)) != .orderedSame {
                parts.append(title)
            }

            if stream.isDefault == true {
                parts.append(Strings.isDefault)
            }

            return parts.isEmpty ? nil : parts.joined(separator: " · ")
        }

        /// "1×", "1,25×" using the current locale.
        static func rate(_ rate: Double) -> String {
            let formatted = rate.formatted(.number.precision(.fractionLength(0 ... 2)))
            return "\(formatted)×"
        }

        /// "6:28", "1:02:03".
        static func time(_ duration: Duration) -> String {
            let total = max(0, Int(duration.seconds.rounded(.down)))
            let hours = total / 3600
            let minutes = (total % 3600) / 60
            let seconds = total % 60

            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            }

            return String(format: "%d:%02d", minutes, seconds)
        }

        /// "−18:34" (true minus sign).
        static func remaining(_ duration: Duration) -> String {
            "\u{2212}\(time(duration))"
        }

        private static func codecName(_ codec: String?, profile: String?) -> String? {
            guard let codec = codec?.lowercased().nilIfBlank else { return nil }

            switch codec {
            case "eac3": return "Dolby Digital+"

            case "ac3": return "Dolby Digital"

            case "truehd": return "Dolby TrueHD"

            case "dts":
                if let profile, profile.localizedCaseInsensitiveContains("MA") {
                    return "DTS-HD MA"
                }
                return "DTS"

            case "aac": return "AAC"

            case "flac": return "FLAC"

            case "opus": return "Opus"

            case "mp3": return "MP3"

            case "vorbis": return "Vorbis"

            default: return codec.uppercased()
            }
        }

        private static func channelName(_ layout: String) -> String {
            switch layout.lowercased() {
            case "stereo": "2.0"
            case "mono": "1.0"
            default:
                // "5.1(side)" -> "5.1"
                layout.components(separatedBy: "(").first ?? layout
            }
        }
    }
}
