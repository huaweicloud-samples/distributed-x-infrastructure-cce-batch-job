# distributed-x-infrastructure-cce-batch-job

![License: MIT No Attribution](https://img.shields.io/badge/License-MIT--0-yellow.svg)
![Huawei Cloud](https://img.shields.io/badge/Cloud-HuaweiCloud-red.svg)

## 1. 简介 / Overview

### 简介


本实践展示了如何使用 Terraform 在华为云上部署容器化定时批量计算作业。通过 CCE（云容器引擎）集群运行 Kubernetes CronJob，实现容器镜像的自动构建推送、定时触发执行和日志收集，适用于数据处理、ETL 任务、定期报表生成等场景。

---

## 2. 目录

- [1. 简介 / Overview](#1-简介--overview)
- [2. 目录](#2-目录)
- [3. 架构图](#3-架构图)
- [4. 方案亮点](#4-方案亮点)
- [5. 涉及云服务](#5-涉及云服务)
- [6. 前置条件](#6-前置条件)
- [7. 快速开始](#7-快速开始)
- [8. 分步部署](#8-分步部署)
- [9. 使用方法 / 验证](#9-使用方法--验证)
- [10. 清理资源](#10-清理资源)
- [11. 详细说明](#11-详细说明)
- [12. 依赖](#12-依赖)
- [13. FAQ / 故障排除](#13-faq--故障排除)
- [14. 贡献指南](#14-贡献指南)
- [15. 许可证](#15-许可证)
- [16. 联系方式 / 维护者](#16-联系方式--维护者)

---

## 3. 架构图

```
┌─────────────────────────────────────────────────────────┐
│                    华为云                                │
│                                                         │
│  ┌──────────────┐    ┌──────────────────────────────┐  │
│  │   SWR        │    │         CCE 集群              │  │
│  │ (容器镜像仓库)│    │  ┌────────────────────────┐  │  │
│  │  batch-job   │───▶│  │     K8s CronJob         │  │  │
│  │  :latest     │    │  │  ┌──────────────────┐  │  │  │
│  └──────────────┘    │  │  │   Container Pod   │  │  │  │
│                      │  │  │  hello_mars.py    │  │  │  │
│  ┌──────────────┐    │  │  └──────────────────┘  │  │  │
│  │   LTS        │    │  │  schedule: 0 20 * * *  │  │  │
│  │ (日志服务)    │◀───│  └────────────────────────┘  │  │
│  └──────────────┘    └──────────────────────────────┘  │
│                                                         │
│  VPC 10.0.0.0/16 → Subnet 10.0.1.0/24 → Security Group  │
└─────────────────────────────────────────────────────────┘
```

---

## 4. 方案亮点

- **容器化作业**：使用 Docker 构建容器镜像，推送到 SWR，由 CCE 拉取执行
- **定时触发**：通过 K8s CronJob 按 cron 表达式自动定时执行作业
- **一键部署**：Terraform 统一管理网络、集群、镜像仓库、定时作业等全部资源
- **日志收集**：作业日志自动写入 LTS，支持按天保留

---

## 5. 涉及云服务

| 服务 | 用途 |
|------|------|
| CCE（云容器引擎） | 提供 Kubernetes 运行环境，承载批量作业容器 |
| SWR（容器镜像仓库） | 存储和管理容器镜像 |
| LTS（云日志服务） | 收集和存储作业执行日志 |
| VPC（虚拟私有云） | 提供隔离的网络环境 |

清理资源：执行 `terraform destroy` 即可释放所有创建的资源。

---

## 6. 前置条件

1. **Terraform** >= 1.5 已安装
2. **Docker** 已安装并运行（用于构建容器镜像）
3. **华为云账号**：已获取 AK/SK，已开通 CCE、SWR、LTS 服务
4. **权限**：账号需具备 VPC、CCE、SWR、LTS 资源的管理权限

---

## 7. 快速开始

```bash
# 设置凭证
export HW_ACCESS_KEY="<your-access-key>"
export HW_SECRET_KEY="<your-secret-key>"

# 进入部署目录
cd infra

# 修改 terraform.tfvars 中的 SWR 认证信息
# 然后一键部署
terraform init && terraform apply
```

---

## 8. 分步部署

### 1. 配置凭证

```bash
export HW_ACCESS_KEY="<your-access-key>"
export HW_SECRET_KEY="<your-secret-key>"
```

### 2. 进入部署目录

```bash
cd infra
```

### 3. 修改变量配置

编辑 `terraform.tfvars`，设置 SWR 组织名、登录凭证和定时表达式等参数。

### 4. 初始化

```bash
terraform init
```

预期输出包含 `Terraform has been successfully initialized!`

### 5. 预览计划

```bash
terraform plan
```

确认将创建的资源：VPC、Subnet、Security Group、CCE 集群、节点池、SWR 组织、LTS 日志组/流、CronJob。

### 6. 执行部署

```bash
terraform apply
```

输入 `yes` 确认。部署约需 5-10 分钟（CCE 集群创建时间）。

---

## 9. 使用方法 / 验证

### 使用方法/验证

本实践通过 `terraform output` 查看部署结果，并通过 CCE 控制台或 kubectl 检查 CronJob 与 Job 的执行状态，详见下列步骤。

### 查看部署结果

```bash
terraform output
```

预期输出包含 CCE 集群名称、SWR 镜像地址、CronJob 名称等。

### 查看作业执行状态

通过 CCE 控制台或 kubectl 查看 CronJob 状态：

```bash
# 获取 CCE 集群的 kubeconfig（从控制台下载或使用以下命令）
# 配置 kubectl 后：

kubectl get cronjob
# 预期输出：NAME                          SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
#           import-moon-lander-cronjob-batch-job   0 20 * * *   False    0        <time>          <age>

kubectl get jobs
# 查看 CronJob 触发的 Job 执行记录

kubectl logs job/<job-name>
# 预期输出：You have landed on the planet Mars!
#           Mission: This is good
#           Test: beta
```

### 手动触发作业

```bash
kubectl create job --from=cronjob/import-moon-lander-cronjob-batch-job manual-trigger
```

部署完成后请按本节步骤自行验证，确认业务功能可用，方可视为交付完成。

---

## 10. 清理资源

```bash
cd infra
terraform destroy
```

输入 `yes` 确认。将按依赖顺序释放 CronJob、CCE 集群、SWR 组织、LTS 日志组、网络资源等。

---

## 11. 详细说明

### 工作流程

1. Terraform 使用 Docker Provider 构建容器镜像并推送到 SWR
2. Terraform 创建 CCE 集群和节点池
3. Terraform 通过 Kubernetes Provider 在 CCE 上创建 CronJob
4. CronJob 按 cron 表达式（默认每天 20:00）自动创建 Pod 执行容器化作业
5. 作业容器的标准输出通过 CCE 日志采集写入 LTS

### 配置项说明

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `region` | 华为云区域 | `cn-north-4` |
| `node_flavor` | CCE 节点规格 | `s6.large.2` |
| `node_count` | CCE 节点数量 | `1` |
| `job_vcpu` | 作业 CPU 配额（核） | `0.25` |
| `job_memory` | 作业内存配额（Mi） | `512` |
| `cron_schedule` | 定时表达式 | `0 20 * * *` |
| `log_retention_in_days` | 日志保留天数 | `30` |

---

## 12. 依赖

| 依赖 | 版本要求 | 用途 |
|------|---------|------|
| Terraform | >= 1.5 | IaC 工具 |
| huaweicloud Provider | >= 1.94.0 | 华为云资源管理 |
| docker Provider | ~> 3.0 | 容器镜像构建推送 |
| kubernetes Provider | >= 3.0.0 | K8s CronJob 管理 |
| Docker | 任意 | 本地构建容器镜像 |

---

## 13. FAQ / 故障排除

### FAQ/故障排除

**Q: SWR 认证失败？**

确认 `swr_username` 和 `swr_password` 使用华为云账号的登录名和密码。

**Q: CCE 集群创建超时？**

CCE 集群创建通常需要 5-10 分钟。检查子网和安全组配置，以及可用区资源配额。

**Q: CronJob 未执行？**

使用 `kubectl get cronjob` 检查状态，确认 cron 表达式格式正确（K8s 使用 5 字段：分 时 日 月 周）。

**Q: 如何修改作业内容？**

修改 `src/hello_mars.py`，重新执行 `terraform apply`，Docker Provider 会自动重新构建并推送镜像。

---

## 14. 贡献指南

欢迎提交 Issue 和 Pull Request。

---

## 15. 许可证

本项目采用 [MIT No Attribution](LICENSE) 许可证。

---

## 16. 联系方式 / 维护者
| 项 | 内容 |
|---|---|
| **创建者** | [dgc-git](https://github.com/dgc-git) |
| **维护者** | [dgc-git](https://github.com/dgc-git) |
| **联系方式** | GitHub Issues / PR（见[第 14 节](#14-贡献指南)） |
