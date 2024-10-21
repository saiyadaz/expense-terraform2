module "frontend" {
  depends_on   = [module.backend]

instance_type  = var.instance_type
 source        = "./modules/app"
 component     = "frontend"
  env          = var.env
  zone_id      = var.zone_id
  ssh_user     = var.ssh_user
  ssh_pass     = var.ssh_pass
  vault_token  = var.vault_token
  subnets      = module.vpc.db_subnets
  vpc_id       = module.vpc.vpc_id

}

module "backend" {
  depends_on   = [module.mysql]

source        = "./modules/app"
instance_type = var.instance_type
component     = "backend"
ssh_user      = var.ssh_user
ssh_pass      = var.ssh_pass
env           = var.env
zone_id       = var.zone_id
vault_token   = var.vault_token
subnets       = module.vpc.db_subnets
vpc_id        = module.vpc.vpc_id


}

module "mysql" {

  source            = "./modules/app"
  instance_type     = var.instance_type
  component         = "mysql"
  env               = var.env
  ssh_user          = var.ssh_user
  ssh_pass          = var.ssh_pass
  zone_id           = var.zone_id
  vault_token       = var.vault_token
  subnets           = module.vpc.db_subnets
  vpc_id            = module.vpc.vpc_id
  }

module "vpc" {
  source                 = "./modules/vpc"
  env                    = var.env
  vpc_cidr_block         = var.vpc_cidr_block
  default_vpc_cidr       = var.default_vpc_cidr
  default_vpc_id         = var.default_vpc_id
  default_route_table_id = var.default_route_table_id
  frontend_subnets       = var.frontend_subnets
  backend_subnets        = var.backend_subnets
  db_subnets             = var.db_subnets
  availability_zones     = var.availability_zones
  public_subnets         = var.public_subnets
}

#ssh_user          = var.ssh_user
#ssh_pass          = var.ssh_pass