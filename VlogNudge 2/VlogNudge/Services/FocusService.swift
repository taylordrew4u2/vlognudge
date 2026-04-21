//
//  FocusService.swift
//  VlogNudge
//

import Foundation
import Intents
import Observation

@Observable
final class FocusService {
    static let shared = FocusService()

    private(set) var isInBlockingFocus: Bool = false

    private init() {}

    func requestAuthorization() async {
        let status = await withCheckedContinuation { (continuation: CheckedContinuation<INFocusStatusAuthorizationStatus, Never>) in
            INFocusStatusCenter.default.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        _ = status
        refresh()
    }

    func refresh() {
        let status = INFocusStatusCenter.default.focusStatus
        isInBlockingFocus = status.isFocused ?? false
    }
}
