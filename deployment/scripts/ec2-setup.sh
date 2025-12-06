#!/bin/bash

###############################################################################
# EC2 Initial Setup Script
# EC2 인스턴스 초기 설정을 자동화합니다.
# SSH로 EC2에 접속한 후 이 스크립트를 실행하세요.
###############################################################################

set -e

echo "🚀 EC2 인스턴스 초기 설정을 시작합니다..."

# OS 감지
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ OS를 감지할 수 없습니다."
    exit 1
fi

echo "📋 감지된 OS: $OS"

###############################################################################
# 1. 시스템 업데이트
###############################################################################
echo ""
echo "1️⃣  시스템 업데이트 중..."

if [ "$OS" = "amzn" ] || [ "$OS" = "rhel" ]; then
    sudo dnf update -y
elif [ "$OS" = "ubuntu" ]; then
    sudo apt-get update && sudo apt-get upgrade -y
fi

echo "✅ 시스템 업데이트 완료"

###############################################################################
# 2. Java 17 설치
###############################################################################
echo ""
echo "2️⃣  Java 17 설치 중..."

if [ "$OS" = "amzn" ] || [ "$OS" = "rhel" ]; then
    sudo dnf install java-17-amazon-corretto-devel -y
elif [ "$OS" = "ubuntu" ]; then
    sudo apt-get install openjdk-17-jdk -y
fi

java -version
echo "✅ Java 17 설치 완료"

###############################################################################
# 3. MySQL 클라이언트 설치
###############################################################################
echo ""
echo "3️⃣  MySQL 클라이언트 설치 중..."

if [ "$OS" = "amzn" ] || [ "$OS" = "rhel" ]; then
    sudo dnf install mariadb105 -y
elif [ "$OS" = "ubuntu" ]; then
    sudo apt-get install mysql-client -y
fi

echo "✅ MySQL 클라이언트 설치 완료"

###############################################################################
# 4. Nginx 설치
###############################################################################
echo ""
echo "4️⃣  Nginx 설치 중..."

if [ "$OS" = "amzn" ] || [ "$OS" = "rhel" ]; then
    sudo dnf install nginx -y
elif [ "$OS" = "ubuntu" ]; then
    sudo apt-get install nginx -y
fi

# Nginx 시작 및 부팅시 자동 시작
sudo systemctl start nginx
sudo systemctl enable nginx

echo "✅ Nginx 설치 및 시작 완료"

###############################################################################
# 5. 애플리케이션 디렉토리 생성
###############################################################################
echo ""
echo "5️⃣  애플리케이션 디렉토리 생성 중..."

# 디렉토리 생성
sudo mkdir -p /opt/trading-app
sudo mkdir -p /opt/trading-app/backups
sudo mkdir -p /var/log/trading-app

# 사용자 권한 부여
if [ "$OS" = "amzn" ] || [ "$OS" = "rhel" ]; then
    sudo chown -R ec2-user:ec2-user /opt/trading-app
    sudo chown -R ec2-user:ec2-user /var/log/trading-app
elif [ "$OS" = "ubuntu" ]; then
    sudo chown -R ubuntu:ubuntu /opt/trading-app
    sudo chown -R ubuntu:ubuntu /var/log/trading-app
fi

echo "✅ 디렉토리 생성 완료"

###############################################################################
# 6. 유용한 도구 설치
###############################################################################
echo ""
echo "6️⃣  추가 도구 설치 중..."

if [ "$OS" = "amzn" ] || [ "$OS" = "rhel" ]; then
    sudo dnf install git wget curl htop -y
elif [ "$OS" = "ubuntu" ]; then
    sudo apt-get install git wget curl htop -y
fi

echo "✅ 추가 도구 설치 완료"

###############################################################################
# 7. 방화벽 설정 (선택)
###############################################################################
echo ""
echo "7️⃣  방화벽 설정은 AWS 보안 그룹에서 관리합니다."
echo "EC2 보안 그룹에서 다음 포트를 열어주세요:"
echo "  - 22 (SSH)"
echo "  - 80 (HTTP)"
echo "  - 443 (HTTPS)"

###############################################################################
# 완료
###############################################################################
echo ""
echo "🎉 EC2 초기 설정이 완료되었습니다!"
echo ""
echo "다음 단계:"
echo "1. Nginx 설정 파일 업로드 및 설정"
echo "2. Systemd 서비스 파일 설정"
echo "3. application-prod.properties 파일 생성"
echo "4. JAR 파일 업로드 및 배포"
echo ""
echo "자세한 내용은 AWS_DEPLOYMENT_GUIDE.md를 참고하세요."
