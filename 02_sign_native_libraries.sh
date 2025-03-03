#!/bin/bash
#===============================================================================
# 네이티브 라이브러리 서명 스크립트
# 목적: 추출된 JAR 디렉토리 내의 네이티브 라이브러리(.jnilib, .dylib)에 서명합니다.
#===============================================================================

# 공통 설정 파일 로드
source ./00_config.sh

#-------------------------------------------------------------------------------
# 사용법 확인
#-------------------------------------------------------------------------------
# 디렉토리가 제공되지 않았을 경우 사용법 출력 후 종료
if [ $# -lt 1 ]; then
    echo "사용법: $0 <추출된_JAR_디렉토리>"
    echo "예: $0 extracted_jna_5.8.0"
    exit 1
fi

# 서명할 디렉토리 (추출된 JAR 파일의 루트 디렉토리)
EXTRACTED_DIR="$1"

# 디렉토리가 존재하는지 확인
if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "오류: '$EXTRACTED_DIR' 디렉토리가 존재하지 않습니다."
    exit 1
fi

#-------------------------------------------------------------------------------
# 네이티브 라이브러리 서명 함수
#-------------------------------------------------------------------------------
sign_native_library() {
    local file="$1"
    
    echo "서명 중: $file"
    
    # 서명 수행 (강제로 덮어쓰기, 타임스탬프 포함)
    if ! codesign --force --timestamp --options=runtime --entitlements ./entitlements.plist --sign "$DEVELOPER_ID" "$file"; then
        echo "  서명 실패: $file"
        
        # 권한 문제일 수 있으므로 권한 수정 후 재시도
        echo "  권한 수정 후 재시도 중..."
        chmod 644 "$file"
        
        if ! codesign --force --timestamp --options=runtime --entitlements ./entitlements.plist --sign "$DEVELOPER_ID" "$file"; then
            echo "  권한 수정 후에도 서명 실패: $file"
            return 1
        fi
    fi
    
    # 서명 검증
    if ! codesign -vvv --deep "$file" &>/dev/null; then
        echo "  서명 검증 실패: $file"
        return 1
    fi
    
    echo "  서명 성공: $file"
    return 0
}

#-------------------------------------------------------------------------------
# 메인 실행 부분
#-------------------------------------------------------------------------------
echo "네이티브 라이브러리(.jnilib, .dylib)를 검색하고 서명합니다..."

# 서명 성공/실패 카운터 초기화
SUCCESS_COUNT=0
FAILURE_COUNT=0

# .jnilib와 .dylib 파일을 찾아 서명
while IFS= read -r file; do
    if sign_native_library "$file"; then
        ((SUCCESS_COUNT++))
    else
        ((FAILURE_COUNT++))
    fi
    echo "--------------------------------"
done < <(find "$EXTRACTED_DIR" -type f \( -name "*.jnilib" -o -name "*.dylib" \))

# 결과 출력
echo "서명 결과:"
echo "- 성공: $SUCCESS_COUNT 파일"
echo "- 실패: $FAILURE_COUNT 파일"

if [ $FAILURE_COUNT -eq 0 ]; then
    echo "모든 네이티브 라이브러리 서명 완료"
    exit 0
else
    echo "일부 네이티브 라이브러리 서명 실패"
    exit 1
fi
