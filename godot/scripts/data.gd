extends Node
## All game data tables (ported 1:1 from the web demo). Pure data, no logic.

const HERO_IDS = ["kael", "mira", "doran", "pip"]

var CHARS = {
	"kael": {"name": "Kael", "title": "Wayfarer", "g": {"hp": 1.25, "mp": 0.55, "str": 1.2, "mag": 0.55, "def": 1.15, "agi": 1.0},
		"skills": ["cleave", "secondwind", "rend"], "blurb": "A steady blade. Hits hard, takes hits.", "hint": "Available from the start."},
	"mira": {"name": "Mira", "title": "Mender", "g": {"hp": 0.95, "mp": 1.4, "str": 0.65, "mag": 1.3, "def": 0.95, "agi": 0.95},
		"skills": ["cure", "smite", "cura", "raise"], "blurb": "A healer who keeps the party standing.", "hint": "Defeat the Stone Warden, guardian of Floor 1."},
	"doran": {"name": "Doran", "title": "Ember", "g": {"hp": 0.82, "mp": 1.5, "str": 0.5, "mag": 1.45, "def": 0.8, "agi": 0.95},
		"skills": ["fire", "frost", "bolt", "blaze", "tempest"], "blurb": "A black-magic prodigy. Fragile, devastating.", "hint": "Find the Sealed Cell on Floor 2 and open it with a Key."},
	"pip": {"name": "Pip", "title": "Cutpurse", "g": {"hp": 1.0, "mp": 0.75, "str": 1.05, "mag": 0.7, "def": 0.9, "agi": 1.55},
		"skills": ["steal", "twinfang", "venom", "mug"], "blurb": "Quick hands, quicker feet. Steals from foes.", "hint": "A stranger in a dungeon shop owes a debt. Pay it off (99 G)."},
}

var SK = {
	"cleave": {"name": "Cleave", "lv": 1, "mp": 4, "tgt": "allEnemies", "type": "phys", "pow": 0.75, "desc": "Strike every foe."},
	"secondwind": {"name": "Second Wind", "lv": 2, "mp": 5, "tgt": "self", "type": "healPct", "pow": 0.35, "desc": "Recover 35% of max HP."},
	"rend": {"name": "Rend", "lv": 5, "mp": 7, "tgt": "enemy", "type": "phys", "pow": 1.9, "desc": "A crushing single blow."},
	"cure": {"name": "Cure", "lv": 1, "mp": 4, "tgt": "ally", "type": "heal", "pow": 12, "desc": "Restore HP to one ally."},
	"smite": {"name": "Smite", "lv": 1, "mp": 4, "tgt": "enemy", "type": "magic", "el": "holy", "pow": 9, "desc": "Holy damage to one foe."},
	"cura": {"name": "Cura", "lv": 3, "mp": 9, "tgt": "allAllies", "type": "heal", "pow": 8, "desc": "Restore HP to all allies."},
	"raise": {"name": "Raise", "lv": 5, "mp": 14, "tgt": "deadAlly", "type": "revive", "pow": 0.4, "desc": "Revive a fallen ally at 40% HP."},
	"fire": {"name": "Fire", "lv": 1, "mp": 5, "tgt": "enemy", "type": "magic", "el": "fire", "pow": 10, "desc": "Fire damage to one foe."},
	"frost": {"name": "Frost", "lv": 1, "mp": 5, "tgt": "enemy", "type": "magic", "el": "frost", "pow": 10, "desc": "Ice damage to one foe."},
	"bolt": {"name": "Bolt", "lv": 2, "mp": 5, "tgt": "enemy", "type": "magic", "el": "bolt", "pow": 10, "desc": "Lightning damage to one foe."},
	"blaze": {"name": "Blaze", "lv": 4, "mp": 12, "tgt": "allEnemies", "type": "magic", "el": "fire", "pow": 8, "desc": "Fire damage to all foes."},
	"tempest": {"name": "Tempest", "lv": 7, "mp": 20, "tgt": "allEnemies", "type": "magic", "el": "bolt", "pow": 13, "desc": "Lightning storm on all foes."},
	"steal": {"name": "Steal", "lv": 1, "mp": 0, "tgt": "enemy", "type": "steal", "desc": "Swipe gold or an item from a foe."},
	"twinfang": {"name": "Twin Fang", "lv": 2, "mp": 4, "tgt": "enemy", "type": "phys", "pow": 0.75, "hits": 2, "desc": "Two quick strikes."},
	"venom": {"name": "Venom Edge", "lv": 4, "mp": 5, "tgt": "enemy", "type": "phys", "pow": 1.0, "poison": true, "desc": "Strike and poison a foe."},
	"mug": {"name": "Mug", "lv": 6, "mp": 6, "tgt": "enemy", "type": "phys", "pow": 1.4, "steal": true, "desc": "Strike hard and steal."},
}

