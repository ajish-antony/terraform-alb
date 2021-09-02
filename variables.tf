#################################################
        # Provider & Project Details
#################################################

variable "region"     {}

variable "access_key" {}

variable "secret_key" {}

variable "project"    {}

#################################################
        # VPC Requiremnet
#################################################

variable "vpc_cidr"   {}

variable "subnetcidr" {}

#################################################
        # EC2 Requirement 
#################################################

variable  "ami"      {}

variable  "type"     {}

variable  "vol_size" {}

variable  "key"      {}

#################################################
        # ASG Requirement
#################################################

variable  "min"     {}

variable  "max"     {}

variable  "desired" {}


#################################################
        # Listner Rule 
#################################################

variable "domain1" {}   

variable "domain2" {}    
