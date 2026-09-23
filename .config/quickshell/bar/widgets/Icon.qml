import QtQuick
import qs

// Nerd Font glyph. Set `code` to the codepoint (e.g. 0xf303).
Text {
    property int code: 0

    text: String.fromCodePoint(code)
    color: Theme.fg
    font.family: Theme.iconFont
    font.pixelSize: Theme.iconSize
    horizontalAlignment: Text.AlignHCenter
}
