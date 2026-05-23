
Make a folder named skill-test-3
Cd skill-test-3
Git clone https://github.com/AtharvaAI/E-CommerceStore.git
Cd E-CommerceStore

Step 1 : creation of Dockerfile and .env file for all services and frontend
Cd backend/cart-service
Create Dockerfile
FROM node:18
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 3001
CMD ["node", "server.js"]

Create .env file
PORT=3003
MONGODB_URI=mongodb://mongodb:27017/ecommerce_carts
MONGODB_URI=mongodb+srv://admin:password123@cluster0.xxxxx.mongodb.net/ecommerce_users?retryWrites=true&w=majority
PRODUCT_SERVICE_URL=http://product-service:3002

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/c109b2aa-ef28-4471-a6d1-b10665b37be8" />

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/52f80f87-4bec-45a8-9330-79f5d0079100" />

Cd ../order-service
Create Dockerfile
FROM node:18
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 3004
CMD ["node", "server.js"]

Create .env file
PORT=3004
MONGODB_URI=mongodb://mongodb:27017/ecommerce_orders
CART_SERVICE_URL=http://cart-service:3003
PRODUCT_SERVICE_URL=http://product-service:3002
USER_SERVICE_URL=http://user-service:3001

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/5e39ec9f-37b1-4970-9369-4b20e32242c7" />
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/6665d3a7-bb07-41d3-aac6-634ad0f38f9e" />

Cd ../product-service
Create Dockerfile
FROM node:18
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 3002
CMD ["node", "server.js"]

Create .env file
PORT=3002
MONGODB_URI=mongodb://mongodb:27017/ecommerce_products
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/587f9229-c697-4618-ab58-2c80d14655fb" />
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/9f8f8684-0c37-4f83-b2fb-4172115851e5" />


Cd ../user-service
Create Dockerfile
FROM node:18
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 3001
CMD ["node", "server.js"]

Create .env file
PORT=3001
MONGODB_URI=mongodb://mongodb:27017/ecommerce_users
JWT_SECRET=your-jwt-secret-key

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/489e3a08-c5af-4dd2-ba87-75978bb7d3c7" />
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/81cdbc76-fee6-4874-8066-9142203e819f" />


Cd ../../frontend
Create Dockerfile:
FROM node:18
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]

Create .env file
REACT_APP_USER_SERVICE_URL=http://13.127.117.182:3001
REACT_APP_PRODUCT_SERVICE_URL=http://13.127.117.182:3002
REACT_APP_CART_SERVICE_URL=http://13.127.117.182:3003
REACT_APP_ORDER_SERVICE_URL=13.127.117.182:3004
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/c0b20855-a7a8-4d84-9bfc-d32a45c84662" />
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/d6406c3b-9837-47b8-a668-76437088bff9" />


Step 2: Building docker images for all services
Created Dockerhub repository named saiyedin786/skill-test-3:tagname
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/226c54de-9091-4555-8fbf-880bd9bd20e8" />


docker build -t saiyedin786/skill-test-3:user-service .
docker push saiyedin786/skill-test-3:user-service

cart-service
docker build -t saiyedin786/skill-test-3:cart-service .
docker push saiyedin786/skill-test-3:cart-service

product-service
docker build -t saiyedin786/skill-test-3:product-service .
docker push saiyedin786/skill-test-3:product-service

order-service
docker build -t saiyedin786/skill-test-3:order-service .
docker push saiyedin786/skill-test-3:order-service

frontend
docker build -t saiyedin786/skill-test-3:frontend .
docker push saiyedin786/skill-test-3:frontend

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/14dce8d1-44ed-46d2-8fa5-2c9b57365d12" />

Step-3 terraform implementation:
Terraform.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.46.0"
    }
  }
}

Provider.tf
provider "aws" {
  region = "ap-south-1"
}




Outputs.tf
output "public_ip" {
  value = aws_instance.server.public_ip
}


Variables.tf

Main.tf
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}
resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.public.id
 route_table_id = aws_route_table.rt.id
}
resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 3000
    to_port     = 3004
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "ecommerce-keypair"
  public_key = file("ecommerce-keypair.pub")
}

