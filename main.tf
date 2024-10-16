module "frontend" {
depends_on      = [module.backend]

  source        = "./modules/app"
  instance_type = var.instance_type
  component     = "frontend"
  ssh_user      = var.ssh_user
  ssh_pass      = var.ssh_pass
  env           = var.env
  zone_id       = var.zone_id


}

module "backend" {
depends_on      = [module.mysql]

  source        = "./modules/app"
  instance_type = var.instance_type
  component     = "backend"
  ssh_user      = var.ssh_user
  ssh_pass      = var.ssh_pass
  env           = var.env
  zone_id       = var.zone_id


}

module "mysql" {

  source            = "./modules/app"
  instance_type     = var.instance_type
  component         = "mysql"
  env               = var.env
  ssh_user          = var.ssh_user
  ssh_pass          = var.ssh_pass
  zone_id           = var.zone_id

}
