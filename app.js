const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.static("public"));
app.get("/", (req, res) => {
  res.json({
    message: "Bienvenue sur notre application CI/CD !",
    version: "1.0.0",
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || "development",
  });
});

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "OK",
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

app.get("/api/users", (req, res) => {
  const users = [
    { id: 1, name: "Alice", email: "alice@example.com" },
    { id: 2, name: "Bob", email: "bob@example.com" },
    { id: 3, name: "Charlie", email: "charlie@example.com" },
  ];
  res.json(users);
});

app.post("/api/calculate", (req, res) => {
  const { operation, a, b } = req.body;

  if (!operation || typeof a !== "number" || typeof b !== "number") {
    return res.status(400).json({
      error: "Paramètres invalides. Veuillez fournir operation, a et b.",
    });
  }

  let result;
  switch (operation) {
    case "add":
      result = a + b;
      break;
    case "subtract":
      result = a - b;
      break;
    case "multiply":
      result = a * b;
      break;
    case "divide":
      if (b === 0) {
        return res.status(400).json({ error: "Division par zéro impossible" });
      }
      result = a / b;
      break;
    default:
      return res.status(400).json({
        error:
          "Opération non supportée. Utilisez: add, subtract, multiply, divide",
      });
  }

  res.json({
    operation,
    a,
    b,
    result,
  });
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: "Erreur interne du serveur",
    message:
      process.env.NODE_ENV === "development"
        ? err.message
        : "Une erreur est survenue",
  });
});

app.use("*", (req, res) => {
  res.status(404).json({
    error: "Route non trouvée",
    path: req.originalUrl,
  });
});

const server = app.listen(PORT, () => {
  console.log(`Serveur démarré sur le port ${PORT}`);
  console.log(`Environnement: ${process.env.NODE_ENV || "development"}`);
});

process.on("SIGTERM", () => {
  console.log("SIGTERM reçu, arrêt du serveur...");
  server.close(() => {
    console.log("Serveur arrêté proprement");
    process.exit(0);
  });
});

module.exports = app;
