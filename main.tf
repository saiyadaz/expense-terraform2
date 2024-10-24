module "frontend" {
  depends_on      = [module.backend]

instance_type      = var.instance_type
 source            = "./modules/app"
 component         = "frontend"
  env              = var.env
  zone_id          = var.zone_id
  ssh_user         = var.ssh_user
  ssh_pass         = var.ssh_pass
  vault_token      = var.vault_token
  subnets          = module.vpc.frontend_subnets
  vpc_id           = module.vpc.vpc_id
  lb_type          = "public"
  lb_needed        = true
  lb_subnets       = module.vpc.public_subnets
  app_port         = 80
  bastion_nodes    =  var.bastion_nodes
  prometheus_nodes =  var.prometheus_nodes
  server_app_port_sg_cidr= var.public_subnets
  lb_app_port_sg_cidr= ["0.0.0.0/0"] #load balancer accessing the frontend from public subnets port
}

module "backend" {
  depends_on     = [module.mysql]

source                      = "./modules/app"
instance_type               = var.instance_type
component                   = "backend"
ssh_user                    = var.ssh_user
ssh_pass                    = var.ssh_pass
env                         = var.env
zone_id                     = var.zone_id
vault_token                 = var.vault_token
subnets                     = module.vpc.backend_subnets
vpc_id                      = module.vpc.vpc_id
lb_type                     = "private"
lb_needed                   = true
lb_subnets                  = module.vpc.backend_subnets
app_port                    = 8080
bastion_nodes               =  var.bastion_nodes
prometheus_nodes            =  var.prometheus_nodes
server_app_port_sg_cidr     = concat(var.frontend_subnets, var.backend_subnets)
lb_app_port_sg_cidr         = var.frontend_subnets

}
##

#concat done because lb --backend subnets needs to access backend subnets and frontend subnets
#so ur merging the port access for both modules.


module "mysql" {

  source                  = "./modules/app"
  instance_type           = var.instance_type
  component               = "mysql"
  env                     = var.env
  ssh_user                = var.ssh_user
  ssh_pass                = var.ssh_pass
  zone_id                 = var.zone_id
  vault_token             = var.vault_token
  subnets                 = module.vpc.db_subnets
  vpc_id                  = module.vpc.vpc_id
  bastion_nodes           = var.bastion_nodes
  prometheus_nodes        = var.prometheus_nodes
  app_port                = 3306
  server_app_port_sg_cidr = var.backend_subnets
                                                   #this is to allow only the port to open to backend subnets
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