var ELC = {"fire": Color("#ff7a2a"), "frost": Color("#7ad8ff"), "bolt": Color("#ffe94a"), "holy": Color("#fff6c0")}

var ITEMS = {
	"potion": {"name": "Potion", "desc": "Restore 60 HP to one ally.", "tgt": "ally", "price": 15},
	"hipotion": {"name": "Hi-Potion", "desc": "Restore 180 HP to one ally.", "tgt": "ally", "price": 40},
	"ether": {"name": "Ether", "desc": "Restore 30 MP to one ally.", "tgt": "ally", "price": 30},
	"ember": {"name": "Phoenix Ember", "desc": "Revive a fallen ally at 50% HP.", "tgt": "deadAlly", "price": 55},
	"firebomb": {"name": "Firebomb", "desc": "Fire damage to all foes (battle only).", "tgt": "allEnemies", "price": 25, "battle": true},
}
const ITEM_ORDER = ["potion", "hipotion", "ether", "ember", "firebomb"]

var RELICS = {
	"whetstone": {"name": "Whetstone", "desc": "+20% physical damage.", "pool": "base"},
	"ironcharm": {"name": "Iron Charm", "desc": "Take 15% less damage.", "pool": "base"},
	"vitalseed": {"name": "Vital Seed", "desc": "+20% max HP.", "pool": "base"},
	"manaprism": {"name": "Mana Prism", "desc": "+30% max MP.", "pool": "base"},
	"swiftfeather": {"name": "Swift Feather", "desc": "+6 Agility. Act sooner.", "pool": "base"},
	"clover": {"name": "Four-Leaf Clover", "desc": "+10% critical hit chance.", "pool": "base"},
	"vampfang": {"name": "Vampire Fang", "desc": "Physical hits heal 15% of damage dealt.", "pool": "base"},
	"goldtooth": {"name": "Gold Tooth", "desc": "+50% gold from battles.", "pool": "base"},
	"thornmail": {"name": "Thorn Mail", "desc": "Reflect 25% of physical damage taken.", "pool": "base"},
	"fairy": {"name": "Bottled Fairy", "desc": "First hero to fall each floor revives at 30% HP.", "pool": "base"},
	"coal": {"name": "Campfire Coal", "desc": "Heal 15% HP after every battle.", "pool": "base"},
	"glassblade": {"name": "Glass Blade", "desc": "+45% damage dealt, but -25% max HP.", "pool": "base"},
	"etherleaf": {"name": "Ether Leaf", "desc": "Recover 2 MP at the start of each round.", "pool": "base"},
	"echobell": {"name": "Echo Bell", "desc": "Attacks have a 20% chance to strike twice.", "pool": "base"},
	"rosary": {"name": "Saint's Rosary", "desc": "Healing +40%.", "pool": "mira"},
	"halo": {"name": "Halo", "desc": "Party regenerates 5% HP each round.", "pool": "mira"},
	"embercore": {"name": "Ember Core", "desc": "+30% magic damage.", "pool": "doran"},
	"battery": {"name": "Arcane Battery", "desc": "Skills cost 30% less MP.", "pool": "doran"},
	"loadeddice": {"name": "Loaded Dice", "desc": "+5% crit; crits deal x2.5.", "pool": "pip"},
	"glove": {"name": "Pickpocket's Glove", "desc": "Steal never fails; attacks may snatch gold.", "pool": "pip"},
	"smokebomb": {"name": "Smoke Bomb", "desc": "Fleeing always works; party acts first on round 1.", "pool": "pip"},
	"berserker": {"name": "Berserker Band", "desc": "+40% damage while below 50% HP.", "pool": "ach:slayer"},
	"compass": {"name": "Seer's Compass", "desc": "Reveals the whole floor map.", "pool": "ach:delver"},
	"goldkey": {"name": "Golden Key", "desc": "Gain a Key on every new floor.", "pool": "ach:looter"},
	"gravemoss": {"name": "Grave Moss", "desc": "Fallen heroes revive at 1 HP after battle.", "pool": "ach:mourner"},
	"crown": {"name": "Crown of Dusk", "desc": "+15% to all stats.", "pool": "ach:victor"},
}

