# CLAUDE.md - AI Assistant Guide for Used Car Trading Platform

## Project Overview

**Project Name:** Used Car Trading Platform
**Group:** com.usedcar
**Artifact:** trading
**Version:** 0.0.1-SNAPSHOT
**Description:** A comprehensive B2B/B2C platform for used car trading with multi-role support (Admin, Company Owners, Employees, Customers)

### Business Domain
This platform facilitates used car sales with the following key actors:
- **Admins**: Oversee platform operations, approve vehicles, manage settlements
- **Company Owners**: Manage dealerships, employees, and settlements
- **Company Employees**: Register and manage vehicle listings
- **Customers**: Browse, favorite, purchase vehicles, and write reviews

---

## Technology Stack

### Core Framework
- **Java 17** (Language toolchain)
- **Spring Boot 3.5.7**
- **Gradle** (Build tool)

### Key Dependencies
- **Web & Templates**
  - Spring Web (REST APIs)
  - Thymeleaf (Server-side rendering)
  - Spring Validation (Input validation)
  - Thymeleaf Spring Security extras

- **Data & Persistence**
  - Spring Data JPA (ORM)
  - Hibernate (JPA implementation)
  - MySQL (Production database)
  - H2 Database (Development/Testing)

- **Security**
  - Spring Security (Authentication & Authorization)
  - OAuth2 Client (Social login)
  - JWT (io.jsonwebtoken:jjwt 0.11.5) for token-based auth

- **Utilities**
  - Lombok (Boilerplate reduction)
  - Spring Boot DevTools (Hot reload)

- **Frontend Libraries** (Located in `src/main/resources/static/libs/`)
  - Bootstrap (UI framework)
  - jQuery (DOM manipulation)
  - ApexCharts (Data visualization)
  - Owl Carousel (Image carousels)
  - Magnific Popup (Lightbox)
  - And more...

---

## Architecture & Design Patterns

### Domain-Driven Design (DDD)
The project follows a **domain-driven architecture** with clear separation of concerns:

```
src/main/java/com/usedcar/trading/
├── domain/                  # Business domains
│   ├── admin/              # Admin management
│   ├── company/            # Dealership management
│   ├── employee/           # Employee management
│   ├── favorite/           # User favorites
│   ├── notification/       # Notification system
│   ├── report/             # Reporting system
│   ├── review/             # Customer reviews
│   ├── settlement/         # Financial settlements
│   ├── transaction/        # Purchase transactions
│   ├── user/               # User management
│   └── vehicle/            # Vehicle listings
└── global/                  # Cross-cutting concerns
    ├── audit/              # Auditing (BaseEntity)
    ├── auth/               # Authentication & Authorization
    ├── config/             # Application configuration
    ├── exception/          # Global exception handling
    └── home/               # Home page controller
```

### Layered Architecture Pattern
Each domain follows a consistent 4-layer structure:

```
domain/{name}/
├── controller/      # HTTP endpoints & request handling
├── dto/             # Data Transfer Objects (requests/responses)
├── entity/          # JPA entities (database models)
├── repository/      # Data access layer (Spring Data JPA)
└── service/         # Business logic layer
```

**Important:** Some simpler domains may not have all layers (e.g., missing `dto/` if entities are used directly)

### Key Design Patterns

1. **Repository Pattern**
   - All repositories extend `JpaRepository<Entity, ID>`
   - Located in `{domain}/repository/`
   - Example: `VehicleRepository extends JpaRepository<Vehicle, Long>`

2. **Service Layer Pattern**
   - Business logic encapsulated in service classes
   - Services are `@Service` annotated and use constructor injection
   - Example: `VehicleService`

3. **DTO Pattern**
   - Separate DTOs for requests (e.g., `VehicleRegisterRequest`)
   - Response DTOs (e.g., `UserResponse`)
   - Never expose entities directly in APIs

4. **Entity Auditing**
   - All entities extend `BaseEntity` for automatic timestamp management
   - `@CreatedDate` and `@LastModifiedDate` handled by JPA Auditing
   - Location: `global/audit/BaseEntity.java:1`

5. **Builder Pattern**
   - Entities use Lombok's `@Builder` for object construction
   - Example: `Vehicle.builder().brand("BMW").model("X5").build()`

