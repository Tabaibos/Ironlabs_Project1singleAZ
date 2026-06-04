Goal:

Automation, modularity

Create a tfvars file in folder, aka terraform/ with the followinf format

myIP     = < insert your IP>
key_name = < insert key name>

Where:
   myIP is the ip of your network should be of type /32.
   key_name is an already existing key of zone us-east-1. This key is just to access the bastion host which will be deleted automatically after the application is running.

If debugging needed, please de-comment the line in the setup_provision.sh script in line xxxxxxxx.

Then, simply run:
   1) in provision_s3 folder, the main.tf to provision an S3 + DynamoDB to save state of infra (for first time only)
   2) inside ansible folder, create secrets.yml file where pg_user and pg_password are defined for creation/connection to Posgres DB
         example:

         pg_user: </insertUsername>
         pg_password: </insertPassword>


   3) setup_provision.sh in your local machine

(if names needed to be changed please account for the changes latter on)


(
   local dependencies needed:
      aws account
      aws cli installed
      terraform installed   
   )

