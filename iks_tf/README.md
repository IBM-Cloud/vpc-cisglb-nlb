# Schematics users

Open the Settings tab and edit the *Variables* using the three vertical dots menu.  Click the information symbol for a description of each variable. 

Schematics will execute terraform using the credentials of the current user.  Make sure that you have the permissions to create the resources described in github repository main README.md

Hit the **Apply plan** button.  Check the results in the **Jobs** panel.  Scroll to the end of the **Apply plan successful** log to see the test curl commands that you can run from your desktop:

Example:
```
 2022/12/05 18:58:17 Terraform refresh | test_curl_glb = <<EOT
 2022/12/05 18:58:17 Terraform refresh | curl glbnlb7-iks.ibmom.com/instance
 2022/12/05 18:58:17 Terraform refresh | 
 2022/12/05 18:58:17 Terraform refresh | EOT
 2022/12/05 18:58:17 Terraform refresh | test_curl_nlbs = [
 2022/12/05 18:58:17 Terraform refresh |   <<-EOT
 2022/12/05 18:58:17 Terraform refresh |   curl 150.240.64.25/instance;# load-balancer-us-south-1
 2022/12/05 18:58:17 Terraform refresh |   
 2022/12/05 18:58:17 Terraform refresh |   EOT,
 2022/12/05 18:58:17 Terraform refresh |   <<-EOT
 2022/12/05 18:58:17 Terraform refresh |   curl 150.239.169.87/instance;# load-balancer-us-south-2
 2022/12/05 18:58:17 Terraform refresh |   
 2022/12/05 18:58:17 Terraform refresh |   EOT,
 2022/12/05 18:58:17 Terraform refresh | ]
 2022/12/05 18:58:17 Terraform refresh | test_kubectl = <<EOT
 2022/12/05 18:58:17 Terraform refresh | # choose one:
 2022/12/05 18:58:17 Terraform refresh | export KUBECONFIG=/tmp/tfws-0123456789iks_tf/0123456789d88d4ddc0123456789eb660123456789f3901234567890376aed24_c0123456789dk5mhj93g_admin_k8sconfig/config.yml ;# env var
 2022/12/05 18:58:17 Terraform refresh | ibmcloud cs cluster config --cluster ce0123456789k5mhj93g ;# cluster config via cluster id
```

To use kubectl from your desktop use the second method suggested.

Example:

```
ibmcloud cs cluster config --cluster ce0123456789k5mhj93g
```