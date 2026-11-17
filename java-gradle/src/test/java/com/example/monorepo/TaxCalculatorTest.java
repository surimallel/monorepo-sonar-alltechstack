package com.example.monorepo;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class TaxCalculatorTest {
    private final TaxCalculator calculator = new TaxCalculator();

    @Test
    void calculatesAndRoundsTaxToCents() {
        assertEquals(new BigDecimal("8.25"),
                calculator.calculate(new BigDecimal("50.00"), new BigDecimal("0.165")));
    }

    @Test
    void rejectsInvalidAmountsAndRates() {
        assertThrows(IllegalArgumentException.class,
                () -> calculator.calculate(new BigDecimal("-1"), new BigDecimal("0.1")));
        assertThrows(IllegalArgumentException.class,
                () -> calculator.calculate(BigDecimal.ONE, new BigDecimal("1.1")));
        assertThrows(IllegalArgumentException.class,
                () -> calculator.calculate(null, BigDecimal.ZERO));
    }
}
