const request = require("supertest");
const app = require("./app");

describe("Application Web - Tests d'intégration", () => {
  describe("GET /", () => {
    it("devrait retourner le message de bienvenue", async () => {
      const res = await request(app).get("/").expect(200);

      expect(res.body).toHaveProperty("message");
      expect(res.body).toHaveProperty("version", "1.0.0");
      expect(res.body).toHaveProperty("timestamp");
      expect(res.body.message).toContain("Bienvenue");
    });
  });

  describe("GET /health", () => {
    it("devrait retourner le statut de santé", async () => {
      const res = await request(app).get("/health").expect(200);

      expect(res.body).toHaveProperty("status", "OK");
      expect(res.body).toHaveProperty("uptime");
      expect(res.body).toHaveProperty("timestamp");
      expect(typeof res.body.uptime).toBe("number");
    });
  });

  describe("GET /api/users", () => {
    it("devrait retourner la liste des utilisateurs", async () => {
      const res = await request(app).get("/api/users").expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body).toHaveLength(3);
      expect(res.body[0]).toHaveProperty("id");
      expect(res.body[0]).toHaveProperty("name");
      expect(res.body[0]).toHaveProperty("email");
    });
  });

  describe("POST /api/calculate", () => {
    it("devrait effectuer une addition correctement", async () => {
      const res = await request(app)
        .post("/api/calculate")
        .send({
          operation: "add",
          a: 5,
          b: 3,
        })
        .expect(200);

      expect(res.body).toEqual({
        operation: "add",
        a: 5,
        b: 3,
        result: 8,
      });
    });

    it("devrait effectuer une soustraction correctement", async () => {
      const res = await request(app)
        .post("/api/calculate")
        .send({
          operation: "subtract",
          a: 10,
          b: 4,
        })
        .expect(200);

      expect(res.body.result).toBe(6);
    });

    it("devrait effectuer une multiplication correctement", async () => {
      const res = await request(app)
        .post("/api/calculate")
        .send({
          operation: "multiply",
          a: 6,
          b: 7,
        })
        .expect(200);

      expect(res.body.result).toBe(42);
    });

    it("devrait effectuer une division correctement", async () => {
      const res = await request(app)
        .post("/api/calculate")
        .send({
          operation: "divide",
          a: 15,
          b: 3,
        })
        .expect(200);

      expect(res.body.result).toBe(5);
    });

    it("devrait rejeter la division par zéro", async () => {
      const res = await request(app)
        .post("/api/calculate")
        .send({
          operation: "divide",
          a: 10,
          b: 0,
        })
        .expect(400);

      expect(res.body).toHaveProperty("error");
      expect(res.body.error).toContain("Division par zéro");
    });

    it("devrait rejeter les paramètres invalides", async () => {
      const res = await request(app)
        .post("/api/calculate")
        .send({
          operation: "add",
          a: "invalide",
          b: 3,
        })
        .expect(400);

      expect(res.body).toHaveProperty("error");
      expect(res.body.error).toContain("Paramètres invalides");
    });

    it("devrait rejeter une opération non supportée", async () => {
      const res = await request(app)
        .post("/api/calculate")
        .send({
          operation: "power",
          a: 2,
          b: 3,
        })
        .expect(400);

      expect(res.body).toHaveProperty("error");
      expect(res.body.error).toContain("Opération non supportée");
    });
  });

  describe("Routes inexistantes", () => {
    it("devrait retourner 404 pour une route inexistante", async () => {
      const res = await request(app).get("/route-inexistante").expect(404);

      expect(res.body).toHaveProperty("error");
      expect(res.body.error).toContain("Route non trouvée");
    });
  });
});
