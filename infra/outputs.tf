# ============================================================================
# 输出
# ============================================================================

output "cce_cluster_name" {
  description = "CCE 集群名称"
  value       = huaweicloud_cce_cluster.main.name
}

output "cce_cluster_id" {
  description = "CCE 集群 ID"
  value       = huaweicloud_cce_cluster.main.id
}

output "swr_image_url" {
  description = "SWR 容器镜像地址"
  value       = local.swr_image_url
}

output "swr_organization" {
  description = "SWR 组织名称"
  value       = huaweicloud_swr_organization.main.name
}

output "lts_log_group" {
  description = "LTS 日志组名称"
  value       = huaweicloud_lts_group.batch_log_group.group_name
}

output "lts_log_stream" {
  description = "LTS 日志流名称"
  value       = huaweicloud_lts_stream.batch_log_stream.stream_name
}

output "cronjob_name" {
  description = "CronJob 名称"
  value       = kubernetes_cron_job_v1.batch_job.metadata[0].name
}

output "vpc_id" {
  description = "VPC ID"
  value       = huaweicloud_vpc.main.id
}

output "subnet_id" {
  description = "子网 ID"
  value       = huaweicloud_vpc_subnet.main.id
}

output "security_group_id" {
  description = "安全组 ID"
  value       = huaweicloud_networking_secgroup.main.id
}

output "kube_config_raw" {
  value     = huaweicloud_cce_cluster.main.kube_config_raw
  sensitive = true
}

output "cce_eip_address" {
  value = huaweicloud_vpc_eip.cce_eip.address
}
