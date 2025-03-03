#!/bin/bash
#===============================================================================
# JAR 파일 압축 해제 스크립트
# 목적: 서명이 필요한 네이티브 라이브러리가 포함된 JAR 파일들을 압축 해제합니다.
#===============================================================================

# 공통 설정 파일 로드
source ./00_config.sh

#-------------------------------------------------------------------------------
# JAR 파일 압축 해제 함수
#-------------------------------------------------------------------------------
unzip_jar() {
    local JAR_PATH="$1"
    local EXTRACT_DIR="$2"
    
    echo "압축 해제 중: $JAR_PATH -> $EXTRACT_DIR"
    
    # JAR 파일 존재 여부 확인
    if [ ! -f "$JAR_PATH" ]; then
        echo "오류: JAR 파일이 존재하지 않습니다: $JAR_PATH"
        return 1
    fi
    
    # 이미 존재하는 경우 디렉토리 삭제
    if [ -d "$EXTRACT_DIR" ]; then
        echo "기존 디렉토리 삭제 중: $EXTRACT_DIR"
        rm -rf "$EXTRACT_DIR"
    fi
    
    # 디렉토리 생성 및 JAR 압축 해제
    mkdir -p "$EXTRACT_DIR"
    if ! unzip -q "$JAR_PATH" -d "$EXTRACT_DIR"; then
        echo "오류: JAR 파일 압축 해제 실패: $JAR_PATH"
        return 1
    fi
    
    echo "압축 해제 완료: $JAR_PATH"
    return 0
}

#-------------------------------------------------------------------------------
# 메인 실행 부분
#-------------------------------------------------------------------------------
echo "JAR 파일 압축 해제 시작..."

# 모든 JAR 파일 압축 해제
SUCCESS=true
for i in "${!JAR_PATHS[@]}"; do
    jar_path="${JAR_PATHS[$i]}"
    extract_dir="${EXTRACT_DIRS[$i]}"
    
    if ! unzip_jar "$jar_path" "$extract_dir"; then
        echo "경고: $jar_path 압축 해제 중 오류 발생"
        SUCCESS=false
    fi
    echo "--------------------------------"
done

# 결과 출력
if [ "$SUCCESS" = true ]; then
    echo "모든 JAR 파일 압축 해제 완료"
    exit 0
else
    echo "일부 JAR 파일 압축 해제 실패"
    exit 1
fi
