#module "frontend" {
#depends_on      = [module.backend]

 # source        = "./modules/app"
  #instance_type = var.instance_type
  #component     = "frontend"
  #ssh_user      = var.ssh_user
  #ssh_pass      = var.ssh_pass
  #env           = var.env
  #zone_id       = var.zone_id
  #vault_token   = var.vault_token


#}

#module "backend" {
#depends_on      = [module.mysql]

 # source        = "./modules/app"
  #instance_type = var.instance_type
  #component     = "backend"
  #ssh_user      = var.ssh_user
  #ssh_pass      = var.ssh_pass
  #env           = var.env
  #zone_id       = var.zone_id
  #vault_token   = var.vault_token


#}

#module "mysql" {

 # source            = "./modules/app"
  #instance_type     = var.instance_type
  #component         = "mysql"
  #env               = var.env
  #ssh_user          = var.ssh_user
  #ssh_pass          = var.ssh_pass
  #zone_id           = var.zone_id
  #vault_token       = var.vault_token

#}

module "vpc" {
  source            = "./modules/vpc"
  env               = var.env
  vpc_cidr_block    = var.vpc_cidr_block
  subnet_cidr_block = var.subnet_cidr_block
  default_vpc_cidr  = var.default_vpc_cidr
  default_vpc_id    = var.default_vpc_id
}