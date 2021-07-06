# Roteiro

1. Iremos criar as máquinas na AWS e no GCP. Depois de criadas, iremos entrar nelas e configurar o cluster do banco de dados.

2. Depois de configurado, iremos criar os balanceadores de carga para os bancos de dados. 


```sh 




# --image-id              ami-0b9064170e32bde34
# --instance-type         t3.medium 
# --key-name              multicloud 
# --security-group-ids    sg-0f001cfd035ce11a8
# --subnet-id             subnet-f3621789

# AWS NODE
$ aws ec2 run-instances --image-id ami-0b9064170e32bde34 --count 2 --instance-type t3.small --key-name multicloud --security-group-ids sg-0f001cfd035ce11a8 --subnet-id subnet-f3621789 --user-data file://node-aws.sh --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cockroachdb}]' 'ResourceType=volume,Tags=[{Key=Name,Value=cockroachdb}]' --profile fernando --region us-east-2 

```

Pegar os IP's das maquinas do Google Cloud

AWS 18.216.161.12
AWS 18.117.161.87

GCP 34.139.238.81
GCP 34.73.20.111


18.216.161.12,18.117.161.87,34.139.238.81,34.73.20.111


Entrar dentro das maquinas AWS e configurar

```sh

ssh -i devops-multicloud.pem ubuntu@3.16.216.254
ssh -i devops-multicloud.pem ubuntu@3.143.245.211

cockroach start --insecure --advertise-addr=18.216.161.12 --join=18.216.161.12,18.117.161.87,34.139.238.81,34.73.20.111 --cache=.25 --max-sql-memory=.25  --background

cockroach start --insecure --advertise-addr=18.117.161.87 --join=18.216.161.12,18.117.161.87,34.139.238.81,34.73.20.111 --cache=.25 --max-sql-memory=.25  --background


cockroach init --insecure
cockroach sql --insecure

CREATE DATABASE books;


```

3.143.245.211:8080

Erro que pode acontecer caso os nodes não estejam sincronizados.

***F210415 00:13:41.913691 2763 server/server.go:276 ⋮ [n1] clock synchronization error: this node is more than 500ms away from at least half of the known nodes (0 of 1 are within the offset)
goroutine 2763 [running]:
github.com/cockroachdb/coc***




# INSTALAÇÃO DO ELB PARA DB


```sh
# LOAD BALANCER

# Primeiro criar as instâncias, explicar a rede, ec2, ebs - Na aws e no gcp. 

# !! ESPECIFICAR O SECURITY GROUPS DO LOAD BALANCER

# --subnets subnet-19645b71 subnet-f3621789

$ aws elbv2 create-load-balancer --name cockroachdb --type network  --scheme internal --subnets subnet-19645b71 subnet-f3621789 --profile fernando --region us-east-2 
#"LoadBalancerArn": "arn:aws:elasticloadbalancing:us-east-2:646025261134:loadbalancer/net/cockroachdb/5385daf5e21ac419",

$ aws elbv2 modify-load-balancer-attributes \
	--load-balancer-arn arn:aws:elasticloadbalancing:us-east-2:646025261134:loadbalancer/net/cockroachdb/5385daf5e21ac419 \
	--attributes '[{"Key":"load_balancing.cross_zone.enabled","Value":"true"}]' --profile fernando --region us-east-2 

# Key=string,Value=string
#	 "LoadBalancerArn": "arn:aws:elasticloadbalancing:us-east-1:984102645395:loadbalancer/net/cockroachdb/95cf46020db458f1"


# --vpc-id vpc-e6afbb8e
$ aws elbv2 create-target-group --name cockroachdb --protocol TCP --port 26257 --vpc-id vpc-e6afbb8e --health-check-port 8080 --profile fernando --region us-east-2 
#"TargetGroupArn": "arn:aws:elasticloadbalancing:us-east-2:646025261134:targetgroup/cockroachdb/aea807ef7aea7ba2",	

# REGISTRAR OS TARGETS  
#i-001c1e9e30e2b57f0
#i-05c3e5932fa093d2f
$ aws elbv2 register-targets --target-group-arn arn:aws:elasticloadbalancing:us-east-2:646025261134:targetgroup/cockroachdb/aea807ef7aea7ba2 --targets Id=i-001c1e9e30e2b57f0 Id=i-05c3e5932fa093d2f --profile fernando --region us-east-2 


# HTTPS - CRIADO PRIMEIRO
$ aws elbv2 create-listener \
    --load-balancer-arn arn:aws:elasticloadbalancing:us-east-2:646025261134:loadbalancer/net/cockroachdb/5385daf5e21ac419 \
    --protocol TCP \
    --port 26257 \
	--default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-2:646025261134:targetgroup/cockroachdb/aea807ef7aea7ba2 --profile fernando --region us-east-2 
# "ListenerArn": "arn:aws:elasticloadbalancing:us-east-2:646025261134:listener/net/cockroachdb/5385daf5e21ac419/19bb34062fbc9427",


$ aws elbv2 describe-target-health --target-group-arn targetgroup-arn

# DESCRIBE NO LISTENER
$ aws elbv2 describe-listeners --listener-arns arn:aws:elasticloadbalancing:us-east-1:984102645395:listener/net/cockroachdb/95cf46020db458f1/3f87271d6ce677cb
```
