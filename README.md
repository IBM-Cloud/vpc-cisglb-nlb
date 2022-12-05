# Regional load balancer accessable through CIS GLB

Connect an IBM Cloud Internet Services, CIS, Global Load Balancer, GLB to an application that is load balanced using a Virtual Private Cloud, VPC, Network Load Balancer, NLB.  The NLB back end can be Virtual Server Instances, VSIs, or IBM Kubernetes Services, IKS.

VPC, VSI, NLB, CIS:

![image](diagrams/vpc-cisglb-nlb-arch.svg)

VPC IBM Kubernetes Service, IKS, cluster:

![image](diagrams/vpc-cisglb-nlb-iks.svg)

NOTE the implementations below are for demonstration purposes.  Production environmens should be adjusted to meet security and production requirements.

## IC_API_KEY Terraform Configuration

The terraform configuration will run from your laptop.  See [terraform](https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-tutorials#getting-started-macos_terraform) getting started instructions.

The environment variable IC_API_KEY=your_api_key is required to configure the [IBM Cloud Provider plug-in](https://cloud.ibm.com/docs/ibm-cloud-provider-for-terraform?topic=ibm-cloud-provider-for-terraform-provider-reference#provider-parameter-ov)

```
cp template.local.env local.env
vi local.env;# edit in your apikey
source local.env
```

## VPC, VSI, NLB, CIS Configuration

To create the VPC, subnets, NLB, Instances, and CIS GLB change to the vpc_nlb_tf directory and do it:

```
cd vpc_nlb_tf
cp template.terraform.tfvars terraform.tfvars
vi terraform.tfvrs; # make edits suggested
terraform init
terraform apply
```

The output will provide some test curl commands for the CIS GLB and the VPC NLBs.  Try these out to verify your results.

## IKS, NLB, CIS Configuration
To create the IKS cluster, Deployments and Services (with VPC NLBs) use the iks_tf directory.

```
cd iks_tf
cp template.terraform.tfvars terraform.tfvars
vi terraform.tfvrs; # make edits suggested
terraform init
terraform apply
```

It can take over an 60 minutes for the IKS cluster to be created and over 10 minutes for the Kubernetes Service with associated VPC NLBs to be created.

NOTE SECURITY ALERT: Once complete a directory with a name ID_admin_k8sconfig, like 173a63396eec78a68eb08909cf70204f61cbbe2ee02c699ac078ec0c2c552a1c_ce4n8jsd0lnv9j97v45g_admin_k8sconfig, will be created and it has the credentials to access the kubernetes cluster.

The ID_admin_k8sconfig/config.yaml file can be used to inspect the kubernetes resources: `export KUBECONFIG=173a63396eec78a68eb08909cf70204f61cbbe2ee02c699ac078ec0c2c552a1c_ce4n8jsd0lnv9j97v45g_admin_k8sconfig/config.yml

The output will provide some test curl commands for the CIS GLB and the VPC NLBs.  Try these out to verify your results.

## Clean Up

In either the vpc_nlb_tf/ iks_tf/ directories you can destroy all of the resources:

```
terraform destroy
```