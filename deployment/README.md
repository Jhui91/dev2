# Deployment Files

이 디렉토리는 AWS 배포에 필요한 모든 설정 파일과 스크립트를 포함합니다.

## 📁 디렉토리 구조

```
deployment/
├── config/                                    # 설정 파일
│   ├── application-prod.properties.template  # Spring Boot 프로덕션 설정 템플릿
│   └── nginx-trading-app.conf                # Nginx 설정 파일
├── scripts/                                   # 배포 스크립트
│   ├── ec2-setup.sh                          # EC2 초기 설정 스크립트
│   └── rollback.sh                           # 롤백 스크립트
├── systemd/                                   # Systemd 서비스 파일
│   └── trading-app.service                   # Spring Boot 서비스 파일
└── README.md                                  # 본 파일
```

## 🚀 빠른 시작

### 1. EC2 초기 설정

EC2 인스턴스에 처음 접속했을 때:

```bash
# 1. 이 파일을 EC2로 전송
scp -i <키파일> deployment/scripts/ec2-setup.sh ec2-user@<EC2-IP>:~/

# 2. EC2에 SSH 접속
ssh -i <키파일> ec2-user@<EC2-IP>

# 3. 스크립트 실행
chmod +x ec2-setup.sh
./ec2-setup.sh
```

### 2. 설정 파일 업로드

```bash
# Systemd 서비스 파일
scp -i <키파일> deployment/systemd/trading-app.service \
    ec2-user@<EC2-IP>:~/

# EC2에서
ssh -i <키파일> ec2-user@<EC2-IP>
sudo mv ~/trading-app.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable trading-app

# Nginx 설정
scp -i <키파일> deployment/config/nginx-trading-app.conf \
    ec2-user@<EC2-IP>:~/

# EC2에서
ssh -i <키파일> ec2-user@<EC2-IP>
sudo mv ~/nginx-trading-app.conf /etc/nginx/conf.d/
sudo nginx -t
sudo systemctl restart nginx

# Spring Boot 설정
# 1. 템플릿 복사
cp deployment/config/application-prod.properties.template \
   deployment/config/application-prod.properties

# 2. 실제 값으로 편집
nano deployment/config/application-prod.properties

# 3. EC2로 전송
scp -i <키파일> deployment/config/application-prod.properties \
    ec2-user@<EC2-IP>:/opt/trading-app/
```

### 3. 애플리케이션 배포

프로젝트 루트에서:

```bash
# 1. deploy.sh 수정 (EC2_HOST, KEY_PATH 등)
nano deploy.sh

# 2. 배포 실행
./deploy.sh
```

## 📋 파일별 설명

### config/application-prod.properties.template

Spring Boot 프로덕션 환경 설정 템플릿입니다.

**사용 방법:**
1. 파일을 `application-prod.properties`로 복사
2. `< >` 표시된 부분을 실제 값으로 교체
   - RDS 엔드포인트
   - 데이터베이스 사용자명/비밀번호
   - JWT Secret Key
   - OAuth2 클라이언트 정보
3. EC2의 `/opt/trading-app/` 디렉토리에 업로드

**보안 주의:**
- 절대 Git에 커밋하지 마세요!
- EC2에서만 사용하세요

### config/nginx-trading-app.conf

Nginx 리버스 프록시 설정입니다.