6. **Enum Strategy**
   - Enums for status fields stored as `@Enumerated(EnumType.STRING)`
   - Examples: `VehicleStatus`, `TransactionStatus`, `Role`, `Provider`

---

## Directory Structure

### Source Code (`src/main/java/`)
```
com.usedcar.trading/
├── UsedCarTradingApplication.java    # Main application entry point (@EnableScheduling)
├── domain/                            # 10 business domains (see Architecture section)
└── global/                            # Shared infrastructure code
```

### Resources (`src/main/resources/`)
```
resources/
├── application-prod.properties        # Production configuration (MySQL)
├── application.properties             # GITIGNORED (local dev config)
├── static/                            # Static assets (CSS, JS, images, libraries)
│   ├── css/
│   ├── images/                        # Car images, icons, logos
│   ├── js/
│   └── libs/                          # Third-party libraries (Bootstrap, jQuery, etc.)
└── templates/                         # Thymeleaf HTML templates
    ├── admin/
    ├── company/
    ├── favorite/
    ├── fragments/                     # Reusable template fragments
    ├── mypage/
    ├── notification/
    ├── review/
    └── vehicle/
```

### Test Code (`src/test/java/`)
```
com.usedcar.trading/
└── UsedCarTradingApplicationTests.java
```

---

## Core Domain Models

### 1. User Domain (`domain/user/`)
**Entity:** `User`
- Primary roles: `ADMIN`, `CUSTOMER`, `COMPANY_OWNER`, `COMPANY_EMPLOYEE`
- Supports OAuth2 providers: `GOOGLE`, `KAKAO`, `NAVER`, `LOCAL`
- Status tracking: `UserStatus` enum (`ACTIVE`, `INACTIVE`, `BANNED`)

### 2. Vehicle Domain (`domain/vehicle/`)
**Entity:** `Vehicle` (extends `BaseEntity`)
- Key fields: `brand`, `model`, `modelYear`, `mileage`, `price`, `fuelType`, `transmission`
- Status workflow: `PENDING` → `SALE` → `RESERVED` → `SOLD` (or `REJECTED`, `DELETED`)
- Relationships:
  - `@ManyToOne` with `Company` (seller)
  - `@ManyToOne` with `Employee` (registeredBy)
  - `@ManyToOne` with `User` (approvedBy - admin)
  - `@OneToMany` with `VehicleImage` (cascade all)
  - `@OneToMany` with `Favorite`
  - `@OneToMany` with `Transaction`
- Business methods: `approve()`, `reject()`, `changeStatus()`, `increaseViewCount()`, `extendExpirationDate()`

**Entity:** `VehicleImage`
- Stores multiple images per vehicle
- Cascade delete when vehicle is removed

**Scheduler:** `VehicleScheduler`
- Automated tasks (check for implementation details in `domain/vehicle/scheduler/`)

### 3. Company Domain (`domain/company/`)
**Entity:** `Company`
- Business number (unique identifier)
- Status: `CompanyStatus` enum
- Relationships with `Employee` and `Vehicle`

### 4. Employee Domain (`domain/employee/`)
**Entity:** `Employee`
- Position hierarchy: `EmployeePosition` enum
- Linked to `Company` and `User`

### 5. Transaction Domain (`domain/transaction/`)
**Entity:** `Transaction`
- Status: `TransactionStatus` enum
- Links buyer (`User`), seller (`Company`), and `Vehicle`

### 6. Settlement Domain (`domain/settlement/`)
**Entity:** `Settlement`
- Status: `SettlementStatus` enum
- Financial reconciliation between platform and companies

### 7. Review Domain (`domain/review/`)
**Entity:** `Review`
- Customer feedback on transactions
- Rating system

### 8. Report Domain (`domain/report/`)
**Entity:** `Report`
- Type: `ReportType` enum
- Status: `ReportStatus` enum
- User-generated reports on vehicles, reviews, etc.

### 9. Favorite Domain (`domain/favorite/`)
**Entity:** `Favorite`
- Wishlist/bookmark system for customers

### 10. Notification Domain (`domain/notification/`)
**Entity:** `Notification`
- Type: `NotificationType` enum
- Real-time alerts to users

---

## Security & Authentication

### Security Configuration (`global/config/SecurityConfig.java:1`)

