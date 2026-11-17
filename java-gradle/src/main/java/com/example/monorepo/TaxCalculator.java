package com.example.monorepo;

import java.math.BigDecimal;
import java.math.RoundingMode;

public class TaxCalculator {
    public BigDecimal calculate(BigDecimal amount, BigDecimal rate) {
        if (amount == null || rate == null
                || amount.signum() < 0
                || rate.signum() < 0
                || rate.compareTo(BigDecimal.ONE) > 0) {
            throw new IllegalArgumentException("Amount must be nonnegative and rate must be between 0 and 1");
        }
        return amount.multiply(rate).setScale(2, RoundingMode.HALF_UP);
    }
}
