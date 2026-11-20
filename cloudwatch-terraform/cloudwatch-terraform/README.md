# CloudWatch Log Groups — Terraform Conversion

Generated from the attached CloudFormation JSON; includes **48 log groups**, all configured with **30-day retention**. Only `AWS::Logs::LogGroup` resources were converted; the S3 bucket and bucket policy were intentionally excluded.

## Files

- `main.tf`: exact log-group names, retention settings, and Terraform deletion protection.
- `providers.tf`, `versions.tf`, `variables.tf`: provider configuration.
- `outputs.tf`: log-group names and ARNs.
- `terraform.tfvars.example`: illustrative AWS GovCloud region; replace with the actual region.
- `import_existing.sh`: imports all 48 pre-existing groups into local Terraform state.

## New groups (only if names do not already exist)

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars to the region hosting the groups.
terraform init
terraform plan
terraform apply
```

## Existing groups (migration from CloudFormation)

**Warning:** Do not run `terraform apply` to create groups that already exist. Also, **Terraform import does not detach a resource from CloudFormation**. Two tools managing the same AWS resource can cause configuration drift or accidental deletion. Arrange a managed handoff first: review the CloudFormation stack and its Retain policies, remove the group resources from the CloudFormation stack safely using an appropriate stack refactor/resource removal process, confirm the groups still exist, then import them into Terraform. Avoid deleting the stack or changing its template without a reviewed migration plan.

```bash
cp terraform.tfvars.example terraform.tfvars
# Set the actual AWS region and credentials (AWS_PROFILE or your standard auth).
terraform init
bash import_existing.sh
terraform plan
```

`terraform plan` should report no changes for imported groups if their actual settings match the provided CloudFormation properties. Investigate any differences before applying. Review the remote backend and state controls used by your organization; the generated configuration does not include a backend, to avoid assumptions about your environment.

`prevent_destroy` protects resources from Terraform-initiated deletion while that lifecycle rule remains in configuration; it is not an AWS deletion lock, and it is not a replacement for CloudFormation Retain settings.

Log-group names and case are preserved exactly, e.g. `appian_tomcat_stdOut`.
