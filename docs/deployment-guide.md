# 部署指导书

## 前置条件

1. 已安装 Terraform >= 1.5
2. 已安装 Docker（用于本地构建容器镜像）
3. 拥有华为云账号，并已获取 AK/SK
4. 已开通 CCE、SWR、LTS 服务

## 环境变量配置

在终端中设置华为云凭证：

```bash
export HW_ACCESS_KEY="<your-access-key>"
export HW_SECRET_KEY="<your-secret-key>"
```

## 部署步骤

### 1. 进入部署目录

```bash
cd distributed-x-infrastructure-cce-batch-job/infra
```

### 2. 修改变量配置

编辑 `terraform.tfvars`，根据实际环境修改以下关键变量：

| 变量 | 说明 | 示例 |
|------|------|------|
| `region` | 华为云区域 | `cn-north-4` |
| `swr_organization_name` | SWR 组织名 | `batch-org` |
| `swr_username` | SWR 登录用户名 | 华为云账号名 |
| `swr_password` | SWR 登录密码 | 华为云账号密码 |
| `cron_schedule` | 定时表达式（5 字段 cron） | `0 20 * * *` |
| `job_command` | 容器启动命令 | `["python", "hello_mars.py"]` |

### 3. 初始化 Terraform

```bash
terraform init
```

### 4. 预览部署计划

```bash
terraform plan
```

确认将要创建的资源列表无误。

### 5. 执行部署

```bash
terraform apply
```

输入 `yes` 确认部署。

### 6. 验证部署

查看输出信息：

```bash
terraform output
```

确认 CCE 集群、SWR 镜像、CronJob 等资源已创建。

## 清理资源

```bash
terraform destroy
```

输入 `yes` 确认销毁所有资源。

## 常见问题

### SWR 认证失败

确认 `swr_username` 和 `swr_password` 使用的是华为云账号的登录名和密码（或长期有效 AK/SK）。SWR 的 Docker 登录凭证与控制台登录凭证一致。

### CCE 集群创建超时

CCE 集群创建通常需要 5-10 分钟。如果超时，检查子网和安全组配置是否正确，以及该可用区是否有足够的资源配额。

### CronJob 未执行

使用 kubectl 检查 CronJob 状态：

```bash
kubectl get cronjob
kubectl get jobs
kubectl logs <job-pod-name>
```

确认 cron 表达式格式正确（K8s 使用 5 字段 cron：分 时 日 月 周）。