**주요 기능:**
- Spring Boot 애플리케이션으로 트래픽 전달
- 정적 파일 캐싱
- WebSocket 지원
- HTTPS 설정 (Let's Encrypt)

**설치 위치:** `/etc/nginx/conf.d/nginx-trading-app.conf`

### systemd/trading-app.service

Spring Boot 애플리케이션을 시스템 서비스로 등록하는 파일입니다.

**주요 기능:**
- 애플리케이션 자동 시작 (부팅시)
- 장애 시 자동 재시작
- 로그 관리

**설치 위치:** `/etc/systemd/system/trading-app.service`

**사용 명령어:**
```bash
sudo systemctl start trading-app      # 시작
sudo systemctl stop trading-app       # 중지
sudo systemctl restart trading-app    # 재시작
sudo systemctl status trading-app     # 상태 확인
sudo journalctl -u trading-app -f     # 로그 확인
```

### scripts/ec2-setup.sh

EC2 인스턴스 초기 설정을 자동화하는 스크립트입니다.

**수행 작업:**
- 시스템 업데이트
- Java 17 설치
- MySQL 클라이언트 설치
- Nginx 설치
- 필요한 디렉토리 생성
- 추가 도구 설치 (git, wget, curl, htop)

**사용 시기:** EC2 인스턴스를 처음 생성한 후 한 번만 실행

### scripts/rollback.sh

이전 버전으로 롤백하는 스크립트입니다.

**사용 방법:**
```bash
# EC2에서 실행
cd /opt/trading-app
./rollback.sh
```

**작동 방식:**
1. 백업 디렉토리에서 가장 최근 JAR 파일 검색
2. 현재 JAR 파일을 임시 백업
3. 이전 버전으로 복원
4. 서비스 재시작
5. 실패 시 자동으로 임시 백업에서 복원

## 🔄 배포 프로세스

### 전체 프로세스

```
로컬                          EC2
  │                            │
  ├─ 1. 빌드                   │
  │  (./gradlew build)         │
  │                            │
  ├─ 2. JAR 전송 ────────────> │
  │                            │
  │                            ├─ 3. 현재 JAR 백업
  │                            │
  │                            ├─ 4. 새 JAR 배치
  │                            │
  │                            ├─ 5. 서비스 재시작
  │                            │
  │                            └─ 6. 헬스 체크
  │                                 │
  └─ 7. 배포 완료 <─────────────────┘
```

### 배포 명령어

```bash
# 프로젝트 루트에서
./deploy.sh
```

### 수동 배포

자동 스크립트를 사용하지 않을 경우:

```bash
# 1. 로컬에서 빌드
./gradlew clean build -x test

# 2. EC2로 전송
scp -i <키파일> build/libs/trading-0.0.1-SNAPSHOT.jar \
    ec2-user@<EC2-IP>:/opt/trading-app/app.jar

# 3. EC2에서 재시작
ssh -i <키파일> ec2-user@<EC2-IP> \
    'sudo systemctl restart trading-app'

# 4. 로그 확인
ssh -i <키파일> ec2-user@<EC2-IP> \
    'sudo journalctl -u trading-app -f'
```

## 🔐 보안 체크리스트

배포 전 확인사항:

- [ ] `application-prod.properties`가 Git에 커밋되지 않았는지 확인
- [ ] JWT Secret Key가 강력한지 확인 (최소 256비트)
- [ ] RDS 보안 그룹이 EC2에서만 접근 가능하도록 설정
- [ ] EC2 보안 그룹에서 불필요한 포트 차단
- [ ] SSH 키 파일 권한이 400인지 확인 (`chmod 400`)
- [ ] Nginx에서 8080 포트 직접 접근 차단
- [ ] OAuth2 리다이렉트 URI가 정확한지 확인
- [ ] HTTPS 설정 (Let's Encrypt)

## 🛠 문제 해결

### 서비스가 시작되지 않을 때

```bash
# 로그 확인
sudo journalctl -u trading-app -n 100 --no-pager

# 설정 파일 확인
cat /opt/trading-app/application-prod.properties

# Java 프로세스 확인
ps aux | grep java

# 포트 사용 확인
sudo netstat -tlnp | grep 8080
```

### Nginx 502 에러

```bash
# Spring Boot 상태 확인
sudo systemctl status trading-app

# Nginx 에러 로그
sudo tail -f /var/log/nginx/trading-app-error.log

# 로컬 접근 테스트
curl http://localhost:8080
```

### 롤백이 필요한 경우

```bash
# EC2에 접속
ssh -i <키파일> ec2-user@<EC2-IP>

# 롤백 실행
cd /opt/trading-app
./rollback.sh

# 또는 특정 백업으로 복원
cp backups/<특정-백업-파일>.jar app.jar
sudo systemctl restart trading-app
```

## 📚 추가 리소스

- **상위 가이드:** [../AWS_DEPLOYMENT_GUIDE.md](../AWS_DEPLOYMENT_GUIDE.md)
- **프로젝트 문서:** [../README.md](../README.md)
- **AI 가이드:** [../CLAUDE.md](../CLAUDE.md)

---

**문의사항이나 문제가 있으면 프로젝트 관리자에게 연락하세요.**
