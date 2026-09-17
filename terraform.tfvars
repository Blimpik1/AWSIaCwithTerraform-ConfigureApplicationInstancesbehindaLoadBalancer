aws_region            = "eu-west-1"
project_id            = "cmtr-53jrx29j"
vpc_name              = "cmtr-53jrx29j-vpc"
public_subnet_a_cidr  = "10.0.1.0/24"
private_subnet_a_cidr = "10.0.2.0/24"
public_subnet_b_cidr  = "10.0.3.0/24"
private_subnet_b_cidr = "10.0.4.0/24"

ec2_sg_name           = "cmtr-53jrx29j-ec2_sg"
http_sg_name          = "cmtr-53jrx29j-http_sg"
alb_sg_name           = "cmtr-53jrx29j-sglb"
instance_profile_name = "cmtr-53jrx29j-instance_profile"
key_pair_name         = "cmtr-53jrx29j-keypair"

launch_template_name = "cmtr-53jrx29j-template"
asg_name             = "cmtr-53jrx29j-asg"
alb_name             = "cmtr-53jrx29j-loadbalancer"

common_tags = {
  Terraform = "true"
  Project   = "cmtr-53jrx29j"
}