var ACH = [
	{"id": "warden", "name": "Wardenbreaker", "desc": "Defeat the Stone Warden (Floor 1 boss).", "reward": "Hero: Mira", "hero": "mira"},
	{"id": "cell", "name": "Jailbreak", "desc": "Open the Sealed Cell on Floor 2 with a Key.", "reward": "Hero: Doran", "hero": "doran"},
	{"id": "debt", "name": "Debt Collector", "desc": "Pay off the stranger's debt in a shop.", "reward": "Hero: Pip", "hero": "pip"},
	{"id": "slayer", "name": "Slayer", "desc": "Defeat 50 monsters (lifetime).", "reward": "Relic: Berserker Band", "stat": "kills", "n": 50},
	{"id": "delver", "name": "Delver", "desc": "Reach Floor 3.", "reward": "Relic: Seer's Compass"},
	{"id": "looter", "name": "Looter", "desc": "Open 8 chests (lifetime).", "reward": "Relic: Golden Key", "stat": "chests", "n": 8},
	{"id": "mourner", "name": "Mourner", "desc": "Fall in battle 3 times.", "reward": "Relic: Grave Moss", "stat": "deaths", "n": 3},
	{"id": "victor", "name": "Dawnbringer", "desc": "Defeat the Umbral Wyrm.", "reward": "Relic: Crown of Dusk"},
	{"id": "party", "name": "Fellowship", "desc": "Unlock all four heroes.", "reward": "Camp Tier IV upgrades"},
]

var UPGRADES = [
	{"id": "vit", "name": "Vitality", "desc": "+8% max HP per rank.", "cost": [20, 45, 90], "req": 1},
	{"id": "might", "name": "Might", "desc": "+6% damage per rank.", "cost": [25, 55, 100], "req": 1},
	{"id": "pack", "name": "Pack Rat", "desc": "Start runs with +1 Potion per rank.", "cost": [15, 40], "req": 1},
	{"id": "coin", "name": "Lucky Coin", "desc": "+25% gold per rank.", "cost": [20, 50], "req": 1},
	{"id": "key", "name": "Skeleton Key", "desc": "Start each run with a Key.", "cost": [40], "req": 2},
	{"id": "sense", "name": "Treasure Sense", "desc": "Reliquaries offer 4 relics instead of 3.", "cost": [60], "req": 2},
	{"id": "wis", "name": "Wisdom", "desc": "+10% max MP per rank.", "cost": [30, 70], "req": 2},
	{"id": "favor", "name": "Merchant's Favor", "desc": "Shop prices -20%.", "cost": [70], "req": 3},
	{"id": "ember", "name": "Phoenix Stash", "desc": "Start runs with a Phoenix Ember.", "cost": [60], "req": 3},
	{"id": "xp", "name": "Quick Study", "desc": "+20% EXP per rank.", "cost": [50, 100], "req": 3},
	{"id": "siphon", "name": "Soul Siphon", "desc": "+30% Soul Shards from runs.", "cost": [120], "req": 4},
	{"id": "heir", "name": "Heirloom", "desc": "Start each run holding a random relic.", "cost": [150], "req": 4},
]
var SIG = {"kael": "+10% physical damage for Kael.", "mira": "Mira's skills cost 1 less MP.", "doran": "+15% spell damage for Doran.", "pip": "+30% gold while Pip is in the party."}

