const express = require("express");
const app = express();

app.get("/", (req, res) => {
    res.send("CI/CD + Terraform demo working 🚀");
});

app.listen(3000, () => console.log("App running"));
