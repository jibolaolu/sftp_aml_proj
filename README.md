# 🚀 SFTP Infrastructure on AWS

## 📌 Overview

This project provisions a **secure AWS SFTP (AWS Transfer Family) server** that allows users to upload and manage files in **Amazon S3** securely. The infrastructure includes:

- **AWS Transfer Family (SFTP)**
- **Amazon S3** for storage
- **IAM roles & policies** for access control
- **CloudWatch Logs** for monitoring
- **Lambda function** for processing S3 events
- **EventBridge Rules & Notifications**
- **VPC Networking** with public and private subnets
- **NLB (Network Load Balancer) and A Record for Live Environment**
- **Jenkins Pipeline for Automated Deployment**

---

## 🏗 **Architecture**

### ✅ **Components**

1. **AWS Transfer Family (SFTP)**
   - Secure file transfer using SSH key-based authentication.
   - Users are mapped to individual directories in **Amazon S3**.

2. **Amazon S3 Storage**
   - Each user has a dedicated directory in the bucket.
   - File upload triggers AWS Lambda.
   - Only `.csv` files are allowed to be uploaded to the bucket.

3. **AWS Lambda Function**
   - Processes S3 file uploads and sends metadata to an **internal API**.
   - Only triggers when a `.csv` file is uploaded.

4. **EventBridge & S3 Notifications**
   - Triggers the Lambda function when new files are uploaded.

5. **Networking & Security**
   - The SFTP server runs inside a **VPC** with **subnet and security group controls**.
   - **Public & Private Subnets** with a **NAT Gateway**.
   - **CloudWatch Logs** for monitoring.
   - **Lambda is always deployed in a private subnet.**

6. **Load Balancer & DNS**
   - **Network Load Balancer (NLB)** is used for live environments.
   - **A Record** is set up for better domain management.

7. **Jenkins Pipeline for Deployment**
   - Automated provisioning using Terraform.
   - **SSH keys are securely stored in Jenkins credentials.**
   - **Dynamic user SSH key mapping from Jenkins credentials.**
   - Deployment supports multiple environments (`dev`, `staging`, `prod`).
   
---

## 📂 **Folder Structure**

```
📁 sftp-infra/
│-- 📁 sftp_users/          # User management & SSH keys
│-- 📁 sftp_transfer/       # Terraform scripts for AWS Transfer Family
│-- 📁 sftp_lambda/         # Lambda function & triggers
│-- 📁 profiles/            # Environment-specific variables (dev, staging, prod)
│-- 📄 Jenkinsfile          # CI/CD pipeline for infrastructure deployment
│-- 📄 README.md            # Project documentation
```

---

## ⚙️ **Infrastructure Setup**

This project is provisioned using **Terraform** and deployed via **Jenkins CI/CD**.

### **🔹 Prerequisites**

- **AWS CLI** installed & configured (`aws configure`)
- **Terraform** installed (`terraform --version`)
- **Jenkins Server** with required plugins
- **SSH keys stored securely in Jenkins credentials**

---

## 🚀 **Deployment Steps**

### **Step 1️⃣: Clone the Repository**

```sh
git clone https://github.com/your-org/sftp-infra.git
cd sftp-infra
```

### **Step 2️⃣: Update Environment Variables**
Modify `profiles/dev.tfvars`, `profiles/staging.tfvars`, or `profiles/prod.tfvars` based on the environment.

```sh
vi profiles/dev.tfvars  # Edit variables for development
```

### **Step 3️⃣: Run Terraform Commands**

#### **Initialize Terraform**
```sh
terraform init
```

#### **Plan Infrastructure Changes**
```sh
terraform plan -var-file=profiles/dev.tfvars
```

#### **Apply Infrastructure Changes**
```sh
terraform apply -var-file=profiles/dev.tfvars -auto-approve
```

#### **Destroy Infrastructure (If Needed)**
```sh
terraform destroy -var-file=profiles/dev.tfvars -auto-approve
```

---

## 🤖 **Jenkins Deployment Pipeline**

### **Pipeline Stages**
1. **User Selection: Environment** - User selects `dev`, `staging`, or `prod`.
2. **Checkout Code** - Fetches the latest infrastructure code.
3. **Inject SSH Keys for SFTP Users** - Retrieves SSH public keys from Jenkins credentials.
4. **Terraform Init & State Check** - Initializes Terraform & checks for existing state.
5. **Terraform Plan** - Displays infrastructure changes.
6. **User Confirmation (Optional)** - Allows users to review the plan before applying changes.
7. **Terraform Apply** - Deploys infrastructure changes.
8. **Terraform Destroy (If Selected)** - Destroys infrastructure if requested.

### **Running the Pipeline**

1. **Trigger Jenkins Build**
   - Select the environment (`dev`, `staging`, `prod`).
   - Choose `Plan`, `Plan and Apply`, or `Destroy`.

2. **SSH Keys Injection**
   - Jenkins fetches public keys for each user dynamically.

3. **Terraform Execution**
   - Runs `terraform init`, `plan`, and `apply` with appropriate variables.

---

## 🔐 **Security Measures**

✅ **IAM Policies & Role-Based Access**
- **IAM policies restrict S3 access to only `.csv` files.**
- **Lambda execution roles grant minimal required permissions.**

✅ **Network Security**
- **SFTP runs inside a VPC** (not exposed to the public).
- **Lambda always runs in a private subnet.**
- **Load balancer and DNS setup for live environments.**

✅ **Logging & Monitoring**
- **CloudWatch Logs** monitor SFTP activity & Lambda execution.
- **EventBridge rules trigger notifications on failures.**

---

## 📌 **Conclusion**
This **SFTP infrastructure** ensures **secure, scalable, and automated file transfer** using AWS services. By integrating **Terraform & Jenkins**, the deployment process is seamless, ensuring consistency across multiple environments.

**🔹 Key Benefits:**
- **Automated deployment with Jenkins CI/CD**
- **Secure authentication with SSH keys stored in Jenkins credentials**
- **Controlled file uploads (only .csv files allowed)**
- **Scalable and highly available SFTP infrastructure**

---

## 🤝 **Contributing**
Feel free to submit issues or PRs to improve this setup. 🚀

📩 **Contact:** your-email@example.com

---

🚀 **Happy Deploying!** 🎉

