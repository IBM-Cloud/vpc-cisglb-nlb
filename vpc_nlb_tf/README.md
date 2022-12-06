# Schematics users

Open the Settings tab and edit the *Variables* using the three vertical dots menus.  Click the information symbol for a description of each variable. 

Schematics will execute terraform using the credentials of the current user.  Make sure that you have the permissions to create the resources described in github repository main README.md

Hit the **Apply plan** button.  Check the results in the **Jobs** panel.  Scroll to the end of a **Apply plan successful** log to see the test curl commands that you can run from your desktop:

Example:
```
 2022/12/06 15:39:00 Terraform refresh | Outputs:
 2022/12/06 15:39:00 Terraform refresh | 
 2022/12/06 15:39:00 Terraform refresh | cis_glb = "glbnlbvpc9-vpc.ibmom.com"
 2022/12/06 15:39:00 Terraform refresh | nlbs = {
 2022/12/06 15:39:00 Terraform refresh |   "glbnlbvpc9-vpc-us-south-1" = "52.116.132.95"
 2022/12/06 15:39:00 Terraform refresh |   "glbnlbvpc9-vpc-us-south-2" = "52.118.209.16"
 2022/12/06 15:39:00 Terraform refresh | }
 2022/12/06 15:39:00 Terraform refresh | test_curl_glb = <<EOT
 2022/12/06 15:39:00 Terraform refresh | curl glbnlbvpc9-vpc.ibmom.com/instance
 2022/12/06 15:39:00 Terraform refresh | 
 2022/12/06 15:39:00 Terraform refresh | EOT
 2022/12/06 15:39:00 Terraform refresh | test_curl_nlbs = [
 2022/12/06 15:39:00 Terraform refresh |   <<-EOT
 2022/12/06 15:39:00 Terraform refresh |   curl 52.116.132.95/instance;# glbnlbvpc9-vpc-us-south-1
 2022/12/06 15:39:00 Terraform refresh |   
 2022/12/06 15:39:00 Terraform refresh |   EOT,
 2022/12/06 15:39:00 Terraform refresh |   <<-EOT
 2022/12/06 15:39:00 Terraform refresh |   curl 52.118.209.16/instance;# glbnlbvpc9-vpc-us-south-2
 2022/12/06 15:39:00 Terraform refresh |   
 2022/12/06 15:39:00 Terraform refresh |   EOT,
 2022/12/06 15:39:00 Terraform refresh | ]
```

Example curl to the CIS GLB:
```
curl glbnlbvpc9-vpc.ibmom.com/instance
```
## Clean up
Click **Actions** menu and select **Destroy resources**.
When the Desroy resources is complete click **Actions** menu and select **Delete workspace**.