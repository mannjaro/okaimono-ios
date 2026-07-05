import Foundation

extension String {
    /// Normalizes ingredient names for fuzzy matching (whitespace, kana, width).
    var normalizedForIngredientMatch: String {
        var result = trimmingCharacters(in: .whitespacesAndNewlines)
        if let katakana = result.applyingTransform(.hiraganaToKatakana, reverse: false) {
            result = katakana
        }
        if let halfwidth = result.applyingTransform(.fullwidthToHalfwidth, reverse: false) {
            result = halfwidth
        }
        return result.lowercased()
    }
}
