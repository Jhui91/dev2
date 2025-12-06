# AWS 배포 가이드 - 중고차 거래 플랫폼

이 가이드는 Spring Boot 애플리케이션을 AWS에 배포하는 전체 과정을 단계별로 설명합니다.

## 📋 목차

1. [배포 아키텍처](#-배포-아키텍처)
2. [사전 준비](#-사전-준비)
3. [1단계: AWS RDS MySQL 설정](#1단계-aws-rds-mysql-설정)
4. [2단계: EC2 인스턴스 생성](#2단계-ec2-인스턴스-생성)
5. [3단계: EC2 환경 설정](#3단계-ec2-환경-설정)
6. [4단계: 애플리케이션 배포](#4단계-애플리케이션-배포)
7. [5단계: 서비스 자동 시작 설정](#5단계-서비스-자동-시작-설정)
8. [6단계: 보안 그룹 설정](#6단계-보안-그룹-설정)
9. [7단계: S3 이미지 저장소 설정](#7단계-s3-이미지-저장소-설정-선택)
10. [8단계: 도메인 및 HTTPS 설정](#8단계-도메인-및-https-설정-선택)
11. [배포 자동화 스크립트](#-배포-자동화-스크립트)
12. [문제 해결](#-문제-해결)

---

## 🏗 배포 아키텍처

```
인터넷
  ↓
[Route 53 (도메인)]
  ↓
[Application Load Balancer] (선택)
  ↓
[EC2 인스턴스]
  ├─ Java 17
  ├─ Spring Boot App
  └─ Nginx (리버스 프록시)
  ↓
[RDS MySQL 8.0]

[S3] ← 이미지 저장
```

### 예상 비용 (월)
- **EC2 t3.small**: ~$15
- **RDS db.t3.micro**: ~$15
- **S3 + 데이터 전송**: ~$5
- **총 예상**: ~$35/월 (기본 설정)

---

## 🎯 사전 준비

### 1. AWS 계정
- AWS 계정 생성: https://aws.amazon.com/ko/
- 결제 정보 등록 (신용카드)
- IAM 사용자 생성 (루트 계정 직접 사용 금지)

### 2. 로컬 환경
```bash
# AWS CLI 설치 (Mac)
brew install awscli

# AWS CLI 설치 (Ubuntu/Debian)
sudo apt-get install awscli

# AWS CLI 설치 (Windows)
# https://aws.amazon.com/cli/ 에서 다운로드

# AWS CLI 설정
aws configure
# AWS Access Key ID: (IAM 사용자 키)
# AWS Secret Access Key: (IAM 사용자 시크릿)
# Default region name: ap-northeast-2 (서울 리전)
# Default output format: json
```

### 3. 필요한 정보 준비
- [ ] DB 사용자명 및 비밀번호 (최소 8자)
- [ ] JWT Secret Key (최소 256비트)
- [ ] OAuth2 클라이언트 정보 (Google, Kakao, Naver)
- [ ] SSH 키페어 이름

---

## 1단계: AWS RDS MySQL 설정

### 1.1 RDS 인스턴스 생성

**AWS Console → RDS → 데이터베이스 생성**

1. **데이터베이스 생성 방식**: 표준 생성
2. **엔진 옵션**: MySQL 8.0
3. **템플릿**: 프리 티어 (또는 개발/테스트)
4. **설정**:
   - DB 인스턴스 식별자: `trading-db`
   - 마스터 사용자 이름: `admin`
   - 마스터 암호: `강력한비밀번호` (기록해두세요!)

5. **인스턴스 구성**:
   - DB 인스턴스 클래스: `db.t3.micro` (프리티어)
   - 스토리지: 20GB (기본값)
   - 스토리지 자동 조정: 활성화

6. **연결**:
   - 퍼블릭 액세스: 예 (나중에 보안 그룹으로 제한)
   - VPC: 기본 VPC
   - 보안 그룹: 새로 생성 (`trading-db-sg`)

7. **추가 구성**:
   - 초기 데이터베이스 이름: `trading_db`
   - 파라미터 그룹: default.mysql8.0
   - 백업 보존 기간: 7일
   - 자동 백업 시간대: 새벽 시간대 선택

8. **생성** 클릭 (5-10분 소요)

### 1.2 RDS 엔드포인트 확인

생성 완료 후:
```
RDS → 데이터베이스 → trading-db → 연결 & 보안
```

**엔드포인트 복사** (예시):
```
trading-db.c1a2b3c4d5e6.ap-northeast-2.rds.amazonaws.com:3306
```

### 1.3 보안 그룹 설정

```
EC2 → 보안 그룹 → trading-db-sg → 인바운드 규칙 편집
```

| 유형 | 프로토콜 | 포트 | 소스 |
|------|----------|------|------|
| MySQL/Aurora | TCP | 3306 | 내 IP (임시) |
| MySQL/Aurora | TCP | 3306 | EC2 보안 그룹 (나중에 추가) |

### 1.4 데이터베이스 연결 테스트 (로컬)

```bash
# MySQL 클라이언트 설치 (Mac)
brew install mysql-client

# 연결 테스트
mysql -h trading-db.c1a2b3c4d5e6.ap-northeast-2.rds.amazonaws.com \
      -u admin \
      -p \
      trading_db

# 비밀번호 입력 후 접속 확인
mysql> SHOW DATABASES;
mysql> EXIT;
```

---

## 2단계: EC2 인스턴스 생성

### 2.1 EC2 인스턴스 시작

**AWS Console → EC2 → 인스턴스 시작**

1. **이름**: `trading-app-server`

2. **애플리케이션 및 OS 이미지**:
   - Amazon Linux 2023 (또는 Ubuntu 22.04 LTS)
   - 아키텍처: 64비트 (x86)

3. **인스턴스 유형**:
   - `t3.small` (2 vCPU, 2GB RAM) - 권장
   - 또는 `t3.micro` (1 vCPU, 1GB RAM) - 프리티어

4. **키 페어**:
   - 새 키 페어 생성: `trading-app-key`
   - 키 페어 유형: RSA
   - 프라이빗 키 파일 형식: .pem
   - **다운로드 후 안전한 곳에 보관!**

5. **네트워크 설정**:
   - VPC: 기본 VPC
   - 서브넷: 기본
   - 퍼블릭 IP 자동 할당: 활성화
   - 보안 그룹 생성: `trading-app-sg`
     - SSH (22): 내 IP
     - HTTP (80): 0.0.0.0/0
     - HTTPS (443): 0.0.0.0/0
     - Custom TCP (8080): 0.0.0.0/0 (임시, 나중에 제거)

6. **스토리지 구성**:
   - 8GB → 16GB로 변경 (권장)
   - 볼륨 유형: gp3

7. **고급 세부 정보** (선택):
   - 종료 방지: 활성화 (실수로 삭제 방지)

8. **인스턴스 시작** 클릭

### 2.2 Elastic IP 할당 (선택, 권장)

고정 IP 주소를 위해 Elastic IP 사용:

```
EC2 → 네트워크 및 보안 → Elastic IP → Elastic IP 주소 할당
→ 할당 → 작업 → Elastic IP 주소 연결
→ 인스턴스: trading-app-server 선택 → 연결
```

### 2.3 SSH 키 파일 권한 설정

```bash
# 다운로드한 키 파일 권한 변경
chmod 400 ~/Downloads/trading-app-key.pem

# 안전한 위치로 이동
mkdir -p ~/.ssh/aws-keys
mv ~/Downloads/trading-app-key.pem ~/.ssh/aws-keys/

# SSH 접속 테스트
ssh -i ~/.ssh/aws-keys/trading-app-key.pem ec2-user@<EC2-퍼블릭-IP>
# 또는 Ubuntu 사용시
ssh -i ~/.ssh/aws-keys/trading-app-key.pem ubuntu@<EC2-퍼블릭-IP>
```

---

## 3단계: EC2 환경 설정

EC2 인스턴스에 SSH 접속 후:

### 3.1 시스템 업데이트

```bash
# Amazon Linux 2023
sudo dnf update -y

# Ubuntu
# sudo apt-get update && sudo apt-get upgrade -y
```

### 3.2 Java 17 설치

```bash
# Amazon Linux 2023
sudo dnf install java-17-amazon-corretto-devel -y

# Ubuntu
# sudo apt-get install openjdk-17-jdk -y

# 설치 확인
java -version
# 출력: openjdk version "17.x.x"
```

### 3.3 MySQL 클라이언트 설치

```bash
# Amazon Linux 2023
sudo dnf install mariadb105 -y

# Ubuntu
# sudo apt-get install mysql-client -y

# RDS 연결 테스트
mysql -h <RDS-엔드포인트> -u admin -p trading_db
```

### 3.4 Nginx 설치 (리버스 프록시)

```bash
# Amazon Linux 2023
sudo dnf install nginx -y

# Ubuntu
# sudo apt-get install nginx -y

# Nginx 시작 및 부팅시 자동 시작
sudo systemctl start nginx
sudo systemctl enable nginx

# 상태 확인
sudo systemctl status nginx

# 브라우저에서 http://<EC2-퍼블릭-IP> 접속하여 Nginx 기본 페이지 확인
```

### 3.5 애플리케이션 디렉토리 생성

```bash
# 애플리케이션 디렉토리
sudo mkdir -p /opt/trading-app
sudo mkdir -p /opt/trading-app/logs
sudo mkdir -p /var/log/trading-app

# 사용자 권한 부여
sudo chown -R ec2-user:ec2-user /opt/trading-app
# Ubuntu: sudo chown -R ubuntu:ubuntu /opt/trading-app
```

---

## 4단계: 애플리케이션 배포

### 4.1 로컬에서 애플리케이션 빌드

```bash
# 프로젝트 루트 디렉토리에서
./gradlew clean build -x test

# 빌드 파일 확인
ls -lh build/libs/trading-0.0.1-SNAPSHOT.jar
```

### 4.2 EC2로 파일 전송

```bash
# SCP로 JAR 파일 전송
scp -i ~/.ssh/aws-keys/trading-app-key.pem \
    build/libs/trading-0.0.1-SNAPSHOT.jar \
    ec2-user@<EC2-퍼블릭-IP>:/opt/trading-app/app.jar

# 또는 rsync 사용 (더 빠름)
rsync -avz -e "ssh -i ~/.ssh/aws-keys/trading-app-key.pem" \
      build/libs/trading-0.0.1-SNAPSHOT.jar \
      ec2-user@<EC2-퍼블릭-IP>:/opt/trading-app/app.jar
```

### 4.3 환경 설정 파일 생성

EC2에서 `/opt/trading-app/application-prod.properties` 생성:

```bash
ssh -i ~/.ssh/aws-keys/trading-app-key.pem ec2-user@<EC2-퍼블릭-IP>

# 설정 파일 생성
cat > /opt/trading-app/application-prod.properties << 'EOF'
# Application
spring.application.name=UsedCarTrading

# Server
server.port=8080

# Database - RDS MySQL
spring.datasource.url=jdbc:mysql://<RDS-엔드포인트>:3306/trading_db?useSSL=true&requireSSL=false&serverTimezone=Asia/Seoul&characterEncoding=UTF-8
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
spring.datasource.username=admin
spring.datasource.password=<RDS-마스터-비밀번호>

# JPA / Hibernate
spring.jpa.database-platform=org.hibernate.dialect.MySQL8Dialect
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.format_sql=false
spring.jpa.properties.hibernate.jdbc.batch_size=20
spring.jpa.properties.hibernate.order_inserts=true
spring.jpa.properties.hibernate.order_updates=true

# Connection Pool
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=20000

# Logging
logging.level.org.hibernate.SQL=WARN
logging.level.com.usedcar.trading=INFO
logging.file.name=/var/log/trading-app/application.log
logging.file.max-size=10MB
logging.file.max-history=30

# JWT
jwt.secret=<256비트-이상의-강력한-시크릿-키-여기에-입력>
jwt.expiration=86400000

# OAuth2 - Google
spring.security.oauth2.client.registration.google.client-id=<구글-클라이언트-ID>
spring.security.oauth2.client.registration.google.client-secret=<구글-클라이언트-시크릿>
spring.security.oauth2.client.registration.google.scope=profile,email

# OAuth2 - Kakao
spring.security.oauth2.client.registration.kakao.client-id=<카카오-클라이언트-ID>
spring.security.oauth2.client.registration.kakao.client-secret=<카카오-클라이언트-시크릿>
spring.security.oauth2.client.registration.kakao.authorization-grant-type=authorization_code
spring.security.oauth2.client.registration.kakao.redirect-uri={baseUrl}/login/oauth2/code/kakao
spring.security.oauth2.client.registration.kakao.client-authentication-method=client_secret_post
spring.security.oauth2.client.registration.kakao.scope=profile_nickname,account_email

spring.security.oauth2.client.provider.kakao.authorization-uri=https://kauth.kakao.com/oauth/authorize
spring.security.oauth2.client.provider.kakao.token-uri=https://kauth.kakao.com/oauth/token
spring.security.oauth2.client.provider.kakao.user-info-uri=https://kapi.kakao.com/v2/user/me
spring.security.oauth2.client.provider.kakao.user-name-attribute=id

# File Upload (나중에 S3로 변경)
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=50MB

# Thymeleaf Cache (Production)
spring.thymeleaf.cache=true
EOF
```

**중요**: 위 파일에서 `< >` 부분을 실제 값으로 교체하세요!

### 4.4 애플리케이션 실행 테스트

```bash
# 직접 실행 테스트
cd /opt/trading-app
java -jar app.jar --spring.config.location=application-prod.properties

# 로그 확인 (다른 터미널)
tail -f /var/log/trading-app/application.log

# 브라우저에서 확인
# http://<EC2-퍼블릭-IP>:8080

# 정상 작동 확인 후 Ctrl+C로 종료
```

---

## 5단계: 서비스 자동 시작 설정

### 5.1 Systemd 서비스 파일 생성

```bash
sudo nano /etc/systemd/system/trading-app.service
```

다음 내용 입력:

```ini
[Unit]
Description=Used Car Trading Platform
After=syslog.target network.target

[Service]
Type=simple
User=ec2-user
Group=ec2-user
WorkingDirectory=/opt/trading-app
ExecStart=/usr/bin/java -jar \
    -Xms512m \
    -Xmx1024m \
    -XX:+UseG1GC \
    -Dspring.profiles.active=prod \
    -Dspring.config.location=/opt/trading-app/application-prod.properties \
    /opt/trading-app/app.jar

SuccessExitStatus=143
StandardOutput=journal
StandardError=journal
SyslogIdentifier=trading-app

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 5.2 서비스 활성화 및 시작

```bash
# 서비스 파일 리로드
sudo systemctl daemon-reload

# 서비스 시작
sudo systemctl start trading-app

# 상태 확인
sudo systemctl status trading-app

# 부팅시 자동 시작 설정
sudo systemctl enable trading-app

# 로그 확인
sudo journalctl -u trading-app -f

# 또는
tail -f /var/log/trading-app/application.log
```

### 5.3 서비스 관리 명령어

```bash
# 서비스 재시작
sudo systemctl restart trading-app

# 서비스 중지
sudo systemctl stop trading-app

# 최근 로그 100줄 보기
sudo journalctl -u trading-app -n 100

# 특정 시간 이후 로그
sudo journalctl -u trading-app --since "1 hour ago"
```

---

## 6단계: 보안 그룹 설정

### 6.1 RDS 보안 그룹 업데이트

```
EC2 → 보안 그룹 → trading-db-sg → 인바운드 규칙 편집
```

기존 "내 IP" 규칙 삭제 후:

| 유형 | 프로토콜 | 포트 | 소스 | 설명 |
|------|----------|------|------|------|
| MySQL/Aurora | TCP | 3306 | trading-app-sg | EC2에서만 접근 허용 |

### 6.2 EC2 보안 그룹 업데이트

```
EC2 → 보안 그룹 → trading-app-sg → 인바운드 규칙 편집
```

| 유형 | 프로토콜 | 포트 | 소스 | 설명 |
|------|----------|------|------|------|
| SSH | TCP | 22 | 내 IP | SSH 접속 |
| HTTP | TCP | 80 | 0.0.0.0/0 | 웹 접속 |
| HTTPS | TCP | 443 | 0.0.0.0/0 | HTTPS 접속 |
| Custom TCP | TCP | 8080 | 127.0.0.1/32 | 로컬에서만 (Nginx 경유) |

---

## 7단계: Nginx 리버스 프록시 설정

### 7.1 Nginx 설정 파일 생성

```bash
sudo nano /etc/nginx/conf.d/trading-app.conf
```

다음 내용 입력:

```nginx
upstream spring_boot {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    server_name <EC2-퍼블릭-IP-또는-도메인>;

    client_max_body_size 50M;

    # 정적 파일 캐싱
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf|svg)$ {
        proxy_pass http://spring_boot;
        proxy_cache_valid 200 30d;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Spring Boot 애플리케이션
    location / {
        proxy_pass http://spring_boot;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket 지원 (필요시)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # 타임아웃 설정
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # 로그
    access_log /var/log/nginx/trading-app-access.log;
    error_log /var/log/nginx/trading-app-error.log;
}
```

### 7.2 Nginx 설정 테스트 및 재시작

```bash
# 설정 파일 문법 검사
sudo nginx -t

# Nginx 재시작
sudo systemctl restart nginx

# 상태 확인
sudo systemctl status nginx
```

### 7.3 접속 확인

브라우저에서 `http://<EC2-퍼블릭-IP>` 접속 (포트 8080 없이)

---

## 8단계: S3 이미지 저장소 설정 (선택)

차량 이미지를 S3에 저장하려면:

### 8.1 S3 버킷 생성

```bash
# AWS CLI로 버킷 생성
aws s3 mb s3://trading-app-images-<고유한-이름> --region ap-northeast-2

# 또는 AWS Console에서:
# S3 → 버킷 만들기 → 이름: trading-app-images-xxx
# 리전: 아시아 태평양(서울) ap-northeast-2
# 퍼블릭 액세스 차단: 모두 해제 (또는 CloudFront 사용)
```

### 8.2 버킷 정책 설정

S3 → 버킷 → 권한 → 버킷 정책:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::trading-app-images-xxx/*"
        }
    ]
}
```

### 8.3 IAM 사용자 생성 및 권한 부여

```
IAM → 사용자 → 사용자 추가
- 사용자 이름: trading-app-s3-user
- 액세스 유형: 프로그래밍 방식 액세스
- 권한: AmazonS3FullAccess (또는 특정 버킷만 접근 가능한 커스텀 정책)
- 액세스 키 ID 및 시크릿 키 다운로드
```

### 8.4 Spring Boot 설정 추가

`build.gradle`에 의존성 추가:

```gradle
dependencies {
    // AWS S3
    implementation 'org.springframework.cloud:spring-cloud-starter-aws:2.2.6.RELEASE'
}
```

`application-prod.properties`에 설정 추가:

```properties
# AWS S3
cloud.aws.credentials.access-key=<액세스-키-ID>
cloud.aws.credentials.secret-key=<시크릿-액세스-키>
cloud.aws.region.static=ap-northeast-2
cloud.aws.stack.auto=false

# S3 버킷
cloud.aws.s3.bucket=trading-app-images-xxx
```

---

## 9단계: 도메인 및 HTTPS 설정 (선택)

### 9.1 도메인 연결 (Route 53)

도메인이 있는 경우:

```
Route 53 → 호스팅 영역 → 레코드 생성
- 레코드 이름: www (또는 비워두기)
- 레코드 유형: A
- 값: <EC2-Elastic-IP>
- TTL: 300
```

### 9.2 Let's Encrypt SSL 인증서 (무료)

EC2에서:

```bash
# Certbot 설치 (Amazon Linux 2023)
sudo dnf install certbot python3-certbot-nginx -y

# Ubuntu
# sudo apt-get install certbot python3-certbot-nginx -y

# SSL 인증서 발급 및 자동 설정
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# 이메일 입력
# 약관 동의: Y
# 이메일 수신: N
# Redirect HTTP to HTTPS: 2 (권장)

# 자동 갱신 테스트
sudo certbot renew --dry-run

# 자동 갱신은 systemd timer로 자동 설정됨
```

### 9.3 HTTPS 설정 확인

브라우저에서 `https://yourdomain.com` 접속하여 자물쇠 아이콘 확인

---

## 📜 배포 자동화 스크립트

프로젝트 루트에 `deploy.sh` 생성:

```bash
#!/bin/bash

# 설정
EC2_USER="ec2-user"
EC2_HOST="<EC2-퍼블릭-IP-또는-도메인>"
KEY_PATH="~/.ssh/aws-keys/trading-app-key.pem"
APP_DIR="/opt/trading-app"

echo "🔨 Building application..."
./gradlew clean build -x test

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "📦 Copying JAR file to EC2..."
scp -i $KEY_PATH \
    build/libs/trading-0.0.1-SNAPSHOT.jar \
    $EC2_USER@$EC2_HOST:$APP_DIR/app.jar

if [ $? -ne 0 ]; then
    echo "❌ File transfer failed!"
    exit 1
fi

echo "🔄 Restarting application..."
ssh -i $KEY_PATH $EC2_USER@$EC2_HOST << 'ENDSSH'
    sudo systemctl restart trading-app
    echo "⏳ Waiting for application to start..."
    sleep 10
    sudo systemctl status trading-app
ENDSSH

echo "✅ Deployment completed!"
echo "📊 Check logs: ssh -i $KEY_PATH $EC2_USER@$EC2_HOST 'sudo journalctl -u trading-app -f'"
```

실행 권한 부여 및 사용:

```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 🔧 문제 해결

### 애플리케이션이 시작되지 않는 경우

```bash
# 로그 확인
sudo journalctl -u trading-app -n 100 --no-pager

# Java 프로세스 확인
ps aux | grep java

# 포트 사용 확인
sudo netstat -tlnp | grep 8080

# 메모리 확인
free -h

# 디스크 확인
df -h
```

### 데이터베이스 연결 오류

```bash
# RDS 연결 테스트
mysql -h <RDS-엔드포인트> -u admin -p

# 보안 그룹 확인
# EC2에서 RDS로 접근 가능한지 확인

# application-prod.properties 확인
cat /opt/trading-app/application-prod.properties | grep datasource
```

### Out of Memory 오류

`/etc/systemd/system/trading-app.service` 수정:

```ini
ExecStart=/usr/bin/java -jar \
    -Xms256m \
    -Xmx768m \
    ...
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart trading-app
```

### Nginx 502 Bad Gateway

```bash
# Spring Boot 애플리케이션 상태 확인
sudo systemctl status trading-app

# 로컬에서 직접 접근 테스트
curl http://localhost:8080

# Nginx 에러 로그
sudo tail -f /var/log/nginx/trading-app-error.log
```

### SSL 인증서 갱신 오류

```bash
# 수동 갱신
sudo certbot renew

# 갱신 로그 확인
sudo journalctl -u certbot.timer
```

---

## 📊 모니터링 및 유지보수

### 로그 확인

```bash
# 애플리케이션 로그
tail -f /var/log/trading-app/application.log

# Systemd 로그
sudo journalctl -u trading-app -f

# Nginx 액세스 로그
sudo tail -f /var/log/nginx/trading-app-access.log

# Nginx 에러 로그
sudo tail -f /var/log/nginx/trading-app-error.log
```

### 성능 모니터링

```bash
# CPU 및 메모리 사용량
top

# 디스크 사용량
df -h

# 네트워크 연결
sudo netstat -tlnp

# Java 프로세스 메모리
jcmd <PID> VM.native_memory summary
```

### 데이터베이스 백업

```bash
# RDS 자동 백업 설정 확인
# AWS Console → RDS → trading-db → 유지 관리 및 백업

# 수동 스냅샷 생성
aws rds create-db-snapshot \
    --db-instance-identifier trading-db \
    --db-snapshot-identifier trading-db-snapshot-$(date +%Y%m%d)
```

---

## 🎯 체크리스트

배포 전 확인사항:

- [ ] AWS 계정 및 결제 정보 설정
- [ ] RDS MySQL 인스턴스 생성 및 엔드포인트 확인
- [ ] EC2 인스턴스 생성 및 SSH 접속 가능
- [ ] Java 17, Nginx 설치
- [ ] 애플리케이션 빌드 성공
- [ ] application-prod.properties 설정 완료
- [ ] Systemd 서비스 등록 및 자동 시작 설정
- [ ] Nginx 리버스 프록시 설정
- [ ] 보안 그룹 규칙 적용
- [ ] 브라우저에서 접속 확인
- [ ] OAuth2 리다이렉트 URI 등록
- [ ] (선택) S3 버킷 생성 및 설정
- [ ] (선택) 도메인 연결
- [ ] (선택) HTTPS 인증서 설정

---

## 📞 추가 도움말

- AWS 프리티어: https://aws.amazon.com/ko/free/
- AWS 문서: https://docs.aws.amazon.com/ko_kr/
- Spring Boot on AWS: https://spring.io/guides/gs/spring-boot-aws/

---

**마지막 업데이트**: 2025-12-06
**작성자**: AI Assistant
