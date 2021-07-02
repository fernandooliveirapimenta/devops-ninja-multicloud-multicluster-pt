# Roteiro

O que iremos fazer?

## Parte 1
1. Criação de usuário do IAM e permissões
2. Criação da instância do RancherServer pela aws-cli
3. Configuração do Rancher.
4. Configuração do Cluster Kubernetes.
5. Deployment do cluster pela aws-cli.



## Parte 2
6. Configuração do Traefik
7. Configuração do Longhorn
8. Criação do certificado não válido
9. Configuração do ELB
10. Configuração do Route 53


Parabéns, com isso temos a primera parte da nossa infraestrutura. 
Estamos prontos para rodar nossa aplicação.


# Parte 1

## 1 - Criação de usuário do IAM e permissões e configuração da AWS-CLI

https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html


## 2 - Criação da instância do RancherServer pela aws-cli.

```sh 

# RANCHER SERVER

# --image-id              ami-0b9064170e32bde34
# --instance-type         t3.medium 
# --key-name              multicloud 
# --security-group-ids    sg-0f001cfd035ce11a8
# --subnet-id             subnet-19645b71

$ aws ec2 run-instances --image-id ami-0b9064170e32bde34 --count 1 --instance-type t3.medium --key-name multicloud --security-group-ids sg-0f001cfd035ce11a8 --subnet-id subnet-19645b71 --user-data file://rancher.sh --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=rancherserver}]' 'ResourceType=volume,Tags=[{Key=Name,Value=rancherserver}]' --profile fernando --region us-east-2

```


## 3 - Configuração do Rancher
Acessar o Rancher e configurar

https://3.134.108.244

## 4 - Configuração do Cluster Kubernetes.
Criar o cluster pelo Rancher e configurar.



## 5 - Deployment do cluster pela aws-cli

```sh
# --image-id ami-0b9064170e32bde34
# --count 3 
# --instance-type t3.large 
# --key-name multicloud 
# --security-group-ids sg-0f001cfd035ce11a8 
# --subnet-id subnet-f3621789
# --user-data file://k8s.sh

$ aws ec2 run-instances --image-id ami-0b9064170e32bde34 --count 3 --instance-type t3.large --key-name multicloud --security-group-ids sg-0f001cfd035ce11a8 --subnet-id subnet-f3621789 --user-data file://k8s.sh   --block-device-mapping "[ { \"DeviceName\": \"/dev/sda1\", \"Ebs\": { \"VolumeSize\": 70 } } ]" --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=k8s}]' 'ResourceType=volume,Tags=[{Key=Name,Value=k8s}]' --profile fernando --region us-east-2    
```

Instalar o kubectl 

https://kubernetes.io/docs/tasks/tools/


# Parte 2

## 6 - Configuração do Traefik

O Traefik é a aplicação que iremos usar como ingress. Ele irá ficar escutando pelas entradas de DNS que o cluster deve responder. Ele possui um dashboard de  monitoramento e com um resumo de todas as entradas que estão no cluster.
```sh
$ kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-rbac.yaml
$ kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-ds.yaml
$ kubectl --namespace=kube-system get pods
```
Agora iremos configurar o DNS pelo qual o Traefik irá responder. No arquivo ui.yml, localizar a url, e fazer a alteração. Após a alteração feita, iremos rodar o comando abaixo para aplicar o deployment no cluster.
```sh
$ kubectl apply -f traefik.yaml
```


## 7 - Configuração do Longhorn
Pelo console do Rancher


## 8 - Criação do certificado
Criar certificado para nossos dominios:

 *.devops-ninja.ml


```sh
*.losangelesops.ml
> openssl req -new -x509 -keyout cert.pem -out cert.pem -days 50000 -nodes
Country Name (2 letter code) [AU]:DE
State or Province Name (full name) [Some-State]:Germany
Locality Name (eg, city) []:nameOfYourCity
Organization Name (eg, company) [Internet Widgits Pty Ltd]:nameOfYourCompany
Organizational Unit Name (eg, section) []:nameOfYourDivision
Common Name (eg, YOUR name) []:*.example.com
Email Address []:webmaster@example.com
```

arn:aws:acm:us-east-2:646025261134:certificate/3e239411-ad50-4062-b1d7-83a4f8d40cf0


## 9 - Configuração do ELB


```sh
# LOAD BALANCER

# !! ESPECIFICAR O SECURITY GROUPS DO LOAD BALANCER

# --subnets subnet-19645b71 subnet-f3621789

# --security-group-ids sg-0f001cfd035ce11a8
# --subnet-id             

$ aws elbv2 create-load-balancer --name multicloud --type application --subnets subnet-19645b71 subnet-f3621789 --profile fernando --region us-east-2
#	 "LoadBalancerArn": "arn:aws:elasticloadbalancing:us-east-2:646025261134:loadbalancer/app/multicloud/8406988d0e14e2c6"

# --vpc-id vpc-e6afbb8e

$ aws elbv2 create-target-group --name multicloud --protocol HTTP --port 80 --vpc-id vpc-e6afbb8e --health-check-port 8080 --health-check-path /api/providers --profile fernando --region us-east-2
#	 "TargetGroupArn": "arn:aws:elasticloadbalancing:us-east-2:646025261134:targetgroup/multicloud/44e2b9527d4b9367",
	
	
# REGISTRAR OS TARGETS  
$ aws elbv2 register-targets --target-group-arn arn:aws:elasticloadbalancing:us-east-2:646025261134:targetgroup/multicloud/44e2b9527d4b9367 --targets Id=i-057f91f183a2b2f64 Id=i-0e3981d33b611f36e Id=i-0ba4e1e7a90b8f5e6 --profile fernando --region us-east-2


i-057f91f183a2b2f64
i-0e3981d33b611f36e
i-0ba4e1e7a90b8f5e6


# ARN DO Certificado - arn:aws:acm:us-east-2:646025261134:certificate/3e239411-ad50-4062-b1d7-83a4f8d40cf0
# HTTPS - CRIADO PRIMEIRO
$ aws elbv2 create-listener \
    --load-balancer-arn arn:aws:elasticloadbalancing:us-east-2:646025261134:loadbalancer/app/multicloud/8406988d0e14e2c6 \
    --protocol HTTPS \
    --port 443 \
    --certificates CertificateArn=arn:aws:acm:us-east-2:646025261134:certificate/3e239411-ad50-4062-b1d7-83a4f8d40cf0   \
    --ssl-policy ELBSecurityPolicy-2016-08 --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-2:646025261134:targetgroup/multicloud/44e2b9527d4b9367 --profile fernando --region us-east-2
#  "ListenerArn": "arn:aws:elasticloadbalancing:us-east-2:646025261134:listener/app/multicloud/8406988d0e14e2c6/276a83311350c73c"


$ aws elbv2 describe-target-health --target-group-arn targetgroup-arn

# DESCRIBE NO LISTENER
$ aws elbv2 describe-listeners --listener-arns arn:aws:elasticloadbalancing:us-east-1:984102645395:listener/app/multicloud/0c7e036793bff35e/a7386cf3e0dc3c0e


```


## 10 - Configuração do Route 53
Pelo console da AWS



