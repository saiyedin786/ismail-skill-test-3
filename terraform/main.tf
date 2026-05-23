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