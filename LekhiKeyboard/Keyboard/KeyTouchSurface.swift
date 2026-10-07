//
//  KeyTouchSurface.swift
//  LekhiKeyboard
//
//  One UIKit view laid over the whole key grid that receives every touch
//  meant for a key. It decides which key a finger landed on, fires that key
//  on touch-down, and drives the press visuals, backspace auto-repeat and the
//  spacebar language swipe.
//
//  This used to be a `DragGesture` on each keycap. SwiftUI gestures go
//  through the gesture system and SwiftUI's own update transaction before the
//  key sees the touch, and a cancelled gesture never reported its end, which
//  left keys stuck down. `touchesBegan` on a plain view with multiple touch
//  enabled is the earliest and most direct signal iOS gives a keyboard, and
//  every finger arrives on its own, in the order it landed.
//

import SwiftUI
import UIKit
import Observation

/// What one key draws in response to touches. One object per key, observed
/// only by that key, so a press re-renders exactly one keycap.
///
/// Each property stores its new value *before* telling observers, the
/// reverse of what `@Observable` generates. These writes come from UIKit
/// touch handling, outside SwiftUI's update cycle, and there SwiftUI can
/// re-render synchronously from inside the change notification. With the
/// generated order that re-render read the old value and, having already
/// been notified, never looked again: a quick tap left its key drawn down.
@Observable
public final class KeyPressVisual {
    @ObservationIgnored private var _isPressed = false
    @ObservationIgnored private var _dragOffset: CGFloat = 0
    @ObservationIgnored private var _swipeForward = true

    public var isPressed: Bool {
        get { access(keyPath: \.isPressed); return _isPressed }
        set {
            guard newValue != _isPressed else { return }
            _isPressed = newValue
            withMutation(keyPath: \.isPressed) {}
        }
    }

    /// Horizontal travel of a spacebar drag, for the language-swipe label.
    public var dragOffset: CGFloat {
        get { access(keyPath: \.dragOffset); return _dragOffset }
        set {
            guard newValue != _dragOffset else { return }
            _dragOffset = newValue
            withMutation(keyPath: \.dragOffset) {}
        }
    }

    /// Which way the finger was moving when the language flip fired, so the
    /// incoming label slides in from the side it came from.
    public var swipeForward: Bool {
        get { access(keyPath: \.swipeForward); return _swipeForward }
        set {
            guard newValue != _swipeForward else { return }
            _swipeForward = newValue
            withMutation(keyPath: \.swipeForward) {}
        }
    }

    public init() {}
}

/// Hands each key the same `KeyPressVisual` for as long as it exists, so a
/// re-render of the grid (shift, a layout change) does not orphan a press.
final class KeyPressVisuals {
    private var visuals: [String: KeyPressVisual] = [:]

    func visual(for id: String) -> KeyPressVisual {
        if let existing = visuals[id] { return existing }
        let created = KeyPressVisual()
        visuals[id] = created
        return created
    }
}

/// A key as the touch surface sees it.
struct KeyTouchTarget {
    let id: String
    let action: KeyAction
    let kind: KeyKind
    /// Where the cap is drawn, in the surface's space.
    let frame: CGRect
    /// The cap grown over its share of the gaps around it. The targets of a
    /// grid tile it, so there is no point between keys a tap can miss.
    let hitRect: CGRect
    /// Only the spacebar, and only with more than one layout turned on.
    let swipesLanguage: Bool
}

/// Hosts `KeyTouchView` in the SwiftUI grid.
struct KeyTouchSurface: UIViewRepresentable {
    let targets: [KeyTouchTarget]
    let visuals: KeyPressVisuals
    let onPress: (KeyAction) -> Void
    let onSwipeLanguage: (Bool) -> Void

    func makeUIView(context: Context) -> KeyTouchView {
        KeyTouchView()
    }

    func updateUIView(_ view: KeyTouchView, context: Context) {
        view.targets = targets
        view.visuals = visuals
        view.onPress = onPress
        view.onSwipeLanguage = onSwipeLanguage
    }
}

final class KeyTouchView: UIView {

    var targets: [KeyTouchTarget] = []
    var visuals = KeyPressVisuals()
    var onPress: (KeyAction) -> Void = { _ in }
    var onSwipeLanguage: (Bool) -> Void = { _ in }

    /// A finger that is down on a key.
    private struct Press {
        let target: KeyTouchTarget
        let start: CGPoint
        var hasSwiped = false
        var repeatTimer: Timer?
    }

    private var presses: [ObjectIdentifier: Press] = [:]