resource "aws_instance" "server" {
  ami                    = "ami-07a00cf47dbbc844c"
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = aws_key_pair.deployer.key_name

  depends_on = [
    aws_internet_gateway.gw
  ]

  # 25 GB Storage
  root_block_device {
    volume_size = 25
    volume_type = "gp3"
    delete_on_termination = true
  }

 user_data = <<-EOF
#!/bin/bash

exec > /var/log/user-data.log 2>&1
set -x

# Update packages
apt-get update -y

# Install Docker + curl
apt-get install -y docker.io curl

# Start Docker
systemctl enable docker
systemctl start docker

sleep 20

# Add ubuntu user to docker group
usermod -aG docker ubuntu || true

# Create network
docker network create ecommerce-network || true

# Create Mongo volume
docker volume create mongodb-data

# Remove old containers
docker rm -f mongodb product-service user-service cart-service order-service frontend || true

# Pull images first
docker pull mongo
docker pull saiyedin786/skill-test-3:product-service
docker pull saiyedin786/skill-test-3:user-service
docker pull saiyedin786/skill-test-3:cart-service
docker pull saiyedin786/skill-test-3:order-service
docker pull saiyedin786/skill-test-3:frontend

# MongoDB
docker run -d \
  --restart always \
  --name mongodb \
  --network ecommerce-network \
  -p 27017:27017 \
  -v mongodb-data:/data/db \
  mongo

sleep 20

# Check MongoDB
docker ps
docker logs mongodb || true

# Product Service
docker run -d \
  --restart always \
  --name product-service \
  --network ecommerce-network \
  -p 3002:3002 \
  -e MONGO_URI=mongodb://mongodb:27017/products \
  saiyedin786/skill-test-3:product-service || true

# User Service
docker run -d \
  --restart always \
  --name user-service \
  --network ecommerce-network \
  -p 3001:3001 \
  -e MONGO_URI=mongodb://mongodb:27017/users \
  saiyedin786/skill-test-3:user-service || true

# Cart Service
docker run -d \
  --restart always \
  --name cart-service \
  --network ecommerce-network \
  -p 3003:3003 \
  saiyedin786/skill-test-3:cart-service || true

# Order Service
docker run -d \
  --restart always \
  --name order-service \
  --network ecommerce-network \
  -p 3004:3004 \
  saiyedin786/skill-test-3:order-service || true

sleep 30

# Get Public IP from EC2 Metadata
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
-H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)

PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
-s http://169.254.169.254/latest/meta-data/public-ipv4)

echo "PUBLIC IP = $PUBLIC_IP"

# Remove old frontend if exists
docker rm -f frontend || true

# Frontend
docker run -d \
  --restart always \
  --name frontend \
  --network ecommerce-network \
  -p 3000:3000 \
  -e HOST=0.0.0.0 \
  -e PORT=3000 \
  -e REACT_APP_USER_SERVICE_URL=http://$PUBLIC_IP:3001 \
  -e REACT_APP_PRODUCT_SERVICE_URL=http://$PUBLIC_IP:3002 \
  -e REACT_APP_CART_SERVICE_URL=http://$PUBLIC_IP:3003 \
  -e REACT_APP_ORDER_SERVICE_URL=http://$PUBLIC_IP:3004 \
  saiyedin786/skill-test-3:frontend

EOF
  tags = {
    Name = "ecommerce-server"
  }
}

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/ceee1b72-e956-4d68-88c7-c2c8fe4b9671" />
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/89c1c11c-77b6-41ca-9081-24cd8fbff42b" />

Command - Terraform init
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/c1d3e1a0-86a7-4121-9685-9ef50b38eebe" />


Terraform plan
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/8b3dd272-cfaf-42db-bfba-fc5997f2aff8" />

Terraform apply
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/8afa0c98-bf6d-4774-ba1f-8340810a0ac8" />

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/9bca533c-7ae9-43c4-b582-ba7f3f33bd2a" />

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/f1eb2d81-df2f-4c03-844a-d1579696b6df" />


<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/87df3046-73b8-431e-9927-67e80d223a30" />

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/8784fc5d-3765-400e-9d2e-e12b868bc560" />

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/fd2329fb-8e2a-4217-8bef-04a9158d0621" />

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/0429b4c6-60a1-401c-aab5-927c8945b83f" />

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/cebfed63-491c-433a-931f-56e51ec64a5c" />


<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/659070fb-202b-4327-bbff-d36f519a8fc5" />


Terraform destroy:
<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/9eda112c-42dd-4369-a0e9-f4d550fe25d5" />

<img width="975" height="548" alt="image" src="https://github.com/user-attachments/assets/763ab507-64a5-4dd8-9bfb-7c3c5b9669e4" />

















