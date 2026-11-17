import sys

from palindrome import is_palindrome


if len(sys.argv) != 2:
    raise SystemExit("Expected one text value")

print(str(is_palindrome(sys.argv[1])).lower())