    /// Drag a spacebar press must cover before the layout flips: intentional,
    /// so it cannot fire by accident mid-sentence.
    private static let swipeDistance: CGFloat = 55

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Fast typing overlaps fingers: the next key goes down before the
        // last one is up. A view only sees one touch at a time unless it asks
        // for more, and the SwiftUI hosting view does not.
        isMultipleTouchEnabled = true
        backgroundColor = .clear
        isOpaque = false
        // VoiceOver reaches the keys through their own accessibility actions.
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Hit testing

    /// The key a point belongs to: the one whose hit area holds it, else the
    /// nearest cap, so even a touch on the very edge of the plate lands.
    func target(at point: CGPoint) -> KeyTouchTarget? {
        if let hit = targets.first(where: { $0.hitRect.contains(point) }) {
            return hit
        }
        return targets.min { distance(from: point, to: $0.frame) < distance(from: point, to: $1.frame) }
    }

    private func distance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return (dx * dx + dy * dy).squareRoot()
    }

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Several fingers can arrive in one event; strike them in the order
        // they landed so the document gets them in that order too.
        for touch in touches.sorted(by: { $0.timestamp < $1.timestamp }) {
            let point = touch.location(in: self)
            guard let target = target(at: point) else { continue }
            begin(touch, on: target, at: point)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let key = ObjectIdentifier(touch)
            guard var press = presses[key], press.target.swipesLanguage else { continue }

            let point = touch.location(in: self)
            let dx = point.x - press.start.x
            let dy = point.y - press.start.y
            let visual = visuals.visual(for: press.target.id)
            visual.dragOffset = dx

            if !press.hasSwiped, abs(dx) > Self.swipeDistance, abs(dx) > abs(dy) * 1.4 {
                press.hasSwiped = true
                presses[key] = press
                visual.swipeForward = dx > 0
                HapticManager.shared.candidateSelected()
                // The space this press emitted on touch-down is retracted by
                // the handler before it switches layouts.
                onSwipeLanguage(dx > 0)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach(end)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // A system gesture took the touch. Release the key exactly as a lift
        // would, or it stays drawn down and keeps auto-repeating.
        touches.forEach(end)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Leaving the screen mid-press (emoji panel, keyboard dismissed) never
        // delivers the touch's end; release everything here instead.
        if window == nil {
            for press in presses.values {
                press.repeatTimer?.invalidate()
                let visual = visuals.visual(for: press.target.id)
                visual.isPressed = false
                visual.dragOffset = 0
            }
            presses.removeAll()
        }
    }

    private func begin(_ touch: UITouch, on target: KeyTouchTarget, at point: CGPoint) {
        var press = Press(target: target, start: point)
        visuals.visual(for: target.id).isPressed = true
        playFeedback(for: target)

        // Every key, the spacebar included, emits on touch-down so that what
        // reaches the document is ordered by the order the keys were struck
        // in. Emitting space on touch-up reordered fast typing: roll a finger
        // off space onto the next letter and the letter's touch-down beats
        // space's touch-up, so "ami bangla" arrived as a-m-i-b-space.
        onPress(target.action)

        if case .backspace = target.action {
            press.repeatTimer = makeRepeatTimer(for: target)
        }
        presses[ObjectIdentifier(touch)] = press
    }

    private func end(_ touch: UITouch) {
        guard let press = presses.removeValue(forKey: ObjectIdentifier(touch)) else { return }
        press.repeatTimer?.invalidate()

        // Another finger may still be holding the same key.
        guard !presses.values.contains(where: { $0.target.id == press.target.id }) else { return }

        let visual = visuals.visual(for: press.target.id)
        withAnimation(.easeOut(duration: 0.08)) {
            visual.isPressed = false
        }
        if visual.dragOffset != 0 {
            // Settle the label back to rest on a spring so a swipe that
            // stopped short of the switch point eases home instead of snapping.
            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                visual.dragOffset = 0
            }
        }
    }

    /// Backspace repeats while held, at the system keyboard's cadence: a
    /// pause, then about fifteen a second. Invalidated when the finger lifts
    /// or the touch is cancelled.
    private func makeRepeatTimer(for target: KeyTouchTarget) -> Timer {
        let timer = Timer(fire: Date().addingTimeInterval(0.5), interval: 0.065, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.onPress(target.action)
            HapticManager.shared.keyPress(isAction: true)
        }
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }

    private func playFeedback(for target: KeyTouchTarget) {
        MechanicalSoundManager.shared.playKeyPress(
            isReturn: target.kind.isReturn,
            isSpace: target.kind.isSpace,
            isModifier: target.kind.isAction
        )
        HapticManager.shared.keyPress(isAction: target.kind.isAction)
    }
}
