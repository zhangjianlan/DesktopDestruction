enum CharacterSprites {
    private static let animals: [String: String] = [
        "🐶": "animal-dog",
        "🐕": "animal-dog",
        "🐩": "animal-dog",
        "🦮": "animal-dog",
        "🐰": "animal-rabbit",
        "🐇": "animal-rabbit",
        "🐻": "animal-bear",
        "🐻‍❄️": "animal-bear",
        "🐼": "animal-panda",
        "🐮": "animal-cow",
        "🐄": "animal-cow",
        "🐷": "animal-pig",
        "🐖": "animal-pig",
        "🐸": "animal-frog",
        "🐵": "animal-monkey",
        "🐔": "animal-chicken",
        "🐓": "animal-chicken",
        "🐤": "animal-chick",
        "🐥": "animal-chick",
        "🐦": "animal-chick",
        "🐦‍⬛": "animal-chick",
        "🐧": "animal-penguin",
        "🦆": "animal-duck",
        "🦉": "animal-owl",
        "🦅": "animal-owl",
        "🐴": "animal-horse",
        "🐎": "animal-horse",
        "🦄": "animal-horse",
        "🐍": "animal-snake",
        "🐊": "animal-crocodile",
        "🐘": "animal-elephant",
        "🦣": "animal-elephant",
        "🦛": "animal-hippo",
        "🦏": "animal-rhino",
        "🦒": "animal-giraffe",
        "🦓": "animal-zebra",
        "🦭": "animal-walrus",
        "🐐": "animal-goat",
        "🐏": "animal-goat",
        "🐑": "animal-goat",
        "🦌": "animal-moose",
        "🐃": "animal-buffalo",
        "🐂": "animal-buffalo",
        "🦍": "animal-gorilla",
        "🦧": "animal-gorilla",
        "🦥": "animal-sloth",
        "🦚": "animal-parrot",
        "🦜": "animal-parrot",
        "🕊️": "animal-owl",
        "🐳": "animal-whale",
        "🐋": "animal-whale",
        "🦈": "animal-whale",
        "🐬": "animal-whale"
    ]

    static func animal(for emoji: String) -> String? {
        animals[emoji]
    }

    static func person(for species: PersonSpecies) -> String {
        switch species {
        case .zombie:
            return "character-zombie-small"
        case .villain:
            return "character-soldier"
        case .runner, .blackRunner, .hero, .blackHero, .ninja:
            return "character-runner"
        case .astronaut, .astronautWoman:
            return "character-robot"
        case .wizard, .clown, .dancer, .blackDancer:
            return "character-adventurer"
        case .woman, .blondeWoman, .redHairWoman, .businessWoman, .scientistWoman,
             .singerWoman, .teacherWoman, .pregnantWoman, .princess, .blackWoman:
            return "character-female"
        default:
            return "character-male"
        }
    }

    static func zombie(tier: Int) -> String {
        switch tier {
        case 1:
            return "character-zombie-small"
        case 2:
            return "character-zombie-medium"
        case 3:
            return "character-zombie-large"
        default:
            return "character-zombie-brute"
        }
    }
}
