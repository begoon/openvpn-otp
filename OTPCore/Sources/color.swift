import SwiftUI

let colors: [String: Color] = [
    "red": .red, "orange": .orange, "yellow": .yellow, "green": .green,
    "mint": .mint, "teal": .teal, "cyan": .cyan, "blue": .blue,
    "indigo": .indigo, "purple": .purple, "pink": .pink, "brown": .brown,
    "white": .white, "gray": .gray, "black": .black,
]

public func colored(_ string: String) -> (Text, Color?) {
    let regex = /^@(\w+):(.*)/
    if let match = string.firstMatch(of: regex), let color = colors[String(match.1)] {
        return (Text(match.2).foregroundColor(color), color)
    }
    return (Text(verbatim: string), nil)
}
