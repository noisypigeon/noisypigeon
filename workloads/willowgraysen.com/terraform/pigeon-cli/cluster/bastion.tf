# # Diagnostic-only instance to verify the SSH-routing conflict documented at
# # https://www.scaleway.com/en/docs/public-gateways/troubleshooting/cant-connect-to-instance-with-pn-gateway/ :
# # "The Public Gateway's default route advertisement takes priority over the
# # default route through a resource's public interface." Any instance on
# # module.cluster's shared Private Network (push_default_route = true on its
# # scaleway_vpc_gateway_network, ADR-0145) should have this same problem --
# # this bastion deliberately keeps a public IP (enable_ipv4 = true) so direct
# # SSH to it can be compared against the PAT-rule path below.
# #
# # Looked up by name rather than threaded through module.cluster's outputs
# # (pigeon-cluster doesn't expose these) -- fine for a throwaway diagnostic
# # leaf-level resource, not worth a module release for.
# data "scaleway_vpc_private_network" "jobs" {
#   name       = "pigeon-cli-jobs"
#   project_id = local.scaleway_project_id
# }

# data "scaleway_vpc_public_gateway" "jobs" {
#   name       = "pigeon-cli-jobs-gw"
#   project_id = local.scaleway_project_id
# }

# data "scaleway_vpc_public_gateway_ip" "jobs" {
#   ip_id = data.scaleway_vpc_public_gateway.jobs.ip_id
# }

# # Not provisioned through module "cluster" / pigeon-cluster -- that always
# # sets self_delete_on_exit = true, which is separately known-broken and
# # irrelevant here; this box should just stay up until you're done with it.
# module "bastion" {
#   source = "https://pigeon.dev/modules/scaleway/compute-instance/v5.6.1"

#   name_prefix = "pigeon-cli"
#   name_suffix = "bastion"

#   enable_ipv4            = true
#   private_network_id     = data.scaleway_vpc_private_network.jobs.id
#   enable_private_network = true
# }

# # Scaleway's own documented workaround for this exact symptom: SSH to the
# # gateway's public IP on an alternate port, PAT'd through to the bastion's
# # private IP:22 -- bypasses the hijacked default route entirely, since this
# # path never touches the bastion's own public interface.
# locals {
#   # private_ips is dual-stack (IPv4 + IPv6) -- the gateway only tracks IPv4
#   # addresses for PAT, so blindly indexing [0] can grab the IPv6 one instead.
#   bastion_private_ipv4 = [for ip in module.bastion.private_ips : ip.address if !strcontains(ip.address, ":")][0]
# }

# resource "scaleway_vpc_public_gateway_pat_rule" "bastion_ssh" {
#   gateway_id   = data.scaleway_vpc_public_gateway.jobs.id
#   private_ip   = local.bastion_private_ipv4
#   private_port = 22
#   public_port  = 2222
#   protocol     = "tcp"
# }

# output "bastion_direct_public_ip" {
#   description = "Bastion's own public IP. SSH here is EXPECTED to hang/reset if the push_default_route theory is correct -- that's the comparison point, not a bug in this file."
#   value       = module.bastion.ipv4_address
# }

# output "bastion_connect_command" {
#   description = "The actual working path, through the gateway's PAT rule"
#   value       = "ssh -p 2222 root@${data.scaleway_vpc_public_gateway_ip.jobs.address}"
# }
