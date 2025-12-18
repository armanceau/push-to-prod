const { calculate, isValidEmail, formatDate } = require("./utils");

describe("Fonctions utilitaires - Tests unitaires", () => {
  describe("calculate", () => {
    test("addition de nombres positifs", () => {
      expect(calculate("add", 2, 3)).toBe(5);
    });

    test("addition avec nombres négatifs", () => {
      expect(calculate("add", -2, 3)).toBe(1);
      expect(calculate("add", -2, -3)).toBe(-5);
    });

    test("soustraction", () => {
      expect(calculate("subtract", 10, 3)).toBe(7);
      expect(calculate("subtract", 3, 10)).toBe(-7);
    });

    test("multiplication", () => {
      expect(calculate("multiply", 4, 5)).toBe(20);
      expect(calculate("multiply", -3, 4)).toBe(-12);
      expect(calculate("multiply", 0, 5)).toBe(0);
    });

    test("division", () => {
      expect(calculate("divide", 15, 3)).toBe(5);
      expect(calculate("divide", 7, 2)).toBe(3.5);
    });

    test("division par zéro doit lever une erreur", () => {
      expect(() => calculate("divide", 5, 0)).toThrow(
        "Division par zéro impossible"
      );
    });

    test("opération invalide doit lever une erreur", () => {
      expect(() => calculate("invalid", 5, 3)).toThrow(
        "Opération non supportée"
      );
    });

    test("paramètres invalides doivent lever une erreur", () => {
      expect(() => calculate("add", "a", 3)).toThrow(
        "Les paramètres doivent être des nombres"
      );
      expect(() => calculate("add", 3, "b")).toThrow(
        "Les paramètres doivent être des nombres"
      );
    });
  });

  describe("isValidEmail", () => {
    test("emails valides", () => {
      expect(isValidEmail("test@example.com")).toBe(true);
      expect(isValidEmail("user.name@domain.co.uk")).toBe(true);
      expect(isValidEmail("a@b.c")).toBe(true);
    });

    test("emails invalides", () => {
      expect(isValidEmail("invalid-email")).toBe(false);
      expect(isValidEmail("test@")).toBe(false);
      expect(isValidEmail("@domain.com")).toBe(false);
      expect(isValidEmail("test.domain.com")).toBe(false);
      expect(isValidEmail("")).toBe(false);
    });

    test("types invalides", () => {
      expect(isValidEmail(null)).toBe(false);
      expect(isValidEmail(undefined)).toBe(false);
      expect(isValidEmail(123)).toBe(false);
      expect(isValidEmail({})).toBe(false);
    });
  });

  describe("formatDate", () => {
    test("format de date valide", () => {
      const date = new Date("2023-12-25T10:30:00Z");
      expect(formatDate(date)).toBe("2023-12-25");
    });

    test("date actuelle", () => {
      const now = new Date();
      const formatted = formatDate(now);
      expect(formatted).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    });

    test("date invalide doit lever une erreur", () => {
      expect(() => formatDate("invalid")).toThrow("Date invalide");
      expect(() => formatDate(null)).toThrow("Date invalide");
      expect(() => formatDate(new Date("invalid"))).toThrow("Date invalide");
    });
  });
});
