# ============================================================================
# 变量定义
# ============================================================================

variable "region" {
  description = "华为云区域"
  type        = string
  default     = "cn-north-4"
}

variable "availability_zone" {
  description = "可用区"
  type        = string
  default     = "cn-north-4a"
}

variable "project_name" {
  description = "项目名称，用于资源命名前缀"
  type        = string
  default     = "batch-job"
}

variable "app" {
  description = "应用标签"
  type        = string
  default     = "perseverance"
}

variable "component" {
  description = "组件标签"
  type        = string
  default     = "import-moon-lander"
}

variable "environment" {
  description = "环境标识（dev/prod/stage）"
  type        = string
  default     = "dev"
}

# --- 华为云凭证 ---

variable "hw_access_key" {
  description = "华为云 AK（留空则从环境变量 HW_ACCESS_KEY 读取）"
  type        = string
  sensitive   = true
  default     = ""
}

variable "hw_secret_key" {
  description = "华为云 SK（留空则从环境变量 HW_SECRET_KEY 读取）"
  type        = string
  sensitive   = true
  default     = ""
}

variable "hw_project_id" {
  description = "华为云项目 ID"
  type        = string
  default     = "cc2cb3d01b0c46798d77c4cd8ecf6b7e"
}

# --- CCE 节点配置 ---

variable "node_flavor" {
  description = "CCE 节点规格"
  type        = string
  default     = "s6.large.2"
}

variable "node_count" {
  description = "CCE 节点初始数量"
  type        = number
  default     = 1
}

variable "node_password" {
  description = "CCE 节点登录密码（留空则从环境变量 HW_NODE_PASSWORD 读取）"
  type        = string
  default     = ""
  sensitive   = true
}

# --- SWR 容器镜像仓库 ---

variable "swr_organization_name" {
  description = "SWR 组织名称"
  type        = string
}

variable "swr_repository_name" {
  description = "SWR 仓库名称"
  type        = string
  default     = "batch-job"
}

variable "swr_username" {
  description = "SWR 登录用户名（华为云账号名）"
  type        = string
}

variable "swr_password" {
  description = "SWR 登录密码（华为云账号密码或长期 AK；留空则从环境变量 HW_SWR_PASSWORD 读取）"
  type        = string
  sensitive   = true
  default     = ""
}

# --- Docker 镜像构建 ---

variable "docker_source_path" {
  description = "Docker 构建上下文路径（相对于 infra/ 目录）"
  type        = string
  default     = "../src"
}

variable "docker_file_path" {
  description = "Dockerfile 路径（相对于构建上下文）"
  type        = string
  default     = "Dockerfile"
}

variable "docker_build_args" {
  description = "Docker 构建参数"
  type        = map(string)
  default     = {}
}

variable "image_tag" {
  description = "镜像标签，留空则使用时间戳"
  type        = string
  default     = "latest"
}

# --- 批量作业配置 ---

variable "job_command" {
  description = "容器启动命令"
  type        = list(string)
  default     = ["python", "hello_mars.py"]
}

variable "job_vcpu" {
  description = "作业 CPU 配额（单位：核，如 0.25 表示 250m）"
  type        = number
  default     = 0.25
}

variable "job_memory" {
  description = "作业内存配额（单位：Mi）"
  type        = number
  default     = 512
}

variable "job_environment_variables" {
  description = "环境变量列表"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# --- 定时触发 ---

variable "cron_schedule" {
  description = "Cron 表达式（K8s CronJob 格式，5 字段：分 时 日 月 周）"
  type        = string
  default     = "0 20 * * *"
}

# --- 日志 ---

variable "log_retention_in_days" {
  description = "日志保留天数"
  type        = number
  default     = 30
}

variable "node_key_pair" {
  description = "SSH key pair name for CCE nodes"
  type        = string
  default     = "batch-job-key"
}
