#!/bin/bash

###############################################################################
# Used Car Trading Platform - AWS Deployment Script
# 이 스크립트는 로컬에서 빌드하고 EC2 인스턴스에 배포합니다.
###############################################################################

set -e  # 오류 발생시 스크립트 중단

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 설정 (실제 값으로 변경하세요!)
EC2_USER="ec2-user"                                    # Ubuntu 사용시: ubuntu
EC2_HOST="your-ec2-ip-or-domain.com"                  # EC2 퍼블릭 IP 또는 도메인
KEY_PATH="~/.ssh/aws-keys/trading-app-key.pem"       # SSH 키 파일 경로
APP_DIR="/opt/trading-app"                            # EC2의 애플리케이션 디렉토리
JAR_NAME="app.jar"                                     # EC2에 저장될 JAR 파일명
BUILD_JAR="build/libs/trading-0.0.1-SNAPSHOT.jar"     # 로컬 빌드 파일 경로

###############################################################################
# 함수 정의
###############################################################################

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_config() {
    if [ "$EC2_HOST" == "your-ec2-ip-or-domain.com" ]; then
        print_error "EC2_HOST를 실제 값으로 설정해주세요!"
        echo "deploy.sh 파일을 열어서 EC2_HOST, KEY_PATH 등을 수정하세요."
        exit 1
    fi

    if [ ! -f "${KEY_PATH/#\~/$HOME}" ]; then
        print_error "SSH 키 파일을 찾을 수 없습니다: $KEY_PATH"
        exit 1
    fi
}

build_application() {
    print_header "1. 애플리케이션 빌드"

    print_info "Gradle 빌드를 시작합니다..."
    ./gradlew clean build -x test

    if [ $? -ne 0 ]; then
        print_error "빌드 실패!"
        exit 1
    fi

    if [ ! -f "$BUILD_JAR" ]; then
        print_error "JAR 파일을 찾을 수 없습니다: $BUILD_JAR"
        exit 1
    fi

    JAR_SIZE=$(ls -lh $BUILD_JAR | awk '{print $5}')
    print_success "빌드 완료! (파일 크기: $JAR_SIZE)"
}

backup_current_jar() {
    print_header "2. 현재 JAR 파일 백업"

    print_info "EC2의 현재 JAR 파일을 백업합니다..."
    ssh -i "${KEY_PATH/#\~/$HOME}" $EC2_USER@$EC2_HOST << ENDSSH
        if [ -f $APP_DIR/$JAR_NAME ]; then
            BACKUP_NAME=\$(date +"%Y%m%d_%H%M%S")_app.jar
            cp $APP_DIR/$JAR_NAME $APP_DIR/backups/\$BACKUP_NAME 2>/dev/null || mkdir -p $APP_DIR/backups && cp $APP_DIR/$JAR_NAME $APP_DIR/backups/\$BACKUP_NAME
            echo "백업 파일: \$BACKUP_NAME"
        else
            echo "백업할 파일이 없습니다 (첫 배포)"
        fi
ENDSSH

    print_success "백업 완료"
}

upload_jar() {
    print_header "3. JAR 파일 업로드"

    print_info "EC2로 JAR 파일을 전송합니다..."
    scp -i "${KEY_PATH/#\~/$HOME}" \
        $BUILD_JAR \
        $EC2_USER@$EC2_HOST:$APP_DIR/$JAR_NAME

    if [ $? -ne 0 ]; then
        print_error "파일 전송 실패!"
        exit 1
    fi

    print_success "파일 업로드 완료"
}

