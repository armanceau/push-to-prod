function calculate(operation, a, b) {
  if (typeof a !== "number" || typeof b !== "number") {
    throw new Error("Les paramètres doivent être des nombres");
  }

  switch (operation) {
    case "add":
      return a + b;
    case "subtract":
      return a - b;
    case "multiply":
      return a * b;
    case "divide":
      if (b === 0) {
        throw new Error("Division par zéro impossible");
      }
      return a / b;
    default:
      throw new Error("Opération non supportée");
  }
}

function isValidEmail(email) {
  if (typeof email !== "string") return false;
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

function formatDate(date) {
  if (!(date instanceof Date) || isNaN(date)) {
    throw new Error("Date invalide");
  }
  return date.toISOString().split("T")[0];
}

module.exports = {
  calculate,
  isValidEmail,
  formatDate,
};