func all_upgrades() -> Array:
	var l = UPGRADES.duplicate()
	for c in HERO_IDS:
		l.append({"id": "vet_" + c, "name": CHARS[c].name + ": Veteran", "desc": "%s starts runs 1 level higher per rank." % CHARS[c].name, "cost": [30, 70], "hero": c})
		l.append({"id": "sig_" + c, "name": CHARS[c].name + ": Signature", "desc": SIG[c], "cost": [60], "hero": c})
	return l

var ESK = {
	"atk": {"kind": "phys", "pow": 1.0},
	"quake": {"name": "Quake", "kind": "fixed", "all": true, "pow": 16, "color": "#c8a060"},
	"frostbite": {"name": "Frostbite", "kind": "fixed", "pow": 26, "color": "#7ad8ff"},
	"dark": {"name": "Dark Bolt", "kind": "fixed", "pow": 24, "color": "#c050ff"},
	"gravechill": {"name": "Grave Chill", "kind": "fixed", "all": true, "pow": 28, "color": "#9ab0ff"},
	"drain": {"name": "Blood Drain", "kind": "phys", "pow": 1.0, "drain": true, "color": "#ff3050"},
	"inferno": {"name": "Inferno", "kind": "fixed", "all": true, "pow": 40, "color": "#ff5a1a"},
	"abyss": {"name": "Abyss", "kind": "fixed", "pow": 46, "color": "#a040ff"},
	"shadowbreath": {"name": "Shadow Breath", "kind": "fixed", "all": true, "pow": 52, "color": "#a040ff"},
	"tail": {"name": "Tail Sweep", "kind": "phys", "all": true, "pow": 0.7},
	"nova": {"name": "Dark Nova", "kind": "fixed", "all": true, "pow": 75, "color": "#ff40a0"},
}

var EN = {
	"gel": {"name": "Gel", "hp": 22, "atk": 5, "def": 1, "mdef": 0, "agi": 5, "xp": 7, "gold": 4, "weak": ["fire"]},
	"bat": {"name": "Cave Bat", "hp": 16, "atk": 6, "def": 1, "mdef": 2, "agi": 13, "xp": 7, "gold": 4, "weak": ["bolt"], "fly": true},
	"imp": {"name": "Imp", "hp": 28, "atk": 7, "def": 3, "mdef": 2, "agi": 8, "xp": 10, "gold": 6},
	"warden": {"name": "Stone Warden", "boss": true, "scale": 5, "hp": 220, "atk": 12, "def": 6, "mdef": 4, "agi": 5, "xp": 60, "gold": 60, "weak": ["bolt"], "acts": [["atk", 3], ["quake", 1]]},
	"skel": {"name": "Skeleton", "hp": 60, "atk": 15, "def": 7, "mdef": 3, "agi": 8, "xp": 20, "gold": 9, "weak": ["holy", "fire"]},
	"fgel": {"name": "Frost Gel", "hp": 50, "atk": 13, "def": 5, "mdef": 6, "agi": 6, "xp": 18, "gold": 8, "weak": ["fire"], "resist": ["frost"], "acts": [["atk", 2], ["frostbite", 1]]},
	"shade": {"name": "Shade", "hp": 52, "atk": 13, "def": 5, "mdef": 12, "agi": 12, "xp": 22, "gold": 10, "weak": ["holy"], "acts": [["atk", 1], ["dark", 1]]},
	"vbat": {"name": "Vampire Bat", "hp": 48, "atk": 14, "def": 5, "mdef": 6, "agi": 20, "xp": 20, "gold": 10, "fly": true, "acts": [["atk", 2], ["drain", 1]]},
	"monarch": {"name": "Bone Monarch", "boss": true, "scale": 5, "hp": 420, "atk": 22, "def": 10, "mdef": 8, "agi": 10, "xp": 180, "gold": 100, "weak": ["holy"], "acts": [["atk", 3], ["gravechill", 2]]},
	"bknight": {"name": "Bone Knight", "hp": 150, "atk": 28, "def": 14, "mdef": 8, "agi": 12, "xp": 60, "gold": 24, "weak": ["holy", "fire"]},
	"hound": {"name": "Hellhound", "hp": 120, "atk": 26, "def": 11, "mdef": 10, "agi": 22, "xp": 58, "gold": 24, "weak": ["frost"], "resist": ["fire"], "acts": [["atk", 3], ["inferno", 1]]},
	"wraith": {"name": "Wraith", "hp": 120, "atk": 24, "def": 10, "mdef": 16, "agi": 18, "xp": 62, "gold": 26, "weak": ["holy"], "acts": [["atk", 1], ["abyss", 2]]},
	"wyrm": {"name": "Umbral Wyrm", "boss": true, "scale": 6, "hp": 900, "atk": 40, "def": 16, "mdef": 12, "agi": 15, "xp": 0, "gold": 0, "weak": ["holy"], "acts": [["atk", 3], ["shadowbreath", 2], ["tail", 1]]},
}

