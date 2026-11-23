# =============================================================================
# Huawei Cloud CCE Batch Job Infrastructure
# 在 CCE 上部署容器化定时批处理作业（K8s Job / CronJob）
# =============================================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.94.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.0.0"
    }
  }
}

# 凭据来源顺序：terraform.tfvars / terraform.auto.tfvars > 环境变量。
# tfvars 中留空时自动回退到环境变量，避免真实 AK/SK 落盘。
provider "huaweicloud" {
  region     = var.region
  access_key = var.hw_access_key != "" ? var.hw_access_key : env("HW_ACCESS_KEY")
  secret_key = var.hw_secret_key != "" ? var.hw_secret_key : env("HW_SECRET_KEY")
  project_id = var.hw_project_id
}

locals {
  # SWR 镜像地址：组织名 / 仓库名 / 标签
  swr_image_url = "swr.${var.region}.myhuaweicloud.com/${var.swr_organization_name}/${var.swr_repository_name}:${var.image_tag}"

  # 资源统一命名
  name_prefix = var.project_name

  # 统一标签
  common_tags = {
    app         = var.app
    component   = var.component
    environment = var.environment
  }

  # CCE kube-apiserver 访问地址：优先公网（External）端点，回落内网（Internal）
  cce_api_endpoint = (
    length([for e in data.huaweicloud_cce_cluster.batch.endpoints : e.url if e.type == "External"]) > 0
    ? [for e in data.huaweicloud_cce_cluster.batch.endpoints : e.url if e.type == "External"][0]
    : [for e in data.huaweicloud_cce_cluster.batch.endpoints : e.url if e.type == "Internal"][0]
  )
}

# VPC
resource "huaweicloud_vpc" "main" {
  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"
}

# Subnet
resource "huaweicloud_vpc_subnet" "main" {
  name       = "${var.project_name}-subnet"
  vpc_id     = huaweicloud_vpc.main.id
  cidr       = "10.0.1.0/24"
  gateway_ip = "10.0.1.1"
}

# Security Group
resource "huaweicloud_networking_secgroup" "main" {
  name        = "${var.project_name}-sg"
  description = "Security group for ${var.project_name}"
}

# EIP for CCE public access
resource "huaweicloud_vpc_eip" "cce_eip" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.project_name}-cce-bw"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

# CCE Cluster
resource "huaweicloud_cce_cluster" "main" {
  name                   = "${var.project_name}-cce"
  cluster_type           = "VirtualMachine"
  flavor_id              = "cce.s1.small"
  vpc_id                 = huaweicloud_vpc.main.id
  subnet_id              = huaweicloud_vpc_subnet.main.id
  container_network_type = "vpc-router"
  cluster_version        = "v1.28"
  eip                    = huaweicloud_vpc_eip.cce_eip.address
  charging_mode          = "postPaid"

  tags = {
    app         = var.app
    component   = var.component
    environment = var.environment
  }
}

# CCE Node Pool
resource "huaweicloud_cce_node_pool" "main" {
  cluster_id         = huaweicloud_cce_cluster.main.id
  name               = "${var.project_name}-nodepool"
  flavor_id          = var.node_flavor
  initial_node_count = var.node_count
  subnet_id          = huaweicloud_vpc_subnet.main.id
  availability_zone  = var.availability_zone
  key_pair           = var.node_key_pair

  root_volume {
    size       = 40
    volumetype = "SSD"
  }

  data_volumes {
    size       = 100
    volumetype = "SSD"
  }

  tags = {
    app         = var.app
    component   = var.component
    environment = var.environment
  }
}

# SWR Organization
resource "huaweicloud_swr_organization" "main" {
  name = var.swr_organization_name
}

# LTS Log Group
resource "huaweicloud_lts_group" "batch_log_group" {
  group_name  = "cce-batch-${var.app}-${var.component}-${var.environment}"
  ttl_in_days = var.log_retention_in_days
}

# LTS Log Stream
resource "huaweicloud_lts_stream" "batch_log_stream" {
  group_id    = huaweicloud_lts_group.batch_log_group.id
  stream_name = "job-logs"
  ttl_in_days = var.log_retention_in_days
}

# =============================================================================
# K8s 工作负载（Job / CronJob）
# -----------------------------------------------------------------------------
# 「作业定义 + 作业队列 + 定时触发」三件套，
# 在华为云以 CCE + K8s CronJob 落地：
#   - CronJob 承载「定时触发」（schedule）
#   - jobTemplate 承载「作业定义」（容器镜像 / 命令 / 环境变量 / 资源配额）
#   - 调度与队列由 K8s 默认调度器承担
# =============================================================================

# CCE 集群信息（含 kubeconfig / 证书），用于连接 kubernetes provider
data "huaweicloud_cce_cluster" "batch" {
  id     = huaweicloud_cce_cluster.main.id
  status = "Available"
}

# kubernetes provider：连接刚创建的 CCE 集群
# 认证用集群签发的客户端证书（client certificate），无需 token。
# 端点取 External（集群已绑定 EIP，公网可达）；若无 EIP 则回落到 Internal。
provider "kubernetes" {
  host                   = local.cce_api_endpoint
  cluster_ca_certificate = base64decode(data.huaweicloud_cce_cluster.batch.certificate_clusters[0].certificate_authority_data)
  client_key             = base64decode(data.huaweicloud_cce_cluster.batch.certificate_users[0].client_key_data)
  client_certificate     = base64decode(data.huaweicloud_cce_cluster.batch.certificate_users[0].client_certificate_data)
}

# 定时批量作业：CronJob
resource "kubernetes_cron_job_v1" "batch_job" {
  metadata {
    name      = "${var.component}-cronjob-${var.swr_repository_name}"
    namespace = "default"

    labels = {
      app         = var.app
      component   = var.component
      environment = var.environment
    }
  }

  spec {
    # 5 字段 Cron 表达式（分 时 日 月 周），默认每天 20:00
    schedule = var.cron_schedule

    concurrency_policy = "Allow"

    successful_jobs_history_limit = 3
    failed_jobs_history_limit     = 1

    job_template {
      metadata {
        labels = {
          app         = var.app
          component   = var.component
          environment = var.environment
        }
      }

      spec {
        backoff_limit = 3

        template {
          metadata {
            labels = {
              app         = var.app
              component   = var.component
              environment = var.environment
            }
          }

          spec {
            restart_policy = "OnFailure"

            container {
              name              = "mars-lander"
              image             = local.swr_image_url
              image_pull_policy = "IfNotPresent"

              command = var.job_command

              dynamic "env" {
                for_each = var.job_environment_variables
                content {
                  name  = env.value.name
                  value = env.value.value
                }
              }

              resources {
                requests = {
                  cpu    = "${var.job_vcpu}"
                  memory = "${var.job_memory}Mi"
                }
                limits = {
                  cpu    = "${var.job_vcpu * 2}"
                  memory = "${var.job_memory * 2}Mi"
                }
              }
            }
          }
        }
      }
    }
  }
}
