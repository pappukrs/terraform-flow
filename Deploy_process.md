# 🚀 Zero‑Cost Demo Deployment Guide

> **Goal:** Anyone should be able to deploy a Node.js app on AWS using **GitHub Actions + Terraform**, demo it, and then **destroy everything** so that **no cost remains**.

This document is **self‑contained**. If you follow it step‑by‑step, you **do not need to search anywhere else**.

---

## 🧠 Core Philosophy (Very Important)

* **Code is permanent** (GitHub)
* **Infrastructure is temporary** (Terraform)
* **Servers are disposable**
* **No SSH manually in production mindset**

This is how real engineers do demos, PoCs, and even production.

---

## 🏗️ Final Architecture

```
Git Push
   ↓
GitHub Actions (CI/CD)
   ↓
Terraform (Infra as Code)
   ↓
EC2 (Docker installed via User‑Data)
   ↓
Docker Container (Node.js app)
```

When demo is over:

```
terraform destroy  →  💰 cost stops completely
```

---

## 📦 Prerequisites (One‑Time Setup)

### 1️⃣ AWS Account

* Create an **IAM user** (not root)
* Permissions:

  * EC2
  * VPC
  * Security Groups

### 2️⃣ Local Tools

```bash
sudo apt install git docker terraform awscli -y
aws configure
```

---

## 📁 Project Structure

```
project-root/
 ├── src/
 │    └── index.js
 ├── package.json
 ├── Dockerfile
 ├── .gitignore
 ├── infra/
 │    ├── main.tf
 │    ├── outputs.tf
 └── .github/
      └── workflows/
           └── deploy.yml
```

---

## 🟢 Step 1 — Node.js App

### `src/index.js`

```js
const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.send("Deployment successful 🚀");
});

app.listen(3000, () => console.log("App running on port 3000"));
```

---

## 🟢 Step 2 — Dockerfile

```dockerfile
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm install --production

COPY . .
EXPOSE 3000
CMD ["node", "src/index.js"]
```

Why Docker?

* Same runtime everywhere
* No manual Node install

---

## 🟢 Step 3 — `.gitignore` (CRITICAL)

```gitignore
node_modules/
.env
*.log
```

⚠️ **Never commit `node_modules`**

---

## 🟢 Step 4 — Terraform (EC2 + Security Group)

### `infra/main.tf`

```hcl
provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "app_sg" {
  name = "demo-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami           = "ami-0f5ee92e2d63afc18"  # Ubuntu 22.04
  instance_type = "t3.micro"
  security_groups = [aws_security_group.app_sg.name]

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install docker.io -y
    systemctl start docker
    usermod -aG docker ubuntu
  EOF

  tags = {
    Name = "demo-app"
  }
}
```

### `infra/outputs.tf`

```hcl
output "ec2_ip" {
  value = aws_instance.app.public_ip
}
```

---

## 🟢 Step 5 — Create Infra

```bash
cd infra
terraform init
terraform apply
```

Save the **public IP**.

---

## 🔐 Step 6 — SSH Key & Base64 (IMPORTANT PART)

### Why Base64 is needed?

GitHub Secrets **break multiline values** like SSH keys.

### Convert private key to base64

```bash
base64 ~/.ssh/id_ed25519 | tr -d '\n'
```

### GitHub Secrets

| Name     | Value                          |
| -------- | ------------------------------ |
| EC2_HOST | EC2 public IP                  |
| EC2_KEY  | **base64 encoded private key** |

---

## 🟢 Step 7 — GitHub Actions Workflow

### `.github/workflows/deploy.yml`

```yaml
name: Deploy App

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Decode SSH key
        run: |
          echo "${{ secrets.EC2_KEY }}" | base64 -d > key.pem
          chmod 600 key.pem

      - name: Build Docker image
        run: docker build -t demo-app .

      - name: Save image
        run: docker save demo-app > app.tar

      - name: Copy image to EC2
        run: |
          scp -i key.pem -o StrictHostKeyChecking=no app.tar ubuntu@${{ secrets.EC2_HOST }}:/home/ubuntu

      - name: Run container
        run: |
          ssh -i key.pem ubuntu@${{ secrets.EC2_HOST }} << 'EOF'
            docker load < app.tar
            docker stop demo || true
            docker rm demo || true
            docker run -d -p 80:3000 --name demo demo-app
          EOF
```

---

## ❌ Common Errors & Fixes

### ❌ Error: `Load key: invalid format`

**Reason:** Multiline SSH key broken in GitHub secrets

✅ **Fix:** Always base64 encode key

---

### ❌ Error: `permission denied (publickey)`

**Reasons:**

* Wrong EC2 user (`ubuntu` vs `ec2-user`)
* Key not added to instance

---

### ❌ Error: `docker: command not found`

**Reason:** Docker not installed

✅ **Fix:** Ensure user-data script exists

---

## 🚀 Demo Flow (What You Show Someone)

```bash
terraform apply
git push origin main
```

Open browser:

```
http://EC2_IP
```

---

## 💣 Destroy Everything (MOST IMPORTANT)

```bash
terraform destroy
```

✅ EC2 deleted
✅ Security group deleted
✅ Cost = **₹0 after this**

---

## 💰 Cost Summary

| Resource       | Cost               |
| -------------- | ------------------ |
| EC2            | Only while running |
| Terraform      | Free               |
| GitHub Actions | Free tier          |
| Idle infra     | ₹0                 |

---

## 🧠 Final Golden Rules

* Infra should be **re-creatable in minutes**
* If destroy scares you → automation missing
* Never manually SSH for deployments

---

## 🎯 What You Can Do Next

* Move EC2 → ECS
* Add RDS snapshot restore
* Add staging vs prod
* Add secrets manager

---

✅ **If you master this document, you already think like a senior backend engineer.**
