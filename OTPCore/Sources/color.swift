import SwiftUI

let colors: [String: Color] = [
    "red": .red, "orange": .orange, "yellow": .yellow, "green": .green,
    "mint": .mint, "teal": .teal, "cyan": .cyan, "blue": .blue,
    "indigo": .indigo, "purple": .purple, "pink": .pink, "brown": .brown,
    "white": .white, "gray": .gray, "black": .black,
]

let regex = try! NSRegularExpression(pattern: "^@(\\w+):(.*)", options: [])

public func colored(_ string: String) -> (Text, Color?) {
    if let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) {
        let range = Range(match.range(at: 1), in: string)!
        if let color = colors[String(string[range])] {
            let range = Range(match.range(at: 2), in: string)!
            return (Text(string[range]).foregroundColor(color), color)
        }
    }
    return (Text(verbatim: string), nil)
}
