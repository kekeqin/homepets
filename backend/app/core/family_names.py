def default_family_name(nickname: str) -> str:
    return f"{nickname.strip()}的家"


def default_family_names_for(nickname: str) -> set[str]:
    trimmed = nickname.strip()
    return {f"{trimmed}的家", f"{trimmed}的家庭"}
