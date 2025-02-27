#!/bin/bash

# 공통 설정 파일 로드
source ./00_config.sh

# JAR 파일 압축 해제 함수
unzip_jar() {
    local JAR_PATH="$1"
    local EXTRACT_DIR="$2"
    
    echo "압축 해제 중: $JAR_PATH -> $EXTRACT_DIR"
    
    # 이미 존재하는 경우 디렉토리 삭제
    if [ -d "$EXTRACT_DIR" ]; then
        rm -rf "$EXTRACT_DIR"
    fi
    
    # 디렉토리 생성 및 JAR 압축 해제
    mkdir -p "$EXTRACT_DIR"
    unzip -q "$JAR_PATH" -d "$EXTRACT_DIR"
    
    echo "압축 해제 완료: $JAR_PATH"
}

# 모든 JAR 파일 압축 해제
echo "JAR 파일 압축 해제 시작..."

# 연관 배열 대신 일반 배열 사용
for i in "${!JAR_PATHS[@]}"; do
    jar_path="${JAR_PATHS[$i]}"
    extract_dir="${EXTRACT_DIRS[$i]}"
    unzip_jar "$jar_path" "$extract_dir"
done

echo "모든 JAR 파일 압축 해제 완료"
