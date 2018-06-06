module "vpc" {
    source                      = "github.com/thinkstack-co/terraform-modules//modules/aws/vpc"

    name                        = "client_prod_vpc"
    vpc_cidr                    = "10.11.0.0/16"
    azs                         = ["us-east-1a", "us-east-1b"]
    db_subnets_list             = ["10.11.11.0/24", "10.11.12.0/24"]
    dmz_subnets_list            = ["10.11.101.0/24", "10.11.102.0/24"]
    private_subnets_list        = ["10.11.1.0/24", "10.11.2.0/24"]
    public_subnets_list         = ["10.11.201.0/24", "10.11.202.0/24"]
    workspaces_subnets_list     = ["10.11.21.0/24", "10.11.22.0/24"]
    enable_firewall             = true
    fw_network_interface_id     = "${module.aws_ec2_fortigate_fw.private_network_interface_id}"
    tags                    = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "core_infrastructure"
    }
}