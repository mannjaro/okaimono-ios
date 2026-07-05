import CoreData

enum IngredientNameSuggestions {
    static let maxSuggestions = 5

    static func suggestions(
        from allIngredients: [Ingredient],
        matching query: String,
        excluding namesInCurrentMenu: [String] = []
    ) -> [String] {
        let normalizedQuery = query.normalizedForIngredientMatch
        guard !normalizedQuery.isEmpty else { return [] }

        var uniqueNames: [String: String] = [:]
        for ingredient in allIngredients {
            guard let name = ingredient.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { continue }
            let key = name.normalizedForIngredientMatch
            if uniqueNames[key] == nil {
                uniqueNames[key] = name
            }
        }

        let excludedKeys = Set(namesInCurrentMenu.map(\.normalizedForIngredientMatch))

        return uniqueNames
            .filter { key, _ in
                key.hasPrefix(normalizedQuery) && !excludedKeys.contains(key)
            }
            .map(\.value)
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .prefix(maxSuggestions)
            .map { $0 }
    }
}
