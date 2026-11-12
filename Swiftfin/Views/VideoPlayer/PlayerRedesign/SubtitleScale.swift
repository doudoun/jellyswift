//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Observation
import SwiftUI

// REDESIGN: User subtitle size, on top of the system caption style.
//
// Upstream `TextSubtitleOverlay` multiplies its base point size by
// `PlayerRedesign.subtitleScale` (one-line hook). The value is observable,
// so subtitles resize live while the user taps − / +.

extension PlayerRedesign {

    /// Factor applied to subtitles. 1 when the redesign is off.
    @MainActor
    static var subtitleScale: CGFloat {
        isActive ? SubtitleScale.shared.value : 1
    }

    @MainActor
    @Observable
    final class SubtitleScale {

        static let shared = SubtitleScale()

        private typealias Range = Tokens.SubtitleSize

        private(set) var value: Double {
            didSet { Defaults[.playerRedesignSubtitleScale] = value }
        }

        private init() {
            value = Self.clamped(Defaults[.playerRedesignSubtitleScale])
        }

        var canIncrease: Bool {
            value < Range.maximum - 0.001
        }

        var canDecrease: Bool {
            value > Range.minimum + 0.001
        }

        func increase() {
            value = Self.clamped(value + Range.step)
        }

        func decrease() {
            value = Self.clamped(value - Range.step)
        }

        func reset() {
            value = 1
        }

        /// Clamps to the allowed range and snaps to the step, so repeated taps never drift.
        private static func clamped(_ value: Double) -> Double {
            let snapped = (value / Range.step).rounded() * Range.step
            return min(max(snapped, Range.minimum), Range.maximum)
        }
    }
}

extension Defaults.Keys {

    static let playerRedesignSubtitleScale = Defaults.Key<Double>(
        "playerRedesignSubtitleScale",
        default: 1,
        suite: .appSuite
    )
}
