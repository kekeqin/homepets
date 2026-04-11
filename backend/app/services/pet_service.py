"""Pet level configuration and feeding logic."""

EGG_HATCH_EXP = 30  # Experience needed to hatch egg into pet

LEVEL_THRESHOLDS = {
    1: 0,
    2: 100,
    3: 250,
    4: 500,
    5: 1000,
}

MAX_LEVEL = 5

PET_TYPES = ["cat", "dog", "rabbit", "bird", "turtle", "hamster", "fish", "panda"]

PET_EMOJIS = {
    "egg": "🥚",
    "cat": "🐱",
    "dog": "🐶",
    "rabbit": "🐰",
    "bird": "🐦",
    "turtle": "🐢",
    "hamster": "🐹",
    "fish": "🐠",
    "panda": "🐼",
}

VALID_PET_TYPES = set(PET_TYPES)


def get_emoji(pet_type: str) -> str:
    return PET_EMOJIS.get(pet_type, "🐾")


def get_image(pet_type: str, level: int) -> str | None:
    return f"assets/pets/{pet_type}_{level}.png"


def calculate_level(experience: int) -> int:
    level = 1
    for lvl in range(MAX_LEVEL, 1, -1):
        if experience >= LEVEL_THRESHOLDS[lvl]:
            level = lvl
            break
    return level


def get_next_level_threshold(current_level: int) -> int | None:
    if current_level >= MAX_LEVEL:
        return None
    return LEVEL_THRESHOLDS.get(current_level + 1)


def create_egg(family_id: int, owner_id: int) -> dict:
    """Return data dict for creating a new pet egg."""
    return {
        "name": "宠物蛋",
        "pet_type": "egg",
        "pet_form": "egg",
        "level": 0,
        "experience": 0,
        "image_url": "assets/pets/egg.png",
        "owner_id": owner_id,
        "family_id": family_id,
    }


def can_hatch(experience: int) -> bool:
    return experience >= EGG_HATCH_EXP
