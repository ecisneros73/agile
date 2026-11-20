#!/usr/bin/env bash
set -euo pipefail

# Prerequisites: appropriate AWS credentials, terraform init, and correct aws_region.
# Import ONLY after coordinating ownership transfer from CloudFormation.
terraform import 'aws_cloudwatch_log_group.groups["salt_minion_logs"]' salt_minion_logs
terraform import 'aws_cloudwatch_log_group.groups["audit_logs"]' audit_logs
terraform import 'aws_cloudwatch_log_group.groups["cloudwatch_agent_logs"]' cloudwatch_agent_logs
terraform import 'aws_cloudwatch_log_group.groups["appian_login_audit"]' appian_login_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_logout_audit"]' appian_logout_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_deletion"]' appian_deletion
terraform import 'aws_cloudwatch_log_group.groups["appian_tomcat_stdOut"]' appian_tomcat_stdOut
terraform import 'aws_cloudwatch_log_group.groups["appian_jwq_monitor"]' appian_jwq_monitor
terraform import 'aws_cloudwatch_log_group.groups["appian_ajp_monitor"]' appian_ajp_monitor
terraform import 'aws_cloudwatch_log_group.groups["appian_authz_audit"]' appian_authz_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_deployment_log"]' appian_deployment_log
terraform import 'aws_cloudwatch_log_group.groups["appian_groups"]' appian_groups
terraform import 'aws_cloudwatch_log_group.groups["appian_service_manager"]' appian_service_manager
terraform import 'aws_cloudwatch_log_group.groups["appian_admin_console_audit"]' appian_admin_console_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_admin_console_user_start_pages_audit"]' appian_admin_console_user_start_pages_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_api_key_audit"]' appian_api_key_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_blocked_files_audit"]' appian_blocked_files_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_csp_report_audit"]' appian_csp_report_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_data_store_deletions_audit"]' appian_data_store_deletions_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_decryption_audit"]' appian_decryption_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_devops_infrastructure_audit"]' appian_devops_infrastructure_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_devops_infrastructure_handler_audit"]' appian_devops_infrastructure_handler_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_devops_infrastructure_request_audit"]' appian_devops_infrastructure_request_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_forgot_password_requests_audit"]' appian_forgot_password_requests_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_news_usage_audit"]' appian_news_usage_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_oauth_auth_code_grant_for_process_mining_audit"]' appian_oauth_auth_code_grant_for_process_mining_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_oauth_callback_audit"]' appian_oauth_callback_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_oauth_client_credentials_grant_for_web_apis_audit"]' appian_oauth_client_credentials_grant_for_web_apis_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_object_rolemap_audit"]' appian_object_rolemap_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_password_resets_audit"]' appian_password_resets_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_symmetric_key_requests_audit"]' appian_symmetric_key_requests_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_secure_credentials_store_audit"]' appian_secure_credentials_store_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_task_errors_audit"]' appian_task_errors_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_types_outdated_refs_audit"]' appian_types_outdated_refs_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_unscanned_files_audit"]' appian_unscanned_files_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_username_changes_audit"]' appian_username_changes_audit
terraform import 'aws_cloudwatch_log_group.groups["appian_login_dpp"]' appian_login_dpp
terraform import 'aws_cloudwatch_log_group.groups["appian_logout_dpp"]' appian_logout_dpp
terraform import 'aws_cloudwatch_log_group.groups["appian_deletion_dpp"]' appian_deletion_dpp
terraform import 'aws_cloudwatch_log_group.groups["appian_sites_usage_dpp"]' appian_sites_usage_dpp
terraform import 'aws_cloudwatch_log_group.groups["appian_file_attachment_downloads_dpp"]' appian_file_attachment_downloads_dpp
terraform import 'aws_cloudwatch_log_group.groups["kc_server"]' kc_server
terraform import 'aws_cloudwatch_log_group.groups["salt_server_logs"]' salt_server_logs
terraform import 'aws_cloudwatch_log_group.groups["vault_logs"]' vault_logs
terraform import 'aws_cloudwatch_log_group.groups["k8s_logs"]' k8s_logs
terraform import 'aws_cloudwatch_log_group.groups["appian_user_management_audit"]' appian_user_management_audit
terraform import 'aws_cloudwatch_log_group.groups["mission_manager_au16_events"]' mission_manager_au16_events
terraform import 'aws_cloudwatch_log_group.groups["au16_logging_lambda"]' au16_logging_lambda