**Authentication Methods:**
1. Form-based login (`/login`)
   - Username parameter: `email`
   - Custom success handler: `CustomLoginSuccessHandler`
2. OAuth2 login (Google, Kakao, Naver)
   - Custom user service: `CustomOAuth2UserService`

**Authorization Rules:**
- **Public Access:** Static resources, home, search, vehicle listings, auth endpoints
- **Admin Only:** `/admin/**` (requires `ROLE_ADMIN`)
- **Company Owner Only:** `/company/employees/**`, `/company/settlements/**`
- **Seller (Owner + Employee):** `/company/sales/**`, vehicle registration/editing
- **Customer Only:** `/favorites/**`, `/reviews/write/**`, `/reports/write`
- **Authenticated Users:** `/mypage/**`, `/notifications/**`, `/transactions/**`

**CSRF:** Disabled (for development; reconsider for production)

**Password Encoding:** BCrypt

**Important Files:**
- `global/auth/security/PrincipalDetails.java` - UserDetails implementation
- `global/auth/service/CustomOAuth2UserService.java` - OAuth2 integration
- `global/auth/handler/CustomLoginSuccessHandler.java` - Post-login redirect logic

### JWT Token Configuration
- Secret key: Configured in `application.properties` (JWT_SECRET)
- Expiration: 86400000ms (24 hours)
- Implementation: `io.jsonwebtoken:jjwt` library

---

## Exception Handling

### Global Exception Strategy
**Location:** `global/exception/`

**Components:**
1. **ErrorCode** (`ErrorCode.java:1`) - Enum with HTTP status, error code, message
   - Format: `{DOMAIN}_{NUMBER}` (e.g., `USER_001`, `VEHICLE_001`)
   - Categories: 400 (Bad Request), 401 (Unauthorized), 403 (Forbidden), 404 (Not Found), 409 (Conflict), 500 (Server Error)

2. **CustomException** - Base exception class wrapping `ErrorCode`

3. **ErrorResponse** - Standardized error response DTO

4. **GlobalExceptionHandler** - `@RestControllerAdvice` for centralized exception handling

**Usage Pattern:**
```java
if (vehicle == null) {
    throw new CustomException(ErrorCode.VEHICLE_NOT_FOUND);
}
```

---

## Database Configuration

### Development Environment
- **Database:** H2 (in-memory)
- **JPA DDL:** `create-drop` or `update`
- **Configuration:** `src/main/resources/application.properties` (GITIGNORED)

### Production Environment (`application-prod.properties:1`)
- **Database:** MySQL 8.0
- **URL:** `jdbc:mysql://localhost:3306/trading_db`
- **Dialect:** MySQL8Dialect
- **JPA DDL:** `validate` (no auto schema changes)
- **Timezone:** Asia/Seoul
- **Credentials:** Must be configured before deployment

**Important:** `application.properties` is gitignored for security. Copy from `application-prod.properties` and adjust for local development.

---

## Coding Conventions

### Entity Design
1. **Always extend `BaseEntity`** for automatic `createdAt` and `updatedAt` fields
2. Use **Lombok annotations:**
   - `@Entity`, `@Getter` (avoid `@Setter`)
   - `@NoArgsConstructor(access = AccessLevel.PROTECTED)` for JPA
   - `@AllArgsConstructor` and `@Builder` for construction
3. **Enums stored as STRING:** `@Enumerated(EnumType.STRING)` to avoid ordinal issues
4. **Relationship mappings:**
   - Use `FetchType.LAZY` by default
   - Define `cascade` and `orphanRemoval` explicitly
   - Add convenience methods for bidirectional relationships (e.g., `addImage()`, `removeImage()`)
5. **Business logic in entities:** Domain methods like `approve()`, `reject()`, etc.

### Service Layer
1. **Constructor injection only** (via Lombok `@RequiredArgsConstructor`)
2. **Transactional boundaries:** Use `@Transactional` appropriately
3. **Validation:** Handle business rule validation before persistence

### Controller Design
1. **Separate UI and API controllers:**
   - UI: Returns Thymeleaf view names (`String`)
   - API: Returns DTOs with `@RestController`
2. **Use DTOs for input/output:** Never expose entities directly
3. **Validation:** Use `@Valid` with DTO classes annotated with Jakarta Validation constraints

