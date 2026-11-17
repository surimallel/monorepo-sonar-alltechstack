package com.example.monorepo;

import java.math.BigDecimal;

public final class TaxCalculatorCli {
    private TaxCalculatorCli() {
    }

    public static void main(String[] args) {
        if (args.length != 2) {
            throw new IllegalArgumentException("Expected an amount and a rate");
        }
        BigDecimal amount = new BigDecimal(args[0]);
        BigDecimal rate = new BigDecimal(args[1]);
        System.out.print(new TaxCalculator().calculate(amount, rate).toPlainString());
    }
}
