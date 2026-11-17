package com.example.monorepo;

public class GreetingFormatter {
    public String format(String name) {
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("Name must not be blank");
        }
        return "Hello, " + name.trim() + "!";
    }
}
