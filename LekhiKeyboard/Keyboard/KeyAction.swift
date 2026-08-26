//
//  KeyAction.swift
//  LekhiKeyboard
//
//  User actions emitted by the mechanical keyboard layer.
//

import Foundation

public enum KeyAction: Equatable, Sendable {
    /// A printable character (a-z, A-Z, 0-9, punctuation).
    case character(Character)

    /// Insert an arbitrary text string (e.g. multi-scalar emoji).
    case insertText(String)

    /// Delete one character. `word == true` deletes the whole
    /// pre-edit buffer (cmd-backspace equivalent).
    case backspace(word: Bool)

    /// Insert a literal space and commit the active session.
    case space

    /// Insert a newline and commit the active session.
    case `return`

    /// Toggle the shift state (uppercase / lowercase).
    case shift

    /// Switch between letters ("ABC") and numbers/symbols ("123").
    case switchLayout

    /// Switch between numbers ("123") and special symbols ("#+=").
    case switchSymbols

    /// Switch to next system keyboard (Globe).
    case nextKeyboard

    /// Switch to Emoji mode.
    case emoji

    /// Microphone / Dictation key.
    case mic

    /// No-op placeholder.
    case noop
}
