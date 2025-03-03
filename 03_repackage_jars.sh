#!/bin/bash
#===============================================================================
# JAR 재패키징 스크립트
# 목적: 서명된 네이티브 라이브러리를 원본 JAR 파일에 다시 포함시킵니다.
#===============================================================================

# 공통 설정 파일 로드
source ./00_config.sh

#-------------------------------------------------------------------------------
# 사용법 확인
#-------------------------------------------------------------------------------
# 인자가 충분히 제공되지 않았을 경우 사용법 출력 후 종료
if [ $# -lt 2 ]; then
    echo "사용법: $0 <원본_JAR_파일> <추출된_디렉토리>"
    echo "예: $0 jna-5.8.0.jar extracted_jna_5.8.0"
    exit 1
fi

# 원본 JAR 파일 경로
ORIGINAL_JAR="$1"
# 추출된 디렉토리 경로
EXTRACTED_DIR="$2"

#-------------------------------------------------------------------------------
# 파일 및 디렉토리 존재 확인
#-------------------------------------------------------------------------------
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

#-------------------------------------------------------------------------------
# JAR 재패키징 함수
#-------------------------------------------------------------------------------
repackage_native_library() {
    local file="$1"
    local jar="$2"
    local base_dir="$3"
    
    # 상대 경로 계산 (EXTRACTED_DIR 기준)
    local RELATIVE_PATH="${file#$base_dir/}"
    
    echo "포함 중: $RELATIVE_PATH -> $jar"
    
    # jar uf 명령으로 파일을 JAR에 업데이트
    if ! jar uf "$jar" -C "$base_dir" "$RELATIVE_PATH"; then
        echo "실패: $RELATIVE_PATH를 $jar에 포함시키지 못했습니다."
        return 1
    fi
    
    printf "성공: %s가 %s에 포함되었습니다.\n" "$RELATIVE_PATH" "$jar"
    return 0
}

#-------------------------------------------------------------------------------
# 메인 실행 부분
#-------------------------------------------------------------------------------
echo "서명된 네이티브 라이브러리(.jnilib, .dylib)를 JAR에 포함시킵니다..."

# 백업 생성
BACKUP_DIR="backups_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp "$ORIGINAL_JAR" "$BACKUP_DIR/$(basename "$ORIGINAL_JAR").bak"
echo "백업 생성: $BACKUP_DIR/$(basename "$ORIGINAL_JAR").bak"

# 성공/실패 카운터 초기화
SUCCESS_COUNT=0
FAILURE_COUNT=0

# .jnilib와 .dylib 파일을 찾아 JAR에 포함
while IFS= read -r file; do
    if repackage_native_library "$file" "$ORIGINAL_JAR" "$EXTRACTED_DIR"; then
        ((SUCCESS_COUNT++))
    else
        ((FAILURE_COUNT++))
    fi
    echo "--------------------------------"
done < <(find "$EXTRACTED_DIR" -type f \( -name "*.jnilib" -o -name "*.dylib" \))

# 결과 출력
echo "재패키징 결과:"
echo "- 성공: $SUCCESS_COUNT 파일"
echo "- 실패: $FAILURE_COUNT 파일"

if [ $FAILURE_COUNT -eq 0 ]; then
    echo "모든 네이티브 라이브러리 재패키징 작업 완료!"
    exit 0
else
    echo "일부 네이티브 라이브러리 재패키징 실패"
    exit 1
fi

