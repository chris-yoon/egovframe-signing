#!/bin/bash

# 공통 설정 파일 로드
source ./00_config.sh

# 사용법 출력 함수
usage() {
    echo "사용법: $0 [옵션]"
    echo "옵션:"
    echo "  --sign-only     앱 서명까지만 실행"
    echo "  --with-dmg      DMG 생성까지 실행"
    echo "  --full          노타리까지 모두 실행 (기본값)"
    exit 1
}

# 옵션 파싱
MODE="full"
case "$1" in
    --sign-only)
        MODE="sign"
        ;;
    --with-dmg)
        MODE="dmg"
        ;;
    --full|"")
        MODE="full"
        ;;
    --help|-h)
        usage
        ;;
    *)
        echo "알 수 없는 옵션: $1"
        usage
        ;;
esac

# 로그 파일 설정
LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/run_$(date +%Y%m%d_%H%M%S).log"

# 로그 디렉토리 생성
mkdir -p ${LOG_DIR}

# 로그 함수 정의
log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "${message}" | tee -a "${LOG_FILE}"
}

log "스크립트 실행 시작 (모드: $MODE)"
log "로그 파일: ${LOG_FILE}"

# 서명할 필요있는 네이티브 라이브러리가 포함된 JAR 파일 압축 해제
./01_extract_jars.sh | tee -a "${LOG_FILE}"

# JAR 내 네이티브 라이브러리 서명
for dir in "${EXTRACTED_DIRS[@]}"; do
    ./02_sign_native_libraries.sh "$dir" | tee -a "${LOG_FILE}"
done

# JAR 내 네이티브 라이브러리 재패키징
for i in "${!JAR_PATHS[@]}"; do
    jar_path="${JAR_PATHS[$i]}"
    extract_dir="${EXTRACT_DIRS[$i]}"
    ./03_repackage_jars.sh "$jar_path" "$extract_dir" | tee -a "${LOG_FILE}"
done

# 중첩 JAR(JAR내의 JAR)내 네이티브 라이브러리 서명
log "중첩 JAR 내 네이티브 라이브러리 서명 시작..."

for i in "${!OUTER_JARS[@]}"; do
    log "개별 중첩 JAR 처리: ${OUTER_JARS[$i]} -> ${INNER_JAR_PATHS[$i]}"
    ./04_sign_nested_jars.sh "${OUTER_JARS[$i]}" "${INNER_JAR_PATHS[$i]}" | tee -a "${LOG_FILE}"
done

# 앱 서명 (--options=runtime 추가, --deep 제거)
log "앱 서명 중..."
codesign --force --verify --verbose --timestamp --options=runtime --entitlements ./entitlements.plist -i "$APP_BUNDLE_ID" --sign "$DEVELOPER_ID" "$APP_NAME" | tee -a "${LOG_FILE}"

if [ "$MODE" = "sign" ]; then
    log "앱 서명까지 완료되었습니다."
    exit 0
fi

# DMG 생성
./05_create_dmg.sh | tee -a "${LOG_FILE}"

if [ "$MODE" = "dmg" ]; then
    log "DMG 생성까지 완료되었습니다."
    exit 0
fi

NOTARY_OUTPUT_FILE="${LOG_DIR}/notary_output_$(date +%Y%m%d_%H%M%S).log"

# 노타리 제출
log "노타리 제출 중..."
xcrun notarytool submit "$DMG_NAME" --apple-id "$APPLE_ID" --password "$APPLE_PASSWORD" --team-id "$TEAM_ID" --wait | tee ${NOTARY_OUTPUT_FILE}

# 노타리 출력에서 Submission ID 추출
SUBMISSION_ID=$(grep -o "id: [a-zA-Z0-9\-]*" ${NOTARY_OUTPUT_FILE} | head -1 | cut -d' ' -f2)
if [ -n "$SUBMISSION_ID" ]; then
    log "Submission ID: $SUBMISSION_ID"
    
    # 노타리 상태 확인
    STATUS=$(grep -o "status: [a-zA-Z]*" ${NOTARY_OUTPUT_FILE} | cut -d' ' -f2)
    log "노타리 상태: $STATUS"

    # 상태가 Invalid인 경우 로그 확인
    if [ "$STATUS" = "Invalid" ]; then
        log "노타리 상태가 Invalid입니다. 상세 로그를 확인합니다..."
        log "-------- 노타리 로그 시작 --------"
        xcrun notarytool log --apple-id "$APPLE_ID" --password "$APPLE_PASSWORD" --team-id "$TEAM_ID" "$SUBMISSION_ID" | tee -a "${LOG_FILE}"
        log "-------- 노타리 로그 종료 --------"
        
        # 실패 메시지 출력
        log "노타리 검증에 실패했습니다. 위의 로그를 확인하여 문제를 해결하세요."
        exit 1
    elif [ "$STATUS" = "Accepted" ]; then
        log "노타리 검증이 성공적으로 완료되었습니다."
    else
        log "노타리 상태가 '$STATUS'입니다. 필요한 경우 다음 명령으로 로그를 확인하세요:"
        log "xcrun notarytool log --apple-id \"$APPLE_ID\" --password \"$APPLE_PASSWORD\" --team-id \"$TEAM_ID\" \"$SUBMISSION_ID\""
    fi
else
    log "Submission ID를 추출할 수 없습니다."
fi

log "스크립트 실행 완료"

