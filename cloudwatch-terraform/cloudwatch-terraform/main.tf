# CloudWatch Log Groups converted from the provided CloudFormation template.
# Names and retention periods are retained exactly as supplied.
locals {
  log_groups = {
    "salt_minion_logs" = 30
    "audit_logs" = 30
    "cloudwatch_agent_logs" = 30
    "appian_login_audit" = 30
    "appian_logout_audit" = 30
    "appian_deletion" = 30
    "appian_tomcat_stdOut" = 30
    "appian_jwq_monitor" = 30
    "appian_ajp_monitor" = 30
    "appian_authz_audit" = 30
    "appian_deployment_log" = 30
    "appian_groups" = 30
    "appian_service_manager" = 30
    "appian_admin_console_audit" = 30
    "appian_admin_console_user_start_pages_audit" = 30
    "appian_api_key_audit" = 30
    "appian_blocked_files_audit" = 30
    "appian_csp_report_audit" = 30
    "appian_data_store_deletions_audit" = 30
    "appian_decryption_audit" = 30
    "appian_devops_infrastructure_audit" = 30
    "appian_devops_infrastructure_handler_audit" = 30
    "appian_devops_infrastructure_request_audit" = 30
    "appian_forgot_password_requests_audit" = 30
    "appian_news_usage_audit" = 30
    "appian_oauth_auth_code_grant_for_process_mining_audit" = 30
    "appian_oauth_callback_audit" = 30
    "appian_oauth_client_credentials_grant_for_web_apis_audit" = 30
    "appian_object_rolemap_audit" = 30
    "appian_password_resets_audit" = 30
    "appian_symmetric_key_requests_audit" = 30
    "appian_secure_credentials_store_audit" = 30
    "appian_task_errors_audit" = 30
    "appian_types_outdated_refs_audit" = 30
    "appian_unscanned_files_audit" = 30
    "appian_username_changes_audit" = 30
    "appian_login_dpp" = 30
    "appian_logout_dpp" = 30
    "appian_deletion_dpp" = 30
    "appian_sites_usage_dpp" = 30
    "appian_file_attachment_downloads_dpp" = 30
    "kc_server" = 30
    "salt_server_logs" = 30
    "vault_logs" = 30
    "k8s_logs" = 30
    "appian_user_management_audit" = 30
    "mission_manager_au16_events" = 30
    "au16_logging_lambda" = 30
  }
}

resource "aws_cloudwatch_log_group" "groups" {
  for_each = local.log_groups

  name              = each.key
  retention_in_days = each.value

  lifecycle {
    prevent_destroy = true
  }
}
