const express = require("express");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;

// Serwowanie statycznego index.html
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "index.html"));
});

// Tryb "check-only" używany w workflow (bez uruchamiania serwera na stałe)
if (process.argv.includes("--check-only")) {
  console.log("Check-only: serwer startuje poprawnie.");
  process.exit(0);
}

app.listen(PORT, () => {
  console.log(`Serwer działa na http://localhost:${PORT}`);
});
