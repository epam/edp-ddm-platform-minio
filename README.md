<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_keycloak"></a> [keycloak](#requirement\_keycloak) | >= 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.25.0 |
| <a name="provider_http"></a> [http](#provider\_http) | 3.0.1 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.1.1 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.3.2 |
| <a name="provider_template"></a> [template](#provider\_template) | 2.2.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ebs_volume.minio_ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_eip.minio_ip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip_association.minio_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip_association) | resource |
| [aws_instance.minio](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_key_pair.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_security_group.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.minio](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_volume_attachment.minio_ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [null_resource.main](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.minio_init](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [tls_private_key.main](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_internet_gateway.gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/internet_gateway) | data source |
| [aws_nat_gateway.cluster_ip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/nat_gateway) | data source |
| [aws_subnet.public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [http_http.external_ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [template_file.format_ssh](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.minio](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | n/a | `string` | `"eu-central-1"` | no |
| <a name="input_aws_zone"></a> [aws\_zone](#input\_aws\_zone) | n/a | `string` | `"eu-central-1b"` | no |
| <a name="input_backup_bucket_name"></a> [backup\_bucket\_name](#input\_backup\_bucket\_name) | Bucket name for storing backups | `string` | `"backup-bucket"` | no |
| <a name="input_baseDomain"></a> [baseDomain](#input\_baseDomain) | baseDomain | `string` | `"mdtu-ddm.projects.epam.com"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cluster name | `string` | `"main"` | no |
| <a name="input_custom_ingress_rules_cidrs"></a> [custom\_ingress\_rules\_cidrs](#input\_custom\_ingress\_rules\_cidrs) | List of CIDRs for ingress rules. \|<br>**Optional** \|<pre>["85.223.209.0/24"]</pre> | `list(any)` | <pre>[<br>  "85.223.209.0/24"<br>]</pre> | no |
| <a name="input_minio_ebs_volume_size"></a> [minio\_ebs\_volume\_size](#input\_minio\_ebs\_volume\_size) | Default data volumes size for storage | `string` | `300` | no |
| <a name="input_minio_ec2_instance_type"></a> [minio\_ec2\_instance\_type](#input\_minio\_ec2\_instance\_type) | Default instance size for minio instance | `string` | `"t2.micro"` | no |
| <a name="input_minio_root_user"></a> [minio\_root\_user](#input\_minio\_root\_user) | n/a | `string` | `"minio"` | no |
| <a name="input_minio_url"></a> [minio\_url](#input\_minio\_url) | n/a | `string` | `"https://dl.min.io/server/minio/release/linux-amd64/minio"` | no |
| <a name="input_minio_volume_path"></a> [minio\_volume\_path](#input\_minio\_volume\_path) | n/a | `string` | `"/dev/xvdh"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. | `map(any)` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR of the VPC | `string` | `"192.168.100.0/24"` | no |
| <a name="input_wait_for_cluster_cmd"></a> [wait\_for\_cluster\_cmd](#input\_wait\_for\_cluster\_cmd) | Custom local-exec command to execute for determining if the eks cluster is healthy. Cluster endpoint will be available as an environment variable called ENDPOINT | `string` | `"bash -c 'until wget -O - -q $ENDPOINT >/dev/null && true ; do echo \"Waiting for Minio is up and port 9001 is open\"; sleep 15; done'"` | no |
| <a name="input_wait_for_cluster_interpreter"></a> [wait\_for\_cluster\_interpreter](#input\_wait\_for\_cluster\_interpreter) | Custom local-exec command line interpreter for the command to determining if the eks cluster is healthy. | `list(string)` | <pre>[<br>  "/bin/sh",<br>  "-c"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_minio_cred"></a> [minio\_cred](#output\_minio\_cred) | n/a |
| <a name="output_minio_password"></a> [minio\_password](#output\_minio\_password) | n/a |
| <a name="output_minio_username"></a> [minio\_username](#output\_minio\_username) | n/a |
<!-- END_TF_DOCS -->

### License

The platform-minio is Open Source software released under
the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0).
