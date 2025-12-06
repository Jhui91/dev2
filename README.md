# 🚗 중고차 거래 플랫폼 (Used Car Trading Platform)

Spring Boot 기반의 B2B/B2C 통합 중고차 거래 플랫폼입니다. 딜러사와 일반 고객을 연결하여 투명하고 안전한 중고차 거래를 지원합니다.

[![Java](https://img.shields.io/badge/Java-17-orange.svg)](https://www.oracle.com/java/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.5.7-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Gradle](https://img.shields.io/badge/Gradle-8.x-blue.svg)](https://gradle.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📋 목차

- [주요 기능](#-주요 기능)
- [기술 스택](#-기술-스택)
- [시작하기](#-시작하기)
- [프로젝트 구조](#-프로젝트-구조)
- [사용자 역할](#-사용자-역할)
- [주요 도메인](#-주요-도메인)
- [API 엔드포인트](#-api-엔드포인트)
- [환경 설정](#-환경-설정)
- [개발 가이드](#-개발-가이드)
- [배포](#-배포)

## ✨ 주요 기능

### 👥 다중 사용자 역할 지원
- **관리자**: 플랫폼 전체 관리, 매물 승인, 정산 관리
- **딜러사 사장님**: 업체 관리, 직원 관리, 정산 조회
- **딜러사 직원**: 차량 등록 및 관리
- **일반 고객**: 차량 검색, 찜하기, 구매, 리뷰 작성

### 🚙 차량 관리
- 차량 등록 및 다중 이미지 업로드
- 차량 상세 정보 (브랜드, 모델, 연식, 주행거리, 가격 등)
- 사고 이력 관리
- 차량 상태 관리 (대기, 판매중, 예약, 판매완료, 거부, 삭제)
- 조회수 자동 집계
- 매물 만료일 자동 관리

### 🔍 검색 및 필터링
- 브랜드, 모델, 가격대별 검색
- 연식, 주행거리, 연료 타입, 변속기 필터
- 인기순, 최신순, 가격순 정렬

### 💼 거래 및 정산
- 구매 요청 및 거래 상태 관리
- 딜러사별 정산 내역 관리
- 거래 완료 후 자동 정산 생성

### ⭐ 리뷰 및 평가
- 거래 완료 후 리뷰 작성
- 별점 평가 시스템
- 딜러사별 평점 집계

### 🔔 알림 시스템
- 거래 상태 변경 알림
- 매물 승인/거부 알림
- 정산 완료 알림

### 📊 신고 및 관리
- 부적절한 매물/리뷰 신고
- 신고 처리 및 상태 관리

### 🔐 인증 및 보안
- 이메일/비밀번호 로그인
- OAuth2 소셜 로그인 (Google, Kakao, Naver)
- JWT 토큰 기반 인증
- 역할 기반 접근 제어 (RBAC)

## 🛠 기술 스택

### Backend
- **Language**: Java 17
- **Framework**: Spring Boot 3.5.7
- **ORM**: Spring Data JPA / Hibernate
- **Security**: Spring Security + OAuth2 + JWT
- **Build Tool**: Gradle 8.x
- **Validation**: Jakarta Validation API

### Database
- **Development**: H2 Database (In-Memory)
- **Production**: MySQL 8.0

### Frontend
- **Template Engine**: Thymeleaf
- **UI Framework**: Bootstrap 5
- **JavaScript**: jQuery
- **Charts**: ApexCharts
- **Carousel**: Owl Carousel
- **Lightbox**: Magnific Popup

### DevOps
- **Version Control**: Git
- **Server**: Embedded Tomcat
- **Scheduler**: Spring Scheduler

## 🚀 시작하기

### 사전 요구사항

- **Java 17** 이상
- **Gradle 8.x** (또는 포함된 Gradle Wrapper 사용)
- **MySQL 8.0** (프로덕션 환경)
- **Git**

### 설치 및 실행

#### 1. 레포지토리 클론
```bash
git clone https://github.com/Jhui91/dev2.git
cd dev2
```

#### 2. 데이터베이스 설정 (프로덕션)

**MySQL 데이터베이스 생성:**
```sql
CREATE DATABASE trading_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

**사용자 생성 및 권한 부여:**
```sql
CREATE USER 'trading_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON trading_db.* TO 'trading_user'@'localhost';
FLUSH PRIVILEGES;
```

#### 3. 환경 설정 파일 생성

`src/main/resources/application.properties` 파일 생성:
```properties
# Application
spring.application.name=UsedCarTrading

# Database (Development - H2)
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=

# H2 Console
spring.h2.console.enabled=true
spring.h2.console.path=/h2-console

# JPA / Hibernate
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=create-drop
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true

# Logging
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.type.descriptor.sql.BasicBinder=TRACE
logging.level.com.usedcar.trading=DEBUG

# Server
server.port=8080

# JWT
jwt.secret=your-secret-key-min-256-bits-change-this-in-production-environment
jwt.expiration=86400000

# OAuth2 (선택사항 - 사용시 설정)
# spring.security.oauth2.client.registration.google.client-id=your-client-id
# spring.security.oauth2.client.registration.google.client-secret=your-client-secret
```

**중요**: `application.properties` 파일은 `.gitignore`에 포함되어 있어 Git에 커밋되지 않습니다.

#### 4. 빌드
```bash
# 테스트 포함 빌드
./gradlew build

# 테스트 제외 빌드
./gradlew build -x test
```

#### 5. 실행
```bash
# Gradle로 실행
./gradlew bootRun

# JAR 파일로 실행
java -jar build/libs/trading-0.0.1-SNAPSHOT.jar
```

#### 6. 접속
```
http://localhost:8080
```

**H2 콘솔 (개발 환경):**
```
http://localhost:8080/h2-console
JDBC URL: jdbc:h2:mem:testdb
Username: sa
Password: (빈 칸)
```

## 📁 프로젝트 구조

```
dev2/
├── src/
│   ├── main/
│   │   ├── java/com/usedcar/trading/
│   │   │   ├── domain/                    # 비즈니스 도메인
│   │   │   │   ├── admin/                # 관리자
│   │   │   │   ├── company/              # 딜러사
│   │   │   │   ├── employee/             # 직원
│   │   │   │   ├── favorite/             # 찜하기
│   │   │   │   ├── notification/         # 알림
│   │   │   │   ├── report/               # 신고
│   │   │   │   ├── review/               # 리뷰
│   │   │   │   ├── settlement/           # 정산
│   │   │   │   ├── transaction/          # 거래
│   │   │   │   ├── user/                 # 사용자
│   │   │   │   └── vehicle/              # 차량
│   │   │   ├── global/                    # 공통 기능
│   │   │   │   ├── audit/                # 감사 (BaseEntity)
│   │   │   │   ├── auth/                 # 인증/인가
│   │   │   │   ├── config/               # 설정
│   │   │   │   ├── exception/            # 예외 처리
│   │   │   │   └── home/                 # 홈 컨트롤러
│   │   │   └── UsedCarTradingApplication.java
│   │   └── resources/
│   │       ├── static/                    # 정적 리소스
│   │       │   ├── css/                  # 스타일시트
│   │       │   ├── js/                   # JavaScript
│   │       │   ├── images/               # 이미지
│   │       │   └── libs/                 # 라이브러리
│   │       ├── templates/                 # Thymeleaf 템플릿
│   │       │   ├── admin/
│   │       │   ├── company/
│   │       │   ├── fragments/            # 재사용 가능한 조각
│   │       │   ├── mypage/
│   │       │   └── vehicle/
│   │       ├── application-prod.properties
│   │       └── application.properties     # (gitignored)
│   └── test/
│       └── java/com/usedcar/trading/
├── gradle/
├── build.gradle
├── .gitignore
├── CLAUDE.md                              # AI 어시스턴트 가이드
└── README.md                              # 프로젝트 문서 (본 파일)
```

### 도메인 계층 구조
각 도메인은 다음과 같은 계층 구조를 따릅니다:

```
domain/{domain_name}/
├── controller/        # HTTP 요청 처리
├── dto/              # 데이터 전송 객체
├── entity/           # JPA 엔티티
├── repository/       # 데이터 접근 계층
└── service/          # 비즈니스 로직
```

## 👤 사용자 역할

| 역할 | 권한 | 설명 |
|------|------|------|
| **ADMIN** | 전체 관리 | 플랫폼 관리자, 매물 승인/거부, 정산 관리 |
| **COMPANY_OWNER** | 업체 관리 | 딜러사 사장님, 직원 관리, 매물 등록, 정산 조회 |
| **COMPANY_EMPLOYEE** | 매물 관리 | 딜러사 직원, 매물 등록 및 수정 |
| **CUSTOMER** | 구매 및 리뷰 | 일반 고객, 매물 검색, 찜하기, 구매, 리뷰 작성 |

## 🗂 주요 도메인

### 1. Vehicle (차량)
- 차량 정보 관리 (브랜드, 모델, 연식, 주행거리, 가격 등)
- 다중 이미지 업로드
- 상태 관리: `PENDING` → `SALE` → `RESERVED` → `SOLD`
- 사고 이력, 옵션, 설명 등

### 2. User (사용자)
- 이메일/비밀번호 인증
- OAuth2 소셜 로그인 (Google, Kakao, Naver)
- 역할 기반 권한 관리
- 계정 상태 관리 (활성, 비활성, 차단)

### 3. Company (딜러사)
- 사업자 정보 관리
- 직원 관리
- 매출 및 정산 조회

### 4. Transaction (거래)
- 구매 요청 및 승인
- 거래 상태 추적
- 거래 완료 후 정산 생성

### 5. Settlement (정산)
- 딜러사별 정산 내역
- 정산 상태 관리 (대기, 완료)
- 관리자 승인 프로세스

### 6. Review (리뷰)
- 거래 완료 후 리뷰 작성
- 별점 평가
- 딜러사 평점 집계

### 7. Favorite (찜하기)
- 관심 차량 저장
- 개인 위시리스트 관리

### 8. Notification (알림)
- 실시간 알림 전송
- 알림 유형별 분류
- 읽음/안읽음 상태 관리

### 9. Report (신고)
- 부적절한 콘텐츠 신고
- 신고 유형 및 사유 관리
- 관리자 처리 프로세스

## 🌐 API 엔드포인트

### 공개 API
```
GET  /                          # 홈페이지
GET  /vehicles                  # 차량 목록
GET  /vehicles/{id}             # 차량 상세
GET  /search                    # 차량 검색
POST /signup                    # 회원가입
POST /login                     # 로그인
```

### 관리자 API
```
GET  /admin                     # 관리자 대시보드
GET  /admin/vehicles/pending    # 승인 대기 차량
POST /admin/vehicles/{id}/approve   # 차량 승인
POST /admin/vehicles/{id}/reject    # 차량 거부
GET  /admin/settlements         # 정산 관리
```

### 딜러사 API
```
GET  /company/sales             # 매출 현황
GET  /company/employees         # 직원 관리 (사장님만)
GET  /company/settlements       # 정산 조회 (사장님만)
POST /vehicles/register         # 차량 등록
PUT  /vehicles/{id}/edit        # 차량 수정
DELETE /vehicles/{id}/delete    # 차량 삭제
```

### 고객 API
```
GET  /favorites                 # 찜 목록
POST /favorites/{vehicleId}     # 찜 추가
DELETE /favorites/{vehicleId}   # 찜 해제
POST /reviews                   # 리뷰 작성
POST /transactions              # 구매 요청
```

### 공통 API (인증 필요)
```
GET  /mypage                    # 마이페이지
GET  /notifications             # 알림 조회
POST /notifications/{id}/read   # 알림 읽음 처리
GET  /transactions              # 거래 내역
```

## ⚙ 환경 설정

### 개발 환경 (application.properties)
```properties
# H2 데이터베이스 사용
spring.datasource.url=jdbc:h2:mem:testdb
spring.jpa.hibernate.ddl-auto=create-drop
spring.jpa.show-sql=true
```

### 프로덕션 환경 (application-prod.properties)
```properties
# MySQL 데이터베이스 사용
spring.datasource.url=jdbc:mysql://localhost:3306/trading_db
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.show-sql=false
```

### 프로필 활성화
```bash
# 프로덕션 프로필로 실행
java -jar app.jar --spring.profiles.active=prod
```

### 환경 변수 설정
중요한 설정은 환경 변수로 관리하는 것을 권장합니다:

```bash
export JWT_SECRET=your-secret-key
export DB_USERNAME=your-db-username
export DB_PASSWORD=your-db-password
export OAUTH2_GOOGLE_CLIENT_ID=your-client-id
export OAUTH2_GOOGLE_CLIENT_SECRET=your-client-secret
```

## 👨‍💻 개발 가이드

### 코딩 컨벤션

#### Entity 작성
```java
@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class Vehicle extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long vehicleId;

    @Column(nullable = false)
    private String brand;

    @Enumerated(EnumType.STRING)  // 항상 STRING 사용
    private VehicleStatus status;

    // 비즈니스 로직 메서드
    public void approve(User admin) {
        this.status = VehicleStatus.SALE;
        this.approvedBy = admin;
        this.approvedAt = LocalDateTime.now();
    }
}
```

#### Service 작성
```java
@Service
@RequiredArgsConstructor  // 생성자 주입
public class VehicleService {

    private final VehicleRepository vehicleRepository;

    @Transactional
    public Vehicle registerVehicle(VehicleRegisterRequest request) {
        // 비즈니스 로직
        Vehicle vehicle = Vehicle.builder()
                .brand(request.getBrand())
                .model(request.getModel())
                .build();

        return vehicleRepository.save(vehicle);
    }
}
```

#### Controller 작성
```java
@Controller
@RequiredArgsConstructor
public class VehicleController {

    private final VehicleService vehicleService;

    @GetMapping("/vehicles/{id}")
    public String getVehicle(@PathVariable Long id, Model model) {
        Vehicle vehicle = vehicleService.getVehicle(id);
        model.addAttribute("vehicle", vehicle);
        return "vehicle/detail";
    }
}
```

### 예외 처리
```java
// 예외 발생
if (vehicle == null) {
    throw new CustomException(ErrorCode.VEHICLE_NOT_FOUND);
}

// ErrorCode에 정의된 에러 코드 사용
public enum ErrorCode {
    VEHICLE_NOT_FOUND(HttpStatus.NOT_FOUND, "VEHICLE_001", "존재하지 않는 매물입니다"),
    // ...
}
```

### 테스트 작성
```java
@SpringBootTest
class VehicleServiceTest {

    @Autowired
    private VehicleService vehicleService;

    @Test
    void 차량_등록_성공() {
        // given
        VehicleRegisterRequest request = new VehicleRegisterRequest(/*...*/);

        // when
        Vehicle vehicle = vehicleService.registerVehicle(request);

        // then
        assertThat(vehicle.getBrand()).isEqualTo("BMW");
    }
}
```

## 🚢 배포

### 프로덕션 빌드
```bash
# JAR 파일 생성
./gradlew clean build -x test

# 빌드 파일 위치
build/libs/trading-0.0.1-SNAPSHOT.jar
```

### 서버 실행
```bash
# 백그라운드 실행
nohup java -jar trading-0.0.1-SNAPSHOT.jar --spring.profiles.active=prod > app.log 2>&1 &

# 로그 확인
tail -f app.log
```

### Docker (선택사항)
```dockerfile
# Dockerfile 예시
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY build/libs/trading-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

```bash
# 이미지 빌드
docker build -t used-car-trading .

# 컨테이너 실행
docker run -d -p 8080:8080 --name trading-app used-car-trading
```

## 📝 데이터베이스 스키마

### 주요 테이블

```sql
-- 사용자
CREATE TABLE user (
    user_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255),
    name VARCHAR(100),
    role VARCHAR(50),
    provider VARCHAR(50),
    status VARCHAR(50),
    created_at DATETIME,
    updated_at DATETIME
);

-- 차량
CREATE TABLE vehicle (
    vehicle_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    model_year INT NOT NULL,
    mileage INT NOT NULL,
    price DECIMAL(12,2) NOT NULL,
    fuel_type VARCHAR(50),
    transmission VARCHAR(50),
    vehicle_status VARCHAR(50),
    company_id BIGINT,
    registered_by BIGINT,
    approved_by BIGINT,
    created_at DATETIME,
    updated_at DATETIME,
    FOREIGN KEY (company_id) REFERENCES company(company_id),
    FOREIGN KEY (registered_by) REFERENCES employee(employee_id),
    FOREIGN KEY (approved_by) REFERENCES user(user_id)
);

-- 거래
CREATE TABLE transaction (
    transaction_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    vehicle_id BIGINT NOT NULL,
    buyer_id BIGINT NOT NULL,
    transaction_status VARCHAR(50),
    created_at DATETIME,
    updated_at DATETIME,
    FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id),
    FOREIGN KEY (buyer_id) REFERENCES user(user_id)
);
```

## 🤝 기여하기

프로젝트에 기여하고 싶으시다면:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### 커밋 메시지 규칙
```
feat: 새로운 기능 추가
fix: 버그 수정
docs: 문서 수정
style: 코드 포맷팅, 세미콜론 누락 등
refactor: 코드 리팩토링
test: 테스트 코드 추가
chore: 빌드 업무 수정, 패키지 매니저 수정 등
```

## 📚 추가 문서

- **[CLAUDE.md](CLAUDE.md)** - AI 어시스턴트를 위한 상세한 개발 가이드
- **API 문서** - (Swagger/OpenAPI 추가 예정)
- **ERD** - (데이터베이스 스키마 다이어그램 추가 예정)

## 🐛 버그 리포트

버그를 발견하셨다면 [Issues](https://github.com/Jhui91/dev2/issues)에 등록해주세요.

## 📄 라이선스

This project is licensed under the MIT License - see the LICENSE file for details.

## 📧 연락처

프로젝트 관리자 - [@Jhui91](https://github.com/Jhui91)

프로젝트 링크: [https://github.com/Jhui91/dev2](https://github.com/Jhui91/dev2)

---

**Made with ❤️ by the Used Car Trading Team**
