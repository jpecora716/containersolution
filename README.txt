Requirements:
 - docker
 - docker-compose
 - Your user should be part of the docker group or all commands need to be run as root. If you want to add your user to the docker group run: sudo usermod -aG docker $(whoami) && newgrp docker
 - terraform: https://learn.hashicorp.com/tutorials/terraform/install-cli
 - kubectl: https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
 - aws-iam-authenticator: https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html

Information:
Username: panuser
Password: panpass
Static Token: OWCBTo9hW7buI1cOS022

Steps for running the docker-compose solution:
1. docker-compose build
2. docker-compose up -d
3. Test with https: curl -ku panuser:panpass https://localhost/OWCBTo9hW7buI1cOS022
4. Test with http: curl -Lku panuser:panpass http://localhost/OWCBTo9hW7buI1cOS022/index.htm
5. You can replace localhost with the public IP address to verify as well.
6. You should receive the 'secret' text. You may need to allow port 80/443 in your firewall if you don't see anything and both containers are running (docker ps)
7. All other tests should fail without user/pass/static token
8. Clean up: docker-compose down

Steps for running the containers in AWS via EKS
1. aws configure -- You'll need to enter the credentials of an IAM user with AdministratorAccess policy attached
2. cd terraform-eks-cluster
3. terraform init
4. terraform plan -out 'pan1.tfplan'
5. terraform apply 'pan1.tfplan'
6. wait about 10min for cluster to be built and AWS ALB for EKS to be installed.
7. terraform plan -out 'pan2.tfplan' # This is required to deploy the application
8. terraform apply 'pan2.tfplan'
9. cp ~/.kube/config ~/.kube/config.old; terraform output -raw kubectl_config > ~/.kube/config
10. Get the URL of ALB: URL=$(kubectl get ingress pan-ingress -n pan -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
11. curl -ku panuser:panpass https://${URL}/OWCBTo9hW7buI1cOS022
12. curl -Lku panuser:panpass http://${URL}/OWCBTo9hW7buI1cOS022
13. You should receive the 'secret' text.
14. All other tests should fail without user/pass/static token

Clean up:
1. kubectl delete ns pan
2. terraform destroy

Resources used:
Docker Container with Web Server:
https://registry.hub.docker.com/_/nginx/

Docker Container with Basic Auth:
https://github.com/dtan4/nginx-basic-auth-proxy

EKS Terraform:
https://learn.hashicorp.com/tutorials/terraform/eks

AWS ALB Controller for Kubernetes:
https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
