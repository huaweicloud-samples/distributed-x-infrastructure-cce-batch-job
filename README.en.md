# distributed-x-infrastructure-cce-batch-job

![License: MIT No Attribution](https://img.shields.io/badge/License-MIT--0-yellow.svg)
![Huawei Cloud](https://img.shields.io/badge/Cloud-HuaweiCloud-red.svg)

## 1. Overview

### Overview

This practice demonstrates how to use Terraform to deploy a containerized scheduled batch-compute job on Huawei Cloud. A Kubernetes CronJob runs on a CCE (Cloud Container Engine) cluster, enabling automatic build and push of container images, scheduled trigger and execution, and log collection. It fits scenarios such as data processing, ETL tasks, and periodic report generation.

---

## 2. Table of Contents

- [1. Overview](#1-overview)
- [2. Table of Contents](#2-table-of-contents)
- [3. Architecture Diagram](#3-architecture-diagram)
- [4. Highlights](#4-highlights)
- [5. Cloud Services Used](#5-cloud-services-used)
- [6. Prerequisites](#6-prerequisites)
- [7. Quick Start](#7-quick-start)
- [8. Step-by-Step Deployment](#8-step-by-step-deployment)
- [9. Usage / Verification](#9-usage--verification)
- [10. Cleanup](#10-cleanup)
- [11. Detailed Explanation](#11-detailed-explanation)
- [12. Dependencies](#12-dependencies)
- [13. FAQ / Troubleshooting](#13-faq--troubleshooting)
- [14. Contributing](#14-contributing)
- [15. License](#15-license)
- [16. Contact / Maintainers](#16-contact--maintainers)

---

## 3. Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Huawei Cloud                          │
│                                                         │
│  ┌──────────────┐    ┌──────────────────────────────┐  │
│  │     SWR      │    │         CCE Cluster           │  │
│  │ (Image Repo) │    │  ┌────────────────────────┐  │  │
│  │  batch-job   │───▶│  │     K8s CronJob         │  │  │
│  │  :latest     │    │  │  ┌──────────────────┐  │  │  │
│  └──────────────┘    │  │  │   Container Pod   │  │  │  │
│                      │  │  │  hello_mars.py    │  │  │  │
│  ┌──────────────┐    │  │  └──────────────────┘  │  │  │
│  │     LTS      │    │  │  schedule: 0 20 * * *  │  │  │
│  │ (Log Service)│◀───│  └────────────────────────┘  │  │
│  └──────────────┘    └──────────────────────────────┘  │
│                                                         │
│  VPC 10.0.0.0/16 → Subnet 10.0.1.0/24 → Security Group  │
└─────────────────────────────────────────────────────────┘
```

---

## 4. Highlights

- **Containerized job**: build a container image with Docker, push to SWR, and let CCE pull and run it
- **Scheduled trigger**: a K8s CronJob executes the job automatically per a cron expression
- **One-click deployment**: Terraform manages all resources — network, cluster, image repository, scheduled job
- **Log collection**: job logs are written automatically to LTS with configurable daily retention

---

## 5. Cloud Services Used

| Service | Purpose |
|------|------|
| CCE (Cloud Container Engine) | Provides the Kubernetes runtime that hosts the batch-job container |
| SWR (Container Image Repository) | Stores and manages container images |
| LTS (Cloud Log Service) | Collects and stores job execution logs |
| VPC (Virtual Private Cloud) | Provides an isolated network environment |

Resource cleanup: run `terraform destroy` to release all created resources.

---

## 6. Prerequisites

1. **Terraform** >= 1.5 installed
2. **Docker** installed and running (to build container images)
3. **Huawei Cloud account**: AK/SK obtained, CCE, SWR, LTS services enabled
4. **Permissions**: the account has management permissions for VPC, CCE, SWR, LTS resources

---

## 7. Quick Start

```bash
# Set credentials
export HW_ACCESS_KEY="<your-access-key>"
export HW_SECRET_KEY="<your-secret-key>"

# Enter the deployment directory
cd infra

# Edit SWR authentication info in terraform.tfvars
# Then deploy with one command
terraform init && terraform apply
```

---

## 8. Step-by-Step Deployment

### 1. Configure credentials

```bash
export HW_ACCESS_KEY="<your-access-key>"
export HW_SECRET_KEY="<your-secret-key>"
```

### 2. Enter the deployment directory

```bash
cd infra
```

### 3. Modify variable configuration

Edit `terraform.tfvars` to set parameters such as the SWR organization name, login credentials, and schedule expression.

### 4. Initialize

```bash
terraform init
```

Expected output contains `Terraform has been successfully initialized!`

### 5. Preview the plan

```bash
terraform plan
```

Confirm the resources to be created: VPC, Subnet, Security Group, CCE cluster, node pool, SWR organization, LTS log group/stream, CronJob.

### 6. Execute deployment

```bash
terraform apply
```

Type `yes` to confirm. Deployment takes about 5-10 minutes (CCE cluster creation time).

---

## 9. Usage / Verification

### Usage / Verification

This practice checks deployment results with `terraform output` and inspects CronJob and Job execution status through the CCE console or kubectl, as described below.

### View deployment results

```bash
terraform output
```

Expected output contains the CCE cluster name, SWR image address, CronJob name, etc.

### Check job execution status

Check CronJob status through the CCE console or kubectl:

```bash
# Get the CCE cluster kubeconfig (download from the console or use the command below)
# After configuring kubectl:

kubectl get cronjob
# Expected output: NAME                          SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
#           import-moon-lander-cronjob-batch-job   0 20 * * *   False    0        <time>          <age>

kubectl get jobs
# View Job execution records triggered by the CronJob

kubectl logs job/<job-name>
# Expected output: You have landed on the planet Mars!
#           Mission: This is good
#           Test: beta
```

### Trigger the job manually

```bash
kubectl create job --from=cronjob/import-moon-lander-cronjob-batch-job manual-trigger
```

After deployment, follow these steps to verify that the business functionality works before considering the delivery complete.

---

## 10. Cleanup

```bash
cd infra
terraform destroy
```

Type `yes` to confirm. CronJob, CCE cluster, SWR organization, LTS log group, network resources, etc. are released in dependency order.

---

## 11. Detailed Explanation

### Workflow

1. Terraform uses the Docker Provider to build a container image and push it to SWR
2. Terraform creates the CCE cluster and node pool
3. Terraform creates the CronJob on CCE through the Kubernetes Provider
4. The CronJob creates a Pod automatically per the cron expression (default 20:00 daily) to run the containerized job
5. The job container's stdout is collected by CCE logging and written to LTS

### Configuration items

| Variable | Description | Default |
|------|------|--------|
| `region` | Huawei Cloud region | `cn-north-4` |
| `node_flavor` | CCE node flavor | `s6.large.2` |
| `node_count` | Number of CCE nodes | `1` |
| `job_vcpu` | Job CPU quota (cores) | `0.25` |
| `job_memory` | Job memory quota (Mi) | `512` |
| `cron_schedule` | Schedule expression | `0 20 * * *` |
| `log_retention_in_days` | Log retention days | `30` |

---

## 12. Dependencies

| Dependency | Version requirement | Purpose |
|------|---------|------|
| Terraform | >= 1.5 | IaC tool |
| huaweicloud Provider | >= 1.94.0 | Huawei Cloud resource management |
| docker Provider | ~> 3.0 | Container image build and push |
| kubernetes Provider | >= 3.0.0 | K8s CronJob management |
| Docker | any | Local container image build |

---

## 13. FAQ / Troubleshooting

### FAQ / Troubleshooting

**Q: SWR authentication fails?**

Confirm that `swr_username` and `swr_password` use the Huawei Cloud account's login name and password.

**Q: CCE cluster creation times out?**

CCE cluster creation typically takes 5-10 minutes. Check the subnet and security group configuration, and the availability-zone resource quota.

**Q: CronJob does not execute?**

Use `kubectl get cronjob` to check status and confirm the cron expression format is correct (K8s uses 5 fields: minute hour day month weekday).

**Q: How to modify the job content?**

Modify `src/hello_mars.py` and re-run `terraform apply`; the Docker Provider automatically rebuilds and pushes the image.

---

## 14. Contributing

Issues and pull requests are welcome.

---

## 15. License

This project is licensed under [MIT No Attribution](LICENSE).

---

## 16. Contact / Maintainers
| Item | Content |
|---|---|
| **Creator** | [dgc-git](https://github.com/dgc-git) |
| **Maintainer** | [dgc-git](https://github.com/dgc-git) |
| **Contact** | GitHub Issues / PR (see [Section 14](#14-contributing)) |
