import SwiftUI

// see https://github.com/sindresorhus/Plash/blob/4ebd13ba47632aba072ad4abe4ace9a2b7b3539c/Plash/Utilities.swift#L533

extension String {
        
    var trimmedTrailing: Self {
        replacingOccurrences(of: #"\s+$"#, with: "", options: .regularExpression)
    }
    
    func truncating(to number: Int, truncationIndicator: Self = "…") -> Self {
        if number <= 0 {
            return ""
        } else if count > number {
            return Self(prefix(number - truncationIndicator.count)).trimmedTrailing + truncationIndicator
        } else {
            return self
        }
    }
    
    func wrapped(atLength length: Int) -> Self {
        var string = ""
        var currentLineLength = 0

        for word in components(separatedBy: .whitespaces) {
            let wordLength = word.count

            if currentLineLength + wordLength + 1 > length {
                // Can't wrap as the word is longer than the line.
                if wordLength >= length {
                    string += word
                }

                string += "\n"
                currentLineLength = 0
            }

            currentLineLength += wordLength + 1
            string += "\(word) "
        }

        return string
    }
}

enum MyApp {
    static let isFirstLaunch: Bool = {
        let key = "hasLaunched"
        
        if UserDefaults.standard.bool(forKey: key) {
            return false
        } else {
            UserDefaults.standard.set(true, forKey: key)
            return true
        }
    }()
}