restart_application() {
    print_header "4. 애플리케이션 재시작"

    print_info "Spring Boot 애플리케이션을 재시작합니다..."
    ssh -i "${KEY_PATH/#\~/$HOME}" $EC2_USER@$EC2_HOST << 'ENDSSH'
        # 서비스 재시작
        sudo systemctl restart trading-app

        # 잠시 대기
        echo "애플리케이션 시작을 기다리는 중..."
        sleep 5

        # 상태 확인
        if sudo systemctl is-active --quiet trading-app; then
            echo "✅ 애플리케이션이 정상적으로 실행 중입니다"
            sudo systemctl status trading-app --no-pager | head -10
        else
            echo "❌ 애플리케이션 시작 실패!"
            sudo journalctl -u trading-app -n 50 --no-pager
            exit 1
        fi
ENDSSH

    if [ $? -ne 0 ]; then
        print_error "애플리케이션 재시작 실패!"
        print_warning "롤백하려면 다음 명령을 실행하세요:"
        echo "ssh -i ${KEY_PATH/#\~/$HOME} $EC2_USER@$EC2_HOST 'cd $APP_DIR && ./rollback.sh'"
        exit 1
    fi

    print_success "애플리케이션 재시작 완료"
}

health_check() {
    print_header "5. 헬스 체크"

    print_info "애플리케이션 상태를 확인합니다..."

    # 최대 30초 대기
    MAX_RETRY=6
    RETRY_COUNT=0

    while [ $RETRY_COUNT -lt $MAX_RETRY ]; do
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$EC2_HOST/actuator/health 2>/dev/null || echo "000")

        if [ "$HTTP_CODE" == "200" ]; then
            print_success "헬스 체크 통과! (HTTP $HTTP_CODE)"
            return 0
        else
            RETRY_COUNT=$((RETRY_COUNT+1))
            print_warning "재시도 중... ($RETRY_COUNT/$MAX_RETRY)"
            sleep 5
        fi
    done

    print_warning "헬스 체크를 건너뜁니다 (actuator가 비활성화되어 있을 수 있습니다)"
    print_info "수동으로 확인하세요: http://$EC2_HOST"
}

show_logs() {
    print_header "6. 최근 로그 확인"

    print_info "최근 애플리케이션 로그를 표시합니다..."
    ssh -i "${KEY_PATH/#\~/$HOME}" $EC2_USER@$EC2_HOST << 'ENDSSH'
        sudo journalctl -u trading-app -n 20 --no-pager
ENDSSH
}

deployment_summary() {
    print_header "배포 완료!"

    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_success "배포가 성공적으로 완료되었습니다!"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    echo "📋 배포 정보:"
    echo "  - 서버: $EC2_HOST"
    echo "  - 사용자: $EC2_USER"
    echo "  - 애플리케이션 경로: $APP_DIR"
    echo ""
    echo "🔗 접속 정보:"
    echo "  - HTTP:  http://$EC2_HOST"
    echo "  - HTTPS: https://$EC2_HOST (SSL 설정된 경우)"
    echo ""
    echo "📊 유용한 명령어:"
    echo "  - 로그 실시간 확인:"
    echo "    ssh -i ${KEY_PATH/#\~/$HOME} $EC2_USER@$EC2_HOST 'sudo journalctl -u trading-app -f'"
    echo ""
    echo "  - 서비스 상태 확인:"
    echo "    ssh -i ${KEY_PATH/#\~/$HOME} $EC2_USER@$EC2_HOST 'sudo systemctl status trading-app'"
    echo ""
    echo "  - 애플리케이션 재시작:"
    echo "    ssh -i ${KEY_PATH/#\~/$HOME} $EC2_USER@$EC2_HOST 'sudo systemctl restart trading-app'"
    echo ""
    echo "  - 롤백 (이전 버전으로):"
    echo "    ssh -i ${KEY_PATH/#\~/$HOME} $EC2_USER@$EC2_HOST 'cd $APP_DIR && ./rollback.sh'"
    echo ""
}

###############################################################################
# 메인 실행
###############################################################################

main() {
    print_header "Used Car Trading Platform - 배포 시작"

    # 설정 확인
    check_config

    # 배포 프로세스
    build_application
    backup_current_jar
    upload_jar
    restart_application
    health_check
    show_logs
    deployment_summary
}

# 스크립트 실행
main
