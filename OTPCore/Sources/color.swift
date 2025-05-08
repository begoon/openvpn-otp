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
        let attributed = highlightIPs(in: String(match.2))
        return (Text(attributed).foregroundColor(color), color)
    }
    let attributed = highlightIPs(in: string)
    return (Text(attributed), nil)
}

public func highlightIPs(in input: String) -> AttributedString {
    var attributed = AttributedString(input)
    let re = /(\d+\.\d+\.\d+\.\d+)/
    for match in input.matches(of: re) {
        if let range = Range(match.range, in: attributed) {
            attributed[range].underlineStyle = .single
            attributed[range].foregroundColor = .blue
        }
    }
    return attributed
}
