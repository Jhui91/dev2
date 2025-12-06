#!/bin/bash

###############################################################################
# Rollback Script - EC2에서 실행
# 이전 버전의 JAR 파일로 롤백합니다.
###############################################################################

set -e

APP_DIR="/opt/trading-app"
BACKUP_DIR="$APP_DIR/backups"
CURRENT_JAR="$APP_DIR/app.jar"

echo "🔄 롤백을 시작합니다..."

# 백업 파일 목록 확인
if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR)" ]; then
    echo "❌ 백업 파일이 없습니다!"
    exit 1
fi

# 가장 최근 백업 파일 찾기
LATEST_BACKUP=$(ls -t $BACKUP_DIR/*.jar | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "❌ 백업 JAR 파일을 찾을 수 없습니다!"
    exit 1
fi

echo "📦 롤백할 파일: $(basename $LATEST_BACKUP)"

# 현재 파일 백업 (롤백 실패에 대비)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TEMP_BACKUP="$BACKUP_DIR/rollback_before_${TIMESTAMP}_app.jar"
cp $CURRENT_JAR $TEMP_BACKUP
echo "✅ 현재 파일 임시 백업: $(basename $TEMP_BACKUP)"

# 이전 버전으로 복원
cp $LATEST_BACKUP $CURRENT_JAR
echo "✅ JAR 파일 복원 완료"

# 서비스 재시작
echo "🔄 서비스 재시작 중..."
sudo systemctl restart trading-app

# 상태 확인
sleep 5
if sudo systemctl is-active --quiet trading-app; then
    echo "✅ 롤백 성공! 애플리케이션이 정상 작동 중입니다."
    sudo systemctl status trading-app --no-pager | head -10
else
    echo "❌ 롤백 후 애플리케이션 시작 실패!"
    echo "임시 백업에서 복원을 시도합니다..."
    cp $TEMP_BACKUP $CURRENT_JAR
    sudo systemctl restart trading-app
    exit 1
fi

echo ""
echo "📋 백업 파일 목록:"
ls -lht $BACKUP_DIR/*.jar | head -5
