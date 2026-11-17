package com.example.monorepo;

import org.junit.jupiter.api.Test;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class GreetingFormatterCliTest {
    @Test
    void printsFormattedGreeting() {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        PrintStream original = System.out;
        try {
            System.setOut(new PrintStream(output));
            GreetingFormatterCli.main(new String[]{"Ada"});
        } finally {
            System.setOut(original);
        }
        assertEquals("Hello, Ada!", output.toString());
    }

    @Test
    void rejectsWrongArgumentCount() {
        assertThrows(IllegalArgumentException.class, () -> GreetingFormatterCli.main(new String[0]));
    }
}
