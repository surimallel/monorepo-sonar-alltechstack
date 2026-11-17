package com.example.monorepo;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class GreetingFormatterTest {
    private final GreetingFormatter formatter = new GreetingFormatter();

    @Test
    void formatsTrimmedName() {
        assertEquals("Hello, Ada!", formatter.format("  Ada  "));
    }

    @Test
    void rejectsBlankName() {
        assertThrows(IllegalArgumentException.class, () -> formatter.format("  "));
        assertThrows(IllegalArgumentException.class, () -> formatter.format(null));
    }
}