### Naming Conventions
- **Entities:** Singular nouns (e.g., `Vehicle`, `User`)
- **Repositories:** `{Entity}Repository` (e.g., `VehicleRepository`)
- **Services:** `{Entity}Service` (e.g., `VehicleService`)
- **Controllers:** `{Entity}Controller` or `{Entity}ApiController`
- **DTOs:** `{Entity}{Action}Request/Response` (e.g., `VehicleRegisterRequest`)

### Code Comments
- **Korean comments allowed** (project uses Korean for business domain terms)
- Document complex business logic
- Avoid obvious comments

---

## Development Workflow

### Build & Run
```bash
# Build project
./gradlew build

# Run application
./gradlew bootRun

# Run tests
./gradlew test

# Clean build
./gradlew clean build
```

### Database Initialization
- **DataInit.java** (`global/config/DataInit.java:1`) - Handles initial data seeding
- Check this file for sample data setup during development

### Scheduled Tasks
- **@EnableScheduling** enabled in main application class
- Scheduler example: `VehicleScheduler` in `domain/vehicle/scheduler/`

### Hot Reload
- Spring Boot DevTools included for automatic restart on code changes

---

## Testing Strategy

### Test Structure
- **Location:** `src/test/java/com/usedcar/trading/`
- **Base Test:** `UsedCarTradingApplicationTests.java`

### Testing Dependencies
- JUnit 5 (JUnit Platform Launcher)
- Spring Boot Starter Test
- Spring Security Test

**Note:** Expand test coverage by adding unit tests for services and integration tests for controllers.

---

## Common Tasks for AI Assistants

### 1. Adding a New Domain
When creating a new domain (e.g., "payment"):
```
1. Create directory: domain/payment/
2. Add layers: controller/, dto/, entity/, repository/, service/
3. Create entity extending BaseEntity
4. Create repository extending JpaRepository
5. Create service with @Service and @RequiredArgsConstructor
6. Create controller with @Controller or @RestController
7. Add error codes to ErrorCode enum
8. Update SecurityConfig if new endpoints need authorization
```

### 2. Adding a New Entity Field
```
1. Add field to entity class
2. Update builder if using @Builder
3. Add getter (Lombok handles this)
4. Add business methods if field affects domain logic
5. Update related DTOs
6. Consider database migration (in production use ddl-auto=validate)
```

### 3. Adding a New Enum Status
```
1. Create enum in domain/entity/ package
2. Use @Enumerated(EnumType.STRING) in entity
3. Add validation in service layer
4. Add error codes for invalid transitions
5. Document valid state transitions in comments
```

### 4. Adding Security Rules
Edit `SecurityConfig.java:24`:
```java
.requestMatchers("/new-path/**").hasRole("ROLE_NAME")
```

### 5. Adding Custom Exceptions
```
1. Add new error code to ErrorCode enum
2. Throw CustomException in service layer:
   throw new CustomException(ErrorCode.YOUR_ERROR);
3. GlobalExceptionHandler will automatically format response
```

### 6. Working with Relationships
```
1. Define mapping in entity (@ManyToOne, @OneToMany, etc.)
2. Set FetchType.LAZY to avoid N+1 queries
3. Add convenience methods for bidirectional relationships
4. Use @JsonIgnore or DTOs to prevent circular serialization
5. Configure cascade operations carefully
```

---

## File Locations Quick Reference

| Component | Location |
|-----------|----------|
| Main Application | `src/main/java/com/usedcar/trading/UsedCarTradingApplication.java:1` |
| Base Entity | `src/main/java/com/usedcar/trading/global/audit/BaseEntity.java:1` |
| Security Config | `src/main/java/com/usedcar/trading/global/config/SecurityConfig.java:1` |
| Error Codes | `src/main/java/com/usedcar/trading/global/exception/ErrorCode.java:1` |
| Exception Handler | `src/main/java/com/usedcar/trading/global/exception/GlobalExceptionHandler.java` |
| Data Initialization | `src/main/java/com/usedcar/trading/global/config/DataInit.java:1` |
| JPA Config | `src/main/java/com/usedcar/trading/global/config/JpaConfig.java` |
| Vehicle Entity | `src/main/java/com/usedcar/trading/domain/vehicle/entity/Vehicle.java:1` |
| Build Config | `build.gradle:1` |
| Prod DB Config | `src/main/resources/application-prod.properties:1` |
| Templates | `src/main/resources/templates/` |
| Static Assets | `src/main/resources/static/` |

