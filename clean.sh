#!/bin/bash
#===============================================================================
# 정리 스크립트
# 목적: 작업 중 생성된 임시 파일 및 디렉토리를 정리합니다.
#===============================================================================

# 공통 설정 파일 로드
source ./00_config.sh

#-------------------------------------------------------------------------------
# 로그 설정
#-------------------------------------------------------------------------------
LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/clean_$(date +%Y%m%d_%H%M%S).log"

# 로그 디렉토리 생성
mkdir -p "${LOG_DIR}"

# 로그 함수 정의
log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "${message}" | tee -a "${2:-$LOG_FILE}"
}

#-------------------------------------------------------------------------------
# 정리 작업 시작
#-------------------------------------------------------------------------------
log "청소 시작..."

# 삭제할 항목 목록
ITEMS_TO_CLEAN=(
    "extracted_*"       # 추출된 JAR 디렉토리
    "backups_*"         # 백업 디렉토리
    "$APP_NAME"         # 앱 디렉토리
    "$DMG_NAME"         # DMG 파일
    "dmg_temp"          # DMG 임시 디렉토리
    "temp_work_dir*"    # 임시 작업 디렉토리
)

# 각 항목 삭제
for pattern in "${ITEMS_TO_CLEAN[@]}"; do
    log "패턴 '$pattern'에 해당하는 항목 삭제 중..."
    
    # 디렉토리인 경우
    if [[ "$pattern" == *"*" ]]; then
        # 와일드카드 패턴 처리
        for item in $pattern; do
            if [ -e "$item" ]; then
                log "삭제 중: $item"
                rm -rf "$item"
            fi
        done
    else
        # 단일 항목 처리
        if [ -e "$pattern" ]; then
            log "삭제 중: $pattern"
            rm -rf "$pattern"
        fi
    fi
done

#-------------------------------------------------------------------------------
# 정리 결과 확인
#-------------------------------------------------------------------------------
log "청소 완료"
log "삭제 확인:"

# extracted* 디렉토리 확인
remaining_extracted=$(find . -maxdepth 1 -type d -name "extracted_*" | wc -l)
if [ "$remaining_extracted" -eq 0 ]; then
    log "  → 모든 extracted 디렉토리가 삭제됨"
else
    log "  → 경고: 일부 extracted 디렉토리가 남아있음 ($remaining_extracted 개)"
fi

# backups* 디렉토리 확인
remaining_backups=$(find . -maxdepth 1 -type d -name "backups_*" | wc -l)
if [ "$remaining_backups" -eq 0 ]; then
    log "  → 모든 backups 디렉토리가 삭제됨"
else
    log "  → 경고: 일부 backups 디렉토리가 남아있음 ($remaining_backups 개)"
fi

# 임시 작업 디렉토리 확인
remaining_temp=$(find . -maxdepth 1 -type d -name "temp_work_dir*" | wc -l)
if [ "$remaining_temp" -eq 0 ]; then
    log "  → 모든 임시 작업 디렉토리가 삭제됨"
else
    log "  → 경고: 일부 임시 작업 디렉토리가 남아있음 ($remaining_temp 개)"
fi

# 앱 및 DMG 파일 확인
log "  → 앱 디렉토리: $([ -d "$APP_NAME" ] && echo "여전히 존재함" || echo "삭제됨")"
log "  → DMG 파일: $([ -f "$DMG_NAME" ] && echo "여전히 존재함" || echo "삭제됨")"
log "  → DMG 임시 디렉토리: $([ -d "dmg_temp" ] && echo "여전히 존재함" || echo "삭제됨")"

log "정리 작업 완료"
exit 0
