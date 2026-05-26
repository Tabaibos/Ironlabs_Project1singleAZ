run the setup_provision.sh script to deploy.

Current state:
Infrastruture completed (+bastion) w/terraform


Working: (branch)
importing into bastion the necessary files to deply ansible +docker.
Seleting the modules needed to run the application. (Test first on a different ec2 to see if the application runs then test in this setup)
    -> in all, git, docker, apt update
    -> specific hosts;.....

Future tasks:
docker compose on app server 
figure out how to deploy the containers
