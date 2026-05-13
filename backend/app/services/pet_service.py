"""宠物等级配置与成长计算。"""

LEVEL_THRESHOLDS = {
    1: 0,
    2: 100,
    3: 250,
    4: 500,
    5: 1000,
}

MAX_LEVEL = 5

SELECTABLE_PET_TYPES = ("cat", "dog", "hamster", "rabbit", "turtle")
PET_TYPES = [*SELECTABLE_PET_TYPES, "bird", "fish", "panda"]

PET_DISPLAY_NAMES = {
    "cat": "小猫",
    "dog": "小狗",
    "hamster": "仓鼠",
    "rabbit": "小白兔",
    "turtle": "乌龟",
    "bird": "小鸟",
    "fish": "小鱼",
    "panda": "熊猫",
}

PET_EMOJIS = {
    "cat": "🐱",
    "dog": "🐶",
    "rabbit": "🐰",
    "bird": "🐦",
    "turtle": "🐢",
    "hamster": "🐹",
    "fish": "🐟",
    "panda": "🐼",
}

VALID_PET_TYPES = set(PET_TYPES)
VALID_SELECTABLE_PET_TYPES = set(SELECTABLE_PET_TYPES)


def get_emoji(pet_type: str) -> str:
    return PET_EMOJIS.get(pet_type, "🐾")


def get_image(pet_type: str, level: int) -> str | None:
    return f"assets/pets/{pet_type}_{level}.png"


def get_default_pet_name(pet_type: str) -> str:
    return PET_DISPLAY_NAMES.get(pet_type, "宠物")


def create_member_pet(
    family_id: int,
    owner_id: int,
    pet_type: str,
    pet_name: str,
) -> dict[str, int | str]:
    return {
        "name": pet_name,
        "pet_type": pet_type,
        "level": 1,
        "experience": 0,
        "owner_id": owner_id,
        "family_id": family_id,
    }


def calculate_level(experience: int) -> int:
    level = 1
    for candidate_level in range(MAX_LEVEL, 1, -1):
        if experience >= LEVEL_THRESHOLDS[candidate_level]:
            level = candidate_level
            break
    return level


def get_next_level_threshold(current_level: int) -> int | None:
    if current_level >= MAX_LEVEL:
        return None
    return LEVEL_THRESHOLDS.get(current_level + 1)
