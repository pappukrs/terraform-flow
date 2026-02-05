# 🚀 Zero-Cost Demo Deployment Guide (EKS Edition)

> **Goal:** Deploy a Node.js app on **AWS EKS** using GitHub Actions, then **destroy everything** to save costs.

---

## 🧠 Core Philosophy

* **Datacenter in a Box:** We spin up an entire Virtual Private Cloud (VPC) and Kubernetes Cluster.
* **Immutable Infrastructure:** No SSH. We replace containers, not patch servers.
* **Disposable:** Use it, demo it, destroy it.

---

## 🏗️ Architecture

```
Git Push
   ↓
GitHub Actions
   ↓
Docker Build & Push → AWS ECR
   ↓
Terraform → AWS EKS Cluster
   ↓
kubectl apply → Deployment/Service/Ingress
   ↓
AWS ALB (Load Balancer) → User
```

---

## 📦 Prerequisites

### 1️⃣ AWS Account
* IAM User with **AdministratorAccess** (EKS requires many permissions: VPC, IAM, EC2, EKS).

### 2️⃣ GitHub Secrets
* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`

---

## 🟢 Step 1 — Bootstrap
Run `infra-bootstrap.yml` workflow.
* Creates **S3** (State)
* Creates **DynamoDB** (Lock)
* Creates **ECR** (Docker Registry)

**Update** `infra/backend.tf` with the new bucket name!

---

## 🟢 Step 2 — Create Infrastructure
Run `infra-up.yml` workflow.
* Creates **VPC** (Public/Private subnets)
* Creates **EKS Cluster** & **Node Group**
* Installs **Load Balancer Controller**
* ⏳ **Wait:** 10-15 minutes.

---

## 🟢 Step 3 — Deploy
Push code to `main`.
* The `deploy.yml` workflow triggers.
* Function:
  1. Build Docker Image.
  2. Push to ECR.
  3. `envsubst` to inject ECR URL into manifests.
  4. `kubectl apply` resources.
* **Result:** Retrieve the Load Balancer URL from the GitHub Action summary.

---

## 💣 Destroy Everything
Run `infra-destroy.yml` workflow.
* **Critical:** This deletes the Ingress first to remove the AWS Load Balancer.
* Then destroys the cluster and VPC.
* **Cost:** Returns to near $0 (only state storage remains).

---

## 💰 Cost Analysis (EKS vs EC2)

| Resource | EC2 (Old) | EKS (New) |
|:---|:---|:---|
| **Control Plane** | $0 | **$0.10/hr** (~$73/mo) |
| **Compute** | t3.micro (~$0.01/hr) | t3.medium x2 (~$0.08/hr) |
| **Load Balancer** | None (Direct IP) | ALB (~$0.0225/hr + LCU) |
| **Total** | Very Low | ** Moderate** (Destroy after use!) |

---

## 📝 Cheatsheet

**Check App:**
```bash
kubectl get pods
```

**Check Access:**
```bash
kubectl get ingress
```

**Debug Controller:**
```bash
kubectl -n kube-system logs -l app.kubernetes.io/name=aws-load-balancer-controller
```
