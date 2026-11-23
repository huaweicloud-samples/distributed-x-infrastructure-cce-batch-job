region            = "cn-north-4"
availability_zone = "cn-north-4a"
project_name      = "batch-job"

app         = "perseverance"
component   = "import-moon-lander"
environment = "dev"

# 华为云凭证：请勿在此文件写入真实值。
# 优先使用环境变量：
#   export HW_ACCESS_KEY=<AK>
#   export HW_SECRET_KEY=<SK>
# 其次使用同目录下的 terraform.tfvars.local（已被 .gitignore 忽略，不随仓库分发）。
hw_access_key = ""
hw_secret_key = ""
hw_project_id = "cc2cb3d01b0c46798d77c4cd8ecf6b7e"

node_flavor = "s6.large.2"
node_count  = 1
# 节点登录密码同样走环境变量（HW_NODE_PASSWORD），此处留空。
node_password = ""

swr_organization_name = "batch-org"
swr_repository_name   = "batch-job"
swr_username          = "GT-dgcmy"
# SWR 登录密码走环境变量（HW_SWR_PASSWORD），此处留空。
swr_password = ""

docker_source_path = "../src"
docker_file_path   = "Dockerfile"
docker_build_args  = {}

image_tag = "latest"

job_command = ["python", "hello_mars.py"]
job_vcpu    = 0.25
job_memory  = 512
job_environment_variables = [
  { name = "MISSION-MARS", value = "This is good" },
  { name = "TEST", value = "beta" }
]

cron_schedule = "0 20 * * *"

log_retention_in_days = 30
node_key_pair         = "batch-job-key"
