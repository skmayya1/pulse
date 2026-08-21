const defaultTheme = require("tailwindcss/defaultTheme");

/** @type {import("tailwindcss").Config} */
module.exports = {
  content: [
    "./app/components/**/*.{erb,html,rb}",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,html,rb}",
  ],
  darkMode: ["class", '[data-theme="night"]'],
  theme: {
    extend: {
      colors: {
        background: "hsl(var(--pulse-background))",
        foreground: "hsl(var(--pulse-foreground))",
        card: {
          DEFAULT: "hsl(var(--pulse-card))",
          foreground: "hsl(var(--pulse-card-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--pulse-popover))",
          foreground: "hsl(var(--pulse-popover-foreground))",
        },
        primary: {
          DEFAULT: "hsl(var(--pulse-primary))",
          foreground: "hsl(var(--pulse-primary-foreground))",
          content: "hsl(var(--pulse-primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--pulse-secondary))",
          foreground: "hsl(var(--pulse-secondary-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--pulse-muted))",
          foreground: "hsl(var(--pulse-muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--pulse-accent))",
          dark: "hsl(var(--pulse-accent-dark))",
          foreground: "hsl(var(--pulse-accent-foreground))",
        },
        success: {
          DEFAULT: "hsl(var(--pulse-success))",
          foreground: "hsl(var(--pulse-success-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--pulse-destructive))",
          foreground: "hsl(var(--pulse-destructive-foreground))",
        },
        error: {
          DEFAULT: "hsl(var(--pulse-destructive))",
          content: "hsl(var(--pulse-destructive-foreground))",
        },
        warning: {
          DEFAULT: "hsl(var(--pulse-warning))",
          content: "hsl(var(--pulse-warning-foreground))",
        },
        info: "hsl(var(--pulse-info))",
        border: {
          DEFAULT: "hsl(var(--pulse-border))",
          secondary: "hsl(var(--pulse-border-secondary))",
        },
        input: "hsl(var(--pulse-input))",
        ring: "hsl(var(--pulse-ring))",
        disabled: "hsl(var(--pulse-disabled))",
        "base-100": "hsl(var(--pulse-base-100))",
        "base-200": "hsl(var(--pulse-base-200))",
        "base-300": "hsl(var(--pulse-base-300))",
        "base-content": "hsl(var(--pulse-base-content))",
      },
      borderRadius: {
        sm: "calc(var(--pulse-radius) - 4px)",
        md: "calc(var(--pulse-radius) - 2px)",
        lg: "var(--pulse-radius)",
        box: "0.5rem",
        field: "0.4rem",
      },
      fontFamily: {
        sans: ["Inter Variable", "Inter", ...defaultTheme.fontFamily.sans],
      },
    },
  },
};
