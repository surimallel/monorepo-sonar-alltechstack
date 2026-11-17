import re


def is_palindrome(value: str) -> bool:
    if not isinstance(value, str):
        raise TypeError("value must be a string")

    normalized = re.sub(r"[^a-z0-9]", "", value.lower())
    return normalized == normalized[::-1]
