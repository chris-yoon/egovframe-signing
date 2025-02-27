#!/bin/bash

# 공통 설정 파일 로드
source ./00_config.sh

# 서명할 디렉토리 (추출된 JAR 파일의 루트 디렉토리)
EXTRACTED_DIR="$1"

# 디렉토리가 제공되지 않았을 경우 사용법 출력 후 종료
if [ -z "$EXTRACTED_DIR" ]; then
    echo "사용법: $0 <추출된_JAR_디렉토리>"
    echo "예: $0 extracted_jna_5.8.0"
    exit 1
fi

# 디렉토리가 존재하는지 확인
if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "오류: '$EXTRACTED_DIR' 디렉토리가 존재하지 않습니다."
    exit 1
fi

# .jnilib와 .dylib 파일을 찾아 서명
echo "네이티브 라이브러리(.jnilib, .dylib)를 검색하고 서명합니다..."
find "$EXTRACTED_DIR" -type f \( -name "*.jnilib" -o -name "*.dylib" \) | while read -r file; do
    echo "서명 중: $file"
    
    # 서명 수행 (강제로 덮어쓰기, 타임스탬프 포함)
    codesign --force --timestamp --options=runtime --sign "$DEVELOPER_ID" "$file"
    
    # 서명 결과 확인
    if [ $? -eq 0 ]; then
        echo "  서명 성공: $file"
    else
        echo "  서명 실패: $file"
        exit 1
    fi
done

echo "모든 네이티브 라이브러리 서명 완료"
