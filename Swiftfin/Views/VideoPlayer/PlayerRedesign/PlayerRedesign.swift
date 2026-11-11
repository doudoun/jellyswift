//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// REDESIGN: Entry point of the redesigned iPad player overlay.
//
// Everything specific to the redesign lives in this folder. Upstream code
// only references `PlayerRedesign.Controls`, `PlayerRedesign.isActive` and
// `PlayerRedesign.SettingsToggle`. See docs/player-redesign/MAINTENANCE.md.

enum PlayerRedesign {

    /// The redesign targets iPad only. iPhone always keeps the upstream overlay.
    static var isSupportedDevice: Bool {
        UIDevice.isPad
    }

    /// `true` when the redesigned overlay replaces the upstream one.
    static var isActive: Bool {
        isSupportedDevice && Defaults[.playerRedesignEnabled]
    }

    /// Replaces `VideoPlayer.PlaybackControls()` at the single injection point.
    /// Falls back to the untouched upstream overlay when the switch is off.
    struct Controls: View {

        @Default(.playerRedesignEnabled)
        private var isEnabled

        @ContentBuilder
        var body: some View {
            if isEnabled, PlayerRedesign.isSupportedDevice {
                RedesignedControls()
            } else {
                VideoPlayer.PlaybackControls()
            }
        }
    }

    /// Switch shown in Settings > Experimental.
    struct SettingsToggle: View {

        @Default(.playerRedesignEnabled)
        private var isEnabled

        @ContentBuilder
        var body: some View {
            if PlayerRedesign.isSupportedDevice {
                Toggle(Strings.settingsToggle, isOn: $isEnabled)
            }
        }
    }
}

extension Defaults.Keys {

    /// Declared here, not in `SwiftfinDefaults.swift`, so upstream files stay untouched.
    static let playerRedesignEnabled = Defaults.Key<Bool>(
        "playerRedesignEnabled",
        default: true,
        suite: .appSuite
    )
}