var FLOORS = [
	{"name": "Cellar of Echoes", "pool": ["gel", "bat", "imp"], "boss": "warden",
		"intro": "A hulking statue grinds to life. Behind it, someone is chained to the wall...",
		"ambient": Color("#c8a070"), "fog": Color("#2e241a"), "torch": Color("#ffa040")},
	{"name": "Sunken Crypt", "pool": ["skel", "fgel", "shade", "vbat"], "boss": "monarch",
		"intro": "A crowned skeleton rises from its throne of bones.",
		"ambient": Color("#7090c8"), "fog": Color("#141c2a"), "torch": Color("#7ad0ff")},
	{"name": "Spire of Dusk", "pool": ["bknight", "hound", "wraith"], "boss": "wyrm",
		"intro": "The Umbral Wyrm unfurls its wings. The last Shard pulses in its chest.",
		"ambient": Color("#9a80c8"), "fog": Color("#1a1428"), "torch": Color("#d070ff")},
]

var ROOMS = {
	"start": {"name": "Landing", "text": "Stairs lead back into darkness. The way is forward."},
	"combat": {"name": "Chamber", "text": "Scratch marks and bones. Nothing stirs now."},
	"boss": {"name": "Guardian's Lair", "text": "The guardian is gone. Stairs spiral downward."},
	"treasure": {"name": "Reliquary", "text": "A pedestal hums with old power."},
	"shop": {"name": "Wandering Shop", "text": "A hooded merchant has set up a stall."},
	"chest": {"name": "Storeroom", "text": "A dusty chest sits against the wall."},
	"camp": {"name": "Campsite", "text": "Someone left a fire burning. It feels safe here."},
	"altar": {"name": "Blood Altar", "text": "A crimson altar whispers: power, for a price."},
	"fountain": {"name": "Fountain", "text": "Clear water bubbles from a stone basin."},
	"cell": {"name": "Sealed Cell", "text": "An iron cage stands in the gloom."},
}

const HOWTO = "[color=#ffe680]The loop:[/color] Descend 3 procedurally generated floors. Each room is a fight, a shop, a reliquary, an event or a boss.\n" + \
	"[color=#ffe680]Per run:[/color] levels, gold, items and [color=#e0a8ff]relics[/color] are lost when the run ends.\n" + \
	"[color=#ffe680]Permanent:[/color] earn [color=#ffe680]Soul Shards[/color] every run and spend them at Camp. Feats unlock new relics.\n" + \
	"[color=#ffe680]Heroes:[/color] you start with Kael. Three more join, each unlocked a different way. Each new hero grows your party, adds relics to the pool and opens the next Camp tier.\n" + \
	"[color=#9aa3d8]Arrows/WASD/D-pad move - Z/Enter/(A) confirm - X/Esc/(B) back or menu - M mute - F11 fullscreen[/color]"
