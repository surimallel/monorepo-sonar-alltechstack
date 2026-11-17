package com.example.monorepo;

public final class GreetingFormatterCli {
    private GreetingFormatterCli() {
    }

    public static void main(String[] args) {
        if (args.length != 1) {
            throw new IllegalArgumentException("Expected one name");
        }
        System.out.print(new GreetingFormatter().format(args[0]));
    }
}
