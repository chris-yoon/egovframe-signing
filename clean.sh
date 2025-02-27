#!/bin/bash

# 공통 설정 파일 로드
source ./00_config.sh

# 로그 파일 설정
LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/clean_$(date +%Y%m%d_%H%M%S).log"

# 로그 디렉토리 생성
mkdir -p "${LOG_DIR}"

# 로그 함수 정의
log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "${message}" | tee -a "${2:-$LOG_FILE}"
}

# 삭제할 파일/디렉토리 목록
log "청소 시작..."

# extracted* 디렉토리 삭제
log "extracted 디렉토리 삭제 중..."
find . -type d -name "extracted*" -exec rm -rf {} +

# backups* 디렉토리 삭제
log "backups 디렉토리 삭제 중..."
find . -type d -name "backups*" -exec rm -rf {} +

# .app 파일 삭제
if [ -d "$APP_NAME" ]; then
    log "앱 디렉토리 삭제 중: $APP_NAME"
    rm -rf "$APP_NAME"
fi

# .dmg 파일 삭제
if [ -f "$DMG_NAME" ]; then
    log "DMG 파일 삭제 중: $DMG_NAME"
    rm -f "$DMG_NAME"
fi

log "청소 완료"

# 삭제된 항목 확인
log "삭제 확인:"
log "- extracted* 디렉토리가 남아있는지 확인..."
remaining_extracted=$(find . -type d -name "extracted*" | wc -l)
if [ "$remaining_extracted" -eq 0 ]; then
    log "  → 모든 extracted 디렉토리가 삭제됨"
else
    log "  → 경고: 일부 extracted 디렉토리가 남아있음"
fi

log "- backups* 디렉토리가 남아있는지 확인..."
remaining_backups=$(find . -type d -name "backups*" | wc -l)
if [ "$remaining_backups" -eq 0 ]; then
    log "  → 모든 backups 디렉토리가 삭제됨"
else
    log "  → 경고: 일부 backups 디렉토리가 남아있음"
fi

log "- .app 파일 확인: $([ -d "$APP_NAME" ] && echo "여전히 존재함" || echo "삭제됨")"
log "- .dmg 파일 확인: $([ -f "$DMG_NAME" ] && echo "여전히 존재함" || echo "삭제됨")"
log "- dmg_temp 디렉토리 확인: $([ -d "dmg_temp" ] && echo "여전히 존재함" || echo "삭제됨")"
