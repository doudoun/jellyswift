//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// REDESIGN: "Label  [−] value [+]" row used at the bottom of a settings panel.
// Tapping the value resets it. It never closes the panel.

extension PlayerRedesign {

    struct StepperRow: View {

        let title: String
        let accessibilityTitle: String
        let value: String
        let canDecrease: Bool
        let canIncrease: Bool
        let decrease: () -> Void
        let increase: () -> Void
        let reset: () -> Void

        private typealias Colors = Tokens.Colors
        private typealias Size = Tokens.Size

        @ContentBuilder
        private func stepButton(systemImage: String, label: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.system(size: Size.stepperIcon, weight: .semibold))
                    .foregroundStyle(Colors.text)
                    .frame(width: Size.stepperButton, height: Size.stepperButton)
                    .background(Circle().fill(Colors.pill))
                    .contentShape(Circle())
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!isEnabled)
            .accessibilityLabel(label)
        }

        @ContentBuilder
        var body: some View {
            HStack(spacing: 8) {
                Text(title)
                    .font(Tokens.Typography.panelRow)
                    .foregroundStyle(Colors.text)

                Spacer(minLength: 8)

                stepButton(systemImage: Tokens.Icons.decrease, label: Strings.decrease, isEnabled: canDecrease, action: decrease)

                Button(action: reset) {
                    Text(value)
                        .font(Tokens.Typography.panelRowSelected.monospacedDigit())
                        .foregroundStyle(Colors.text)
                        .frame(minWidth: Size.stepperValueWidth, minHeight: Size.minimumHitTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle())

                stepButton(systemImage: Tokens.Icons.increase, label: Strings.increase, isEnabled: canIncrease, action: increase)
            }
            .padding(.horizontal, Tokens.Padding.panelRowHorizontal)
            .frame(height: Size.panelRowDouble)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityTitle)
            .accessibilityValue(value)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: increase()
                case .decrement: decrease()
                @unknown default: break
                }
            }
        }
    }
}