---

## Important Notes for AI Assistants

### Do's ✅
1. **Always read entities** before modifying to understand relationships
2. **Follow the layered architecture** - keep business logic in services
3. **Use DTOs** for API requests/responses
4. **Extend BaseEntity** for new entities
5. **Add proper error codes** for new exceptions
6. **Use constructor injection** with Lombok
7. **Follow existing naming conventions**
8. **Add Korean comments** if business logic is complex
9. **Test security rules** when adding new endpoints
10. **Use @Transactional** for multi-step operations

### Don'ts ❌
1. **Don't expose entities directly** in REST APIs
2. **Don't use field injection** (@Autowired on fields)
3. **Don't use EnumType.ORDINAL** - always use STRING
4. **Don't modify BaseEntity** unless absolutely necessary
5. **Don't hard-code configuration** - use application.properties
6. **Don't commit application.properties** (it's gitignored)
7. **Don't skip validation** in service layer
8. **Don't use FetchType.EAGER** without good reason
9. **Don't add unnecessary dependencies** to build.gradle
10. **Don't create circular dependencies** between domains

### Security Considerations 🔒
1. **Password encoding:** Always use BCrypt via `passwordEncoder` bean
2. **SQL Injection:** Use JPA parameter binding (automatically handled)
3. **XSS:** Thymeleaf escapes by default; be careful with `th:utext`
4. **CSRF:** Currently disabled; re-enable for production
5. **Secrets:** JWT secret and DB passwords must be externalized
6. **Role checks:** Always verify user roles in service layer for critical operations

---

## Git Workflow

### Ignored Files (`.gitignore:1`)
- Build artifacts: `.gradle/`, `build/`, `out/`, `bin/`
- IDE files: `.idea/`, `*.iml`, `.sts4-cache/`
- Database files: `*.mv.db`, `*.trace.db`
- **Security:** `src/main/resources/application.properties` (CRITICAL)

### Branch Strategy
- Follow the branch naming in the current context
- Create feature branches from main/master
- Use descriptive commit messages

---

## Performance Considerations

1. **N+1 Query Prevention:**
   - Use `@EntityGraph` or JOIN FETCH in repositories
   - Prefer LAZY loading and load associations explicitly

2. **Database Indexing:**
   - Add indexes on frequently queried fields (email, business number, status)
   - Consider composite indexes for complex queries

3. **Caching:**
   - Consider Spring Cache for frequently accessed reference data
   - Not currently implemented - evaluate need

4. **Pagination:**
   - Use Spring Data Pageable for large result sets
   - Implement in repository methods returning `Page<Entity>`

---

## Questions to Ask Before Making Changes

1. **New Feature:** Which domain does this belong to? Should it be a new domain?
2. **Database Change:** Will this affect production data? Need migration?
3. **Security Change:** Who should have access? Update SecurityConfig?
4. **API Change:** Is this a breaking change? Do we need versioning?
5. **Performance:** Will this cause N+1 queries? Should we add indexes?
6. **Testing:** Do we need new test cases? Integration or unit tests?

---

## Useful Commands

```bash
# Find all controllers
find src -name "*Controller.java"

# Find all entities
find src -name "*.java" -path "*/entity/*"

# Count lines of code
find src -name "*.java" | xargs wc -l

# Search for specific annotation
grep -r "@Transactional" src/

# Find all repositories
find src -name "*Repository.java"

# Check for security annotations
grep -r "@PreAuthorize\|@Secured" src/
```

---

## Additional Resources

- **Spring Boot Documentation:** https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/
- **Spring Data JPA:** https://docs.spring.io/spring-data/jpa/docs/current/reference/html/
- **Spring Security:** https://docs.spring.io/spring-security/reference/
- **Thymeleaf:** https://www.thymeleaf.org/documentation.html
- **Lombok:** https://projectlombok.org/features/

---

**Last Updated:** 2025-12-06
**Version:** 1.0.0
**Maintained By:** AI Assistant (Claude)
