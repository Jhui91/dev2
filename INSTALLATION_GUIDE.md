# 설치 및 실행 가이드

> **중고차 거래 플랫폼 - 컴파일 및 설치 매뉴얼**
>
> 버전: 1.0.0
> 최종 업데이트: 2025-12-06

이 문서는 프로젝트를 로컬 개발 환경 또는 프로덕션 환경에서 설치하고 실행하는 방법을 단계별로 설명합니다.

---

## 📋 목차

1. [시스템 요구사항](#1-시스템-요구사항)
2. [개발 환경 설정](#2-개발-환경-설정)
3. [프로젝트 다운로드](#3-프로젝트-다운로드)
4. [데이터베이스 설정](#4-데이터베이스-설정)
5. [환경 설정 파일 구성](#5-환경-설정-파일-구성)
6. [컴파일 (빌드)](#6-컴파일-빌드)
7. [실행 방법](#7-실행-방법)
8. [테스트 실행](#8-테스트-실행)
9. [IDE 설정 (선택)](#9-ide-설정-선택)
10. [문제 해결](#10-문제-해결)
11. [부록](#11-부록)

---

## 1. 시스템 요구사항

### 1.1 필수 요구사항

#### 하드웨어
```
최소 사양:
- CPU: 2 Core 이상
- RAM: 4GB 이상
- 디스크: 10GB 이상 여유 공간

권장 사양:
- CPU: 4 Core 이상
- RAM: 8GB 이상
- 디스크: 20GB 이상 SSD
```

#### 소프트웨어

| 구분 | 필수 버전 | 권장 버전 | 다운로드 |
|------|-----------|-----------|----------|
| **Java JDK** | 17 이상 | 17 LTS | https://adoptium.net/ |
| **Gradle** | 8.0 이상 | 8.5+ (또는 Wrapper 사용) | https://gradle.org/ |
| **MySQL** | 8.0 이상 | 8.0.33+ | https://dev.mysql.com/downloads/ |
| **Git** | 2.20 이상 | 최신 버전 | https://git-scm.com/ |

#### 선택 사항

| 항목 | 용도 | 다운로드 |
|------|------|----------|
| IntelliJ IDEA | IDE | https://www.jetbrains.com/idea/ |
| Eclipse | IDE | https://www.eclipse.org/ |
| DBeaver | DB 관리 도구 | https://dbeaver.io/ |
| Postman | API 테스트 | https://www.postman.com/ |

### 1.2 운영체제 지원

| OS | 지원 버전 | 비고 |
|-------|------------|------|
| **Windows** | Windows 10/11 | WSL2 사용 권장 |
| **macOS** | 10.15 (Catalina) 이상 | M1/M2 지원 |
| **Linux** | Ubuntu 20.04+, CentOS 8+ | 권장 |

---

## 2. 개발 환경 설정

### 2.1 Java 17 설치

#### Windows

**방법 1: Chocolatey 사용**
```powershell
# Chocolatey가 설치되어 있다면
choco install temurin17
```

**방법 2: 수동 설치**
1. https://adoptium.net/ 접속
2. **Temurin 17 (LTS)** 다운로드
3. 설치 프로그램 실행
4. 환경 변수 자동 설정 확인

**설치 확인:**
```powershell
java -version
# 출력: openjdk version "17.0.x"

javac -version
# 출력: javac 17.0.x
```

#### macOS

**방법 1: Homebrew 사용 (권장)**
```bash
# Homebrew 설치 (미설치 시)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Java 17 설치
brew install openjdk@17

# 심볼릭 링크 생성
sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk \
     /Library/Java/JavaVirtualMachines/openjdk-17.jdk

# 환경 변수 설정 (~/.zshrc 또는 ~/.bash_profile)
echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**설치 확인:**
```bash
java -version
javac -version
```

#### Linux (Ubuntu/Debian)

```bash
# 패키지 목록 업데이트
sudo apt update

# OpenJDK 17 설치
sudo apt install openjdk-17-jdk -y

# 기본 Java 버전 설정 (여러 버전 설치된 경우)
sudo update-alternatives --config java

# 설치 확인
java -version
javac -version
```

#### Linux (CentOS/RHEL/Amazon Linux)

```bash
# Amazon Corretto 17 설치
sudo dnf install java-17-amazon-corretto-devel -y

# 설치 확인
java -version
javac -version
```

### 2.2 Gradle 설치 (선택)

프로젝트에 **Gradle Wrapper**가 포함되어 있어 별도 설치는 선택사항입니다.

#### Gradle Wrapper 사용 (권장)

```bash
# Windows
gradlew.bat --version

# macOS/Linux
./gradlew --version
```

#### 시스템 전역 Gradle 설치

**Windows (Chocolatey):**
```powershell
choco install gradle
```

**macOS (Homebrew):**
```bash
brew install gradle
```

**Linux (SDKMAN!):**
```bash
# SDKMAN! 설치
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Gradle 설치
sdk install gradle
```

### 2.3 MySQL 설치

#### Windows

1. **MySQL Installer 다운로드**
   - https://dev.mysql.com/downloads/installer/

2. **설치 옵션 선택**
   - Custom 설치 선택
   - MySQL Server 8.0.x 선택
   - MySQL Workbench (선택)

3. **Root 비밀번호 설정**
   - 강력한 비밀번호 설정 (기록해두기!)

4. **서비스 시작**
   ```powershell
   # 서비스 시작
   net start MySQL80

   # 서비스 중지
   net stop MySQL80
   ```

#### macOS

```bash
# Homebrew로 설치
brew install mysql@8.0

# 서비스 시작
brew services start mysql@8.0

# MySQL 보안 설정
mysql_secure_installation
# - Root 비밀번호 설정
# - 익명 사용자 제거
# - 원격 root 로그인 비활성화
# - 테스트 데이터베이스 제거

# 접속 테스트
mysql -u root -p
```

#### Linux (Ubuntu/Debian)

```bash
# MySQL 설치
sudo apt update
sudo apt install mysql-server -y

# MySQL 서비스 시작
sudo systemctl start mysql
sudo systemctl enable mysql

# 보안 설정
sudo mysql_secure_installation

# 접속 테스트
sudo mysql -u root -p
```

### 2.4 Git 설치

#### Windows

```powershell
# Chocolatey 사용
choco install git

# 또는 https://git-scm.com/ 에서 다운로드
```

#### macOS

```bash
# Homebrew 사용
brew install git

# 또는 Xcode Command Line Tools
xcode-select --install
```

#### Linux

```bash
# Ubuntu/Debian
sudo apt install git -y

# CentOS/RHEL
sudo dnf install git -y
```

**Git 설정:**
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## 3. 프로젝트 다운로드

### 3.1 Git Clone

```bash
# 프로젝트 저장소 클론
git clone https://github.com/Jhui91/dev2.git

# 프로젝트 디렉토리로 이동
cd dev2

# 브랜치 확인
git branch -a

# 특정 브랜치로 체크아웃 (필요시)
# git checkout <branch-name>
```

### 3.2 디렉토리 구조 확인

```bash
# 프로젝트 구조 확인
ls -la

# 출력 예시:
# .git/
# .gitignore
# build.gradle
# gradle/
# gradlew
# gradlew.bat
# src/
# README.md
# CLAUDE.md
# ...
```

---

## 4. 데이터베이스 설정

### 4.1 MySQL 데이터베이스 생성

#### 방법 1: MySQL CLI

```bash
# MySQL 접속
mysql -u root -p
# 비밀번호 입력
```

```sql
-- 데이터베이스 생성
CREATE DATABASE trading_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

-- 사용자 생성 (선택)
CREATE USER 'trading_user'@'localhost' IDENTIFIED BY 'your_password';

-- 권한 부여
GRANT ALL PRIVILEGES ON trading_db.* TO 'trading_user'@'localhost';

-- 권한 적용
FLUSH PRIVILEGES;

-- 데이터베이스 선택
USE trading_db;

-- 생성 확인
SHOW DATABASES;
SHOW GRANTS FOR 'trading_user'@'localhost';

-- 종료
EXIT;
```

#### 방법 2: MySQL Workbench (GUI)

1. MySQL Workbench 실행
2. 로컬 MySQL 연결
3. 새 스키마 생성
   - 이름: `trading_db`
   - Charset: `utf8mb4`
   - Collation: `utf8mb4_unicode_ci`
4. Apply 클릭

### 4.2 데이터베이스 연결 테스트

```bash
# 생성한 데이터베이스에 접속
mysql -u trading_user -p trading_db

# 또는 root로
mysql -u root -p trading_db
```

```sql
-- 테이블 목록 확인 (아직 비어있음)
SHOW TABLES;

-- 종료
EXIT;
```

---

## 5. 환경 설정 파일 구성

### 5.1 application.properties 생성

프로젝트 루트에서:

```bash
# src/main/resources 디렉토리로 이동
cd src/main/resources

# application-prod.properties를 복사하여 application.properties 생성
cp application-prod.properties application.properties

# 또는 새로 생성
nano application.properties
# Windows: notepad application.properties
```

### 5.2 개발 환경 설정 (application.properties)

다음 내용으로 `src/main/resources/application.properties` 파일 생성:

```properties
# ===================================
# Development Configuration
# ===================================
spring.application.name=UsedCarTrading

# ===================================
# H2 Database (In-Memory) - 개발용
# ===================================
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=

# H2 Console 활성화
spring.h2.console.enabled=true
spring.h2.console.path=/h2-console
spring.h2.console.settings.web-allow-others=false

# ===================================
# MySQL Database (로컬 MySQL 사용시)
# ===================================
# 위의 H2 설정을 주석처리하고 아래 MySQL 설정 사용
# spring.datasource.url=jdbc:mysql://localhost:3306/trading_db?useSSL=false&serverTimezone=Asia/Seoul&characterEncoding=UTF-8
# spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
# spring.datasource.username=trading_user
# spring.datasource.password=your_password

# ===================================
# JPA / Hibernate
# ===================================
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
# MySQL 사용시: spring.jpa.database-platform=org.hibernate.dialect.MySQL8Dialect

spring.jpa.hibernate.ddl-auto=create-drop
# 옵션 설명:
# - create-drop: 시작시 생성, 종료시 삭제 (개발용)
# - create: 시작시 생성 (기존 테이블 삭제)
# - update: 변경사항만 반영 (데이터 유지)
# - validate: 스키마 검증만 (프로덕션)
# - none: 아무것도 하지 않음

spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true

# ===================================
# Logging
# ===================================
logging.level.root=INFO
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.type.descriptor.sql.BasicBinder=TRACE
logging.level.com.usedcar.trading=DEBUG
logging.level.org.springframework.web=DEBUG

# ===================================
# Server
# ===================================
server.port=8080

# ===================================
# Thymeleaf (개발 모드)
# ===================================
spring.thymeleaf.cache=false
spring.thymeleaf.prefix=classpath:/templates/
spring.thymeleaf.suffix=.html

# ===================================
# DevTools
# ===================================
spring.devtools.restart.enabled=true
spring.devtools.livereload.enabled=true

# ===================================
# JWT
# ===================================
jwt.secret=dev-secret-key-for-testing-only-min-256-bits-long-string-here
jwt.expiration=86400000

# ===================================
# OAuth2 (선택 - 테스트시 주석처리 가능)
# ===================================
# Google
# spring.security.oauth2.client.registration.google.client-id=your-client-id
# spring.security.oauth2.client.registration.google.client-secret=your-client-secret

# Kakao
# spring.security.oauth2.client.registration.kakao.client-id=your-client-id
# spring.security.oauth2.client.registration.kakao.client-secret=your-client-secret

# ===================================
# File Upload
# ===================================
spring.servlet.multipart.enabled=true
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=50MB
```

### 5.3 설정 확인

```bash
# application.properties 파일 존재 확인
ls -la src/main/resources/application.properties

# 내용 확인
cat src/main/resources/application.properties
```

**중요:**
- `application.properties`는 `.gitignore`에 포함되어 Git에 커밋되지 않습니다
- 각 개발자는 자신의 로컬 환경에 맞게 설정해야 합니다

---

## 6. 컴파일 (빌드)

### 6.1 의존성 다운로드

프로젝트 루트 디렉토리에서:

```bash
# Gradle Wrapper에 실행 권한 부여 (macOS/Linux)
chmod +x gradlew

# 의존성 다운로드 및 확인
./gradlew dependencies

# Windows
gradlew.bat dependencies
```

### 6.2 프로젝트 빌드

#### 전체 빌드 (테스트 포함)

```bash
# Clean + Build + Test
./gradlew clean build

# Windows
gradlew.bat clean build
```

**예상 출력:**
```
> Task :compileJava
> Task :processResources
> Task :classes
> Task :bootJar
> Task :jar
> Task :assemble
> Task :compileTestJava
> Task :processTestResources
> Task :testClasses
> Task :test
> Task :check
> Task :build

BUILD SUCCESSFUL in 45s
```

#### 빌드만 (테스트 제외)

```bash
# 테스트를 건너뛰고 빌드
./gradlew clean build -x test

# Windows
gradlew.bat clean build -x test
```

### 6.3 빌드 결과 확인

```bash
# 빌드된 JAR 파일 확인
ls -lh build/libs/

# 출력 예시:
# trading-0.0.1-SNAPSHOT.jar (약 50-80MB)
# trading-0.0.1-SNAPSHOT-plain.jar
```

**파일 설명:**
- `trading-0.0.1-SNAPSHOT.jar`: 실행 가능한 JAR (모든 의존성 포함)
- `trading-0.0.1-SNAPSHOT-plain.jar`: 라이브러리 JAR (의존성 미포함)

### 6.4 빌드 캐시 정리 (문제 발생시)

```bash
# Gradle 캐시 정리
./gradlew clean

# 빌드 디렉토리 완전 삭제
rm -rf build/
rm -rf .gradle/

# 재빌드
./gradlew build
```

---

## 7. 실행 방법

### 7.1 개발 모드 실행

#### 방법 1: Gradle로 실행 (권장)

```bash
# Spring Boot 애플리케이션 실행
./gradlew bootRun

# Windows
gradlew.bat bootRun
```

**장점:**
- 코드 변경 시 자동 재시작 (DevTools)
- IDE 없이 실행 가능
- 설정 간편

**예상 출력:**
```
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::               (v3.5.7)

2025-12-06 14:30:00.000  INFO --- [main] c.u.t.UsedCarTradingApplication : Starting UsedCarTradingApplication
...
2025-12-06 14:30:05.000  INFO --- [main] o.s.b.w.embedded.tomcat.TomcatWebServer : Tomcat started on port(s): 8080 (http)
2025-12-06 14:30:05.000  INFO --- [main] c.u.t.UsedCarTradingApplication : Started UsedCarTradingApplication in 5.123 seconds
```

#### 방법 2: JAR 파일로 실행

```bash
# 빌드 먼저
./gradlew build -x test

# JAR 파일 실행
java -jar build/libs/trading-0.0.1-SNAPSHOT.jar

# 프로파일 지정 (선택)
java -jar build/libs/trading-0.0.1-SNAPSHOT.jar --spring.profiles.active=dev
```

#### 방법 3: IDE에서 실행

**IntelliJ IDEA:**
1. `src/main/java/com/usedcar/trading/UsedCarTradingApplication.java` 열기
2. `main` 메서드 옆의 ▶️ 버튼 클릭
3. 또는 우클릭 → Run 'UsedCarTradingApplication'

**Eclipse:**
1. 프로젝트 우클릭
2. Run As → Spring Boot App

### 7.2 접속 확인

#### 웹 브라우저 접속

```
홈페이지:
http://localhost:8080

H2 Console (H2 사용시):
http://localhost:8080/h2-console
  JDBC URL: jdbc:h2:mem:testdb
  Username: sa
  Password: (비어있음)
```

#### cURL로 헬스체크

```bash
# 기본 접속 확인
curl http://localhost:8080

# Actuator 헬스체크 (활성화된 경우)
curl http://localhost:8080/actuator/health
```

### 7.3 프로덕션 모드 실행

#### 프로파일 지정 실행

```bash
# application-prod.properties 사용
java -jar build/libs/trading-0.0.1-SNAPSHOT.jar \
     --spring.profiles.active=prod

# 또는 환경 변수로
export SPRING_PROFILES_ACTIVE=prod
java -jar build/libs/trading-0.0.1-SNAPSHOT.jar
```

#### 외부 설정 파일 사용

```bash
# 특정 위치의 설정 파일 사용
java -jar build/libs/trading-0.0.1-SNAPSHOT.jar \
     --spring.config.location=/path/to/application.properties

# 여러 설정 파일 사용
java -jar build/libs/trading-0.0.1-SNAPSHOT.jar \
     --spring.config.location=classpath:/application.properties,/external/config/
```

#### JVM 옵션 지정

```bash
# 메모리 설정
java -Xms512m -Xmx1024m \
     -jar build/libs/trading-0.0.1-SNAPSHOT.jar

# GC 옵션 추가
java -Xms512m -Xmx1024m \
     -XX:+UseG1GC \
     -XX:MaxGCPauseMillis=200 \
     -jar build/libs/trading-0.0.1-SNAPSHOT.jar
```

#### 백그라운드 실행 (Linux/macOS)

```bash
# nohup으로 백그라운드 실행
nohup java -jar build/libs/trading-0.0.1-SNAPSHOT.jar > app.log 2>&1 &

# 프로세스 ID 확인
echo $!

# 로그 확인
tail -f app.log

# 프로세스 종료
kill <PID>
```

### 7.4 애플리케이션 종료

```bash
# Ctrl + C (포그라운드 실행시)

# 백그라운드 프로세스 찾기
ps aux | grep trading

# 프로세스 종료
kill <PID>

# 강제 종료
kill -9 <PID>
```

---

## 8. 테스트 실행

### 8.1 전체 테스트 실행

```bash
# 모든 테스트 실행
./gradlew test

# Windows
gradlew.bat test
```

### 8.2 특정 테스트 클래스 실행

```bash
# 특정 테스트 클래스만 실행
./gradlew test --tests "com.usedcar.trading.UsedCarTradingApplicationTests"

# 패턴 매칭
./gradlew test --tests "*Service*"
```

### 8.3 테스트 리포트 확인

```bash
# 테스트 실행 후
# 리포트 위치: build/reports/tests/test/index.html

# macOS에서 브라우저로 열기
open build/reports/tests/test/index.html

# Linux
xdg-open build/reports/tests/test/index.html

# Windows
start build/reports/tests/test/index.html
```

### 8.4 테스트 커버리지 (JaCoCo)

build.gradle에 JaCoCo 플러그인이 있는 경우:

```bash
# 테스트 커버리지 리포트 생성
./gradlew test jacocoTestReport

# 리포트 확인
open build/reports/jacoco/test/html/index.html
```

---

## 9. IDE 설정 (선택)

### 9.1 IntelliJ IDEA

#### 프로젝트 import

1. **Open 또는 Import**
   - File → Open
   - 프로젝트 루트 디렉토리 선택 (build.gradle 있는 곳)

2. **Gradle 프로젝트로 인식**
   - Trust Project 클릭
   - Gradle 자동 import 대기

3. **JDK 설정 확인**
   - File → Project Structure (Cmd+; / Ctrl+Alt+Shift+S)
   - Project → SDK: 17 선택
   - Language Level: 17

#### Lombok 플러그인 설치

1. **플러그인 설치**
   - Preferences → Plugins
   - "Lombok" 검색 및 설치
   - IDE 재시작

2. **Annotation Processing 활성화**
   - Preferences → Build, Execution, Deployment → Compiler → Annotation Processors
   - ✅ Enable annotation processing 체크

#### 실행 구성

1. **Run Configuration 생성**
   - Run → Edit Configurations
   - ➕ → Spring Boot
   - Main class: `com.usedcar.trading.UsedCarTradingApplication`
   - Active profiles: `dev` (선택)

### 9.2 Eclipse

#### 프로젝트 Import

1. **File → Import**
2. **Gradle → Existing Gradle Project**
3. 프로젝트 루트 디렉토리 선택
4. Finish

#### Lombok 설정

1. **lombok.jar 다운로드**
   ```bash
   # Gradle 캐시에서 찾기
   find ~/.gradle/caches -name "lombok*.jar"
   ```

2. **Lombok Installer 실행**
   ```bash
   java -jar lombok-xxx.jar
   ```

3. **Eclipse 선택 및 설치**

4. **Eclipse 재시작**

### 9.3 VS Code

#### 확장 프로그램 설치

1. **Java Extension Pack**
2. **Spring Boot Extension Pack**
3. **Lombok Annotations Support**

#### settings.json 설정

```json
{
  "java.configuration.updateBuildConfiguration": "automatic",
  "java.compile.nullAnalysis.mode": "automatic",
  "spring-boot.ls.problem.application-properties.enabled": true
}
```

---

## 10. 문제 해결

### 10.1 컴파일 오류

#### "Java 17 required"

**증상:**
```
Gradle requires Java 17 or later to run. You are currently using Java 11.
```

**해결:**
```bash
# Java 버전 확인
java -version

# JAVA_HOME 설정 (macOS/Linux)
export JAVA_HOME=$(/usr/libexec/java_home -v 17)

# Windows
# 시스템 환경변수에서 JAVA_HOME 설정
```

#### "Could not resolve dependencies"

**증상:**
```
Could not resolve all dependencies for configuration ':compileClasspath'.
```

**해결:**
```bash
# Gradle 캐시 정리
./gradlew clean --refresh-dependencies

# 오프라인 모드 비활성화
./gradlew build --no-daemon
```

#### Lombok 관련 오류

**증상:**
```
cannot find symbol: method builder()
```

**해결:**
1. Lombok 플러그인 설치 확인
2. Annotation Processing 활성화
3. IDE 재시작
4. 프로젝트 Clean & Rebuild

### 10.2 실행 오류

#### "Port 8080 already in use"

**증상:**
```
Web server failed to start. Port 8080 was already in use.
```

**해결:**

**방법 1: 포트 변경**
```properties
# application.properties
server.port=8081
```

**방법 2: 기존 프로세스 종료**
```bash
# macOS/Linux
lsof -i :8080
kill -9 <PID>

# Windows
netstat -ano | findstr :8080
taskkill /PID <PID> /F
```

#### 데이터베이스 연결 오류

**증상:**
```
Cannot create PoolableConnectionFactory
Communications link failure
```

**해결:**
1. **MySQL 서비스 실행 확인**
   ```bash
   # macOS
   brew services list | grep mysql

   # Linux
   sudo systemctl status mysql

   # Windows
   net start | findstr MySQL
   ```

2. **연결 정보 확인**
   - URL, 사용자명, 비밀번호 재확인
   - 방화벽 설정 확인

3. **MySQL 접속 테스트**
   ```bash
   mysql -u trading_user -p trading_db
   ```

#### "Table doesn't exist"

**증상:**
```
Table 'trading_db.vehicle' doesn't exist
```

**해결:**

**방법 1: DDL 자동 생성 활성화**
```properties
# application.properties
spring.jpa.hibernate.ddl-auto=create
# 또는 update
```

**방법 2: 수동 스키마 생성**
```sql
-- SQL 스크립트 실행 (있는 경우)
mysql -u root -p trading_db < schema.sql
```

### 10.3 메모리 부족

**증상:**
```
java.lang.OutOfMemoryError: Java heap space
```

**해결:**
```bash
# 힙 메모리 증가
export JAVA_OPTS="-Xms512m -Xmx2048m"
./gradlew bootRun

# 또는 JAR 실행시
java -Xms512m -Xmx2048m -jar build/libs/trading-0.0.1-SNAPSHOT.jar
```

### 10.4 정적 리소스 404

**증상:**
```
GET /css/style.css 404 Not Found
```

**해결:**
1. **파일 위치 확인**
   ```
   src/main/resources/static/css/style.css
   ```

2. **빌드 후 재시작**
   ```bash
   ./gradlew clean build
   ./gradlew bootRun
   ```

3. **캐시 클리어**
   - 브라우저 캐시 삭제 (Ctrl+F5)

---

## 11. 부록

### 11.1 유용한 Gradle 명령어

```bash
# 프로젝트 정보 확인
./gradlew projects

# 태스크 목록
./gradlew tasks

# 의존성 트리
./gradlew dependencies

# 빌드 스캔 (상세 정보)
./gradlew build --scan

# 데몬 중지
./gradlew --stop

# 병렬 빌드
./gradlew build --parallel

# 오프라인 모드
./gradlew build --offline
```

### 11.2 데이터 초기화 스크립트

개발 중 데이터베이스를 초기화하려면:

```bash
# H2 사용시
# 애플리케이션 재시작하면 자동 초기화 (create-drop)

# MySQL 사용시
mysql -u root -p trading_db << EOF
DROP DATABASE IF EXISTS trading_db;
CREATE DATABASE trading_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE trading_db;
EOF

# 애플리케이션 재시작
./gradlew bootRun
```

### 11.3 샘플 데이터 삽입

`DataInit.java` 파일이 있다면 자동으로 샘플 데이터가 생성됩니다.

```java
// src/main/java/com/usedcar/trading/global/config/DataInit.java
// 이 클래스에서 초기 데이터를 설정
```

수동으로 데이터 삽입:

```sql
-- 관리자 계정 생성 예시
INSERT INTO user (email, password, name, role, provider, user_status, created_at, updated_at)
VALUES ('admin@example.com', '$2a$10$...', 'Admin', 'ADMIN', 'LOCAL', 'ACTIVE', NOW(), NOW());
```

### 11.4 로그 레벨 조정

```properties
# application.properties

# 전체 로그 레벨
logging.level.root=INFO

# 특정 패키지 로그 레벨
logging.level.com.usedcar.trading=DEBUG
logging.level.org.springframework.security=DEBUG
logging.level.org.hibernate.SQL=DEBUG

# 로그 파일 출력
logging.file.name=logs/application.log
logging.file.max-size=10MB
logging.file.max-history=7
```

### 11.5 프로파일별 설정 파일

```
src/main/resources/
├── application.properties           # 공통 설정
├── application-dev.properties       # 개발 환경
├── application-prod.properties      # 프로덕션 환경
└── application-test.properties      # 테스트 환경
```

**프로파일 활성화:**
```bash
# 실행시 지정
./gradlew bootRun --args='--spring.profiles.active=dev'

# 또는
java -jar app.jar --spring.profiles.active=prod

# 환경 변수로
export SPRING_PROFILES_ACTIVE=dev
```

### 11.6 환경 변수 설정

민감한 정보는 환경 변수로 관리:

```bash
# macOS/Linux (~/.bashrc 또는 ~/.zshrc)
export DB_USERNAME=trading_user
export DB_PASSWORD=secret_password
export JWT_SECRET=your-secret-key

# Windows (시스템 환경 변수)
setx DB_USERNAME "trading_user"
setx DB_PASSWORD "secret_password"
```

**application.properties에서 사용:**
```properties
spring.datasource.username=${DB_USERNAME:trading_user}
spring.datasource.password=${DB_PASSWORD:default_password}
jwt.secret=${JWT_SECRET:dev-secret}
```

### 11.7 도커로 실행 (선택)

#### Dockerfile 생성

```dockerfile
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY build/libs/trading-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### 빌드 및 실행

```bash
# Docker 이미지 빌드
docker build -t trading-app .

# 컨테이너 실행
docker run -d -p 8080:8080 --name trading trading-app

# 로그 확인
docker logs -f trading

# 중지
docker stop trading

# 삭제
docker rm trading
```

---

## 📞 추가 지원

### 문서
- **프로젝트 개요**: [README.md](README.md)
- **개발 가이드**: [CLAUDE.md](CLAUDE.md)
- **사용자 매뉴얼**: [USER_MANUAL.md](USER_MANUAL.md)
- **AWS 배포**: [AWS_DEPLOYMENT_GUIDE.md](AWS_DEPLOYMENT_GUIDE.md)

### 문의
- **이슈 등록**: https://github.com/Jhui91/dev2/issues
- **이메일**: support@example.com

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|-----------|
| 1.0.0 | 2025-12-06 | 초판 작성 |

---

**설치 과정에서 문제가 발생하면 위의 문제 해결 섹션을 참고하거나 이슈를 등록해주세요.**

© 2025 중고차 거래 플랫폼. All rights reserved.
