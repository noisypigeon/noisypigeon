# compute-instance

A Scaleway compute Instance (`scaleway_instance_server`) with a randomized name suffix. Minimal interface — `image` and `type` (defaults to `STARDUST1-S`), no storage sizing, networking, or IP configuration yet.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_volume_ids"></a> [additional\_volume\_ids](#input\_additional\_volume\_ids) | IDs of pre-created block volumes (e.g. scaleway/block-volume's id output) to attach to the instance | `list(string)` | `[]` | no |
| <a name="input_buckets"></a> [buckets](#input\_buckets) | Buckets to configure in rclone (rclone/neovim always install regardless) | <pre>list(object({<br/>    bucket_name       = string<br/>    bucket_alias      = string<br/>    bucket_endpoint   = string<br/>    bucket_access_key = string<br/>    bucket_secret_key = string<br/>    bucket_provider   = string<br/>  }))</pre> | `[]` | no |
| <a name="input_enable_ipv6"></a> [enable\_ipv6](#input\_enable\_ipv6) | Create and attach a routed IPv6 address (true/false) | `bool` | `false` | no |
| <a name="input_image"></a> [image](#input\_image) | Instance image (UUID or marketplace label) | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Instance name suffix | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Instance name prefix | `string` | n/a | yes |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | SSH public keys granted instance-specific access via Scaleway's AUTHORIZED\_KEY tag convention, in addition to account-wide keys | `list(string)` | `[]` | no |
| <a name="input_type"></a> [type](#input\_type) | Instance commercial type | `string` | `"STARDUST1-S"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | Instance ID |
| <a name="output_name"></a> [name](#output\_name) | Computed instance name |
| <a name="output_private_ips"></a> [private\_ips](#output\_private\_ips) | Private IPs attached to the instance |
| <a name="output_public_ips"></a> [public\_ips](#output\_public\_ips) | Public IPs attached to the instance |
<!-- END_TF_DOCS -->
