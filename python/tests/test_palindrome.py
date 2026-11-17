import unittest

from src.palindrome import is_palindrome


class PalindromeTest(unittest.TestCase):
    def test_ignores_case_spaces_and_punctuation(self):
        self.assertTrue(is_palindrome("A man, a plan, a canal: Panama!"))

    def test_returns_false_for_non_palindrome(self):
        self.assertFalse(is_palindrome("python"))

    def test_rejects_non_string_values(self):
        with self.assertRaises(TypeError):
            is_palindrome(None)


if __name__ == "__main__":
    unittest.main()
