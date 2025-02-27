#!/bin/bash

# 원본 JAR 파일 경로
ORIGINAL_JAR="$1"
# 추출된 디렉토리 경로
EXTRACTED_DIR="$2"

# 인자가 충분히 제공되지 않았을 경우 사용법 출력 후 종료
if [ -z "$ORIGINAL_JAR" ] || [ -z "$EXTRACTED_DIR" ]; then
    echo "사용법: $0 <원본_JAR_파일> <추출된_디렉토리>"
    echo "예: $0 jna-5.8.0.jar extracted_jna_5.8.0"
    exit 1
fi

# 원본 JAR 파일이 존재하는지 확인
if [ ! -f "$ORIGINAL_JAR" ]; then
    echo "오류: '$ORIGINAL_JAR' 파일이 존재하지 않습니다."
    exit 1
fi

# 추출된 디렉토리가 존재하는지 확인
if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "오류: '$EXTRACTED_DIR' 디렉토리가 존재하지 않습니다."
    exit 1
fi

# .jnilib와 .dylib 파일을 찾아 JAR에 포함
echo "서명된 네이티브 라이브러리(.jnilib, .dylib)를 JAR에 포함시킵니다..."
find "$EXTRACTED_DIR" -type f \( -name "*.jnilib" -o -name "*.dylib" \) | while read -r file; do
    # 상대 경로 계산 (EXTRACTED_DIR 기준)
    RELATIVE_PATH="${file#$EXTRACTED_DIR/}"
    
    echo "포함 중: $RELATIVE_PATH -> $ORIGINAL_JAR"
    
    # jar uf 명령으로 파일을 JAR에 업데이트
    jar uf "$ORIGINAL_JAR" -C "$EXTRACTED_DIR" "$RELATIVE_PATH"
    
    if [ $? -eq 0 ]; then
        echo "성공: $RELATIVE_PATH가 $ORIGINAL_JAR에 포함되었습니다."
    else
        echo "실패: $RELATIVE_PATH를 $ORIGINAL_JAR에 포함시키지 못했습니다."
    fi
    echo "--------------------------------"
done

echo "모든 네이티브 라이브러리 재패키징 작업 완료!"

