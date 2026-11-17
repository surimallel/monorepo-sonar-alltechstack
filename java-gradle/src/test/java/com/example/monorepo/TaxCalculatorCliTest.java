package com.example.monorepo;

import org.junit.jupiter.api.Test;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class TaxCalculatorCliTest {
    @Test
    void printsCalculatedTax() {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        PrintStream original = System.out;
        try {
            System.setOut(new PrintStream(output));
            TaxCalculatorCli.main(new String[]{"50", "0.165"});
        } finally {
            System.setOut(original);
        }
        assertEquals("8.25", output.toString());
    }

    @Test
    void rejectsWrongArgumentCount() {
        assertThrows(IllegalArgumentException.class, () -> TaxCalculatorCli.main(new String[]{"50"}));
    }
}
