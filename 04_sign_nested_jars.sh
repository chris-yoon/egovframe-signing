#!/bin/bash
#===============================================================================
# 중첩 JAR 서명 스크립트
# 목적: JAR 파일 내부에 있는 JAR 파일 내의 네이티브 라이브러리를 서명합니다.
#===============================================================================

# 공통 설정 파일 로드
source ./00_config.sh

#-------------------------------------------------------------------------------
# 사용법 확인
#-------------------------------------------------------------------------------
# 인자가 충분히 제공되지 않았을 경우 사용법 출력 후 종료
if [ $# -lt 2 ]; then
    echo "사용법: $0 <외부_JAR_파일> <내부_JAR_상대_경로>"
    echo "예: $0 net.sourceforge.pmd.eclipse.plugin_7.4.0.v20240726-0845-r.jar target/lib/jna.jar"
    exit 1
fi

# 외부 JAR 파일 경로
OUTER_JAR="$1"
# 내부 JAR 경로 (외부 JAR 내 상대 경로)
INNER_JAR_PATH="$2"

#-------------------------------------------------------------------------------
# 파일 존재 확인 및 작업 디렉토리 설정
#-------------------------------------------------------------------------------
# 절대 경로로 변환
OUTER_JAR_ABS=$(realpath "$OUTER_JAR")

# 외부 JAR 파일이 존재하는지 확인
if [ ! -f "$OUTER_JAR_ABS" ]; then
    echo "오류: '$OUTER_JAR_ABS' 파일이 존재하지 않습니다."
    exit 1
fi

# 작업 디렉토리 생성 (고유한 이름 사용)
WORK_DIR="temp_work_dir_$(date +%s%N)"
mkdir -p "$WORK_DIR"
WORK_DIR_ABS=$(realpath "$WORK_DIR")

# 백업 디렉토리 생성 - 백업 파일을 별도로 보관
BACKUP_DIR="backups_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
BACKUP_DIR_ABS=$(realpath "$BACKUP_DIR")

echo "작업 디렉토리: $WORK_DIR_ABS"
echo "백업 디렉토리: $BACKUP_DIR_ABS"

#-------------------------------------------------------------------------------
# 내부 JAR 추출 및 서명 함수
#-------------------------------------------------------------------------------
extract_and_sign_inner_jar() {
    local outer_jar="$1"
    local inner_path="$2"
    local work_dir="$3"
    
    echo "내부 JAR 추출 중: $inner_path -> $work_dir"
    
    # 내부 JAR 추출
    if ! unzip -j "$outer_jar" "$inner_path" -d "$work_dir"; then
        echo "오류: 내부 JAR '$inner_path'를 추출하지 못했습니다."
        return 1
    fi
    
    local inner_jar="$work_dir/$(basename "$inner_path")"
    if [ ! -f "$inner_jar" ]; then
        echo "오류: 추출된 내부 JAR 파일을 찾을 수 없습니다: $inner_jar"
        return 1
    fi
    
    # 내부 JAR 내용 추출
    local extract_dir="$work_dir/inner_extracted"
    mkdir -p "$extract_dir"
    
    if ! unzip "$inner_jar" -d "$extract_dir"; then
        echo "오류: 내부 JAR 내용을 추출하지 못했습니다: $inner_jar"
        return 1
    fi
    
    # 네이티브 라이브러리 서명
    local signed_count=0
    local failed_count=0
    
    while IFS= read -r file; do
        echo "서명 중: $file"
        
        if codesign --force --verify --verbose --timestamp --options=runtime --entitlements ./entitlements.plist --sign "$DEVELOPER_ID" "$file"; then
            echo "서명 성공: $file"
            codesign -vvv --deep "$file" && echo "검증 성공" || echo "검증 실패"
            ((signed_count++))
        else
            echo "서명 실패: $file"
            # 서명 실패 시 파일 권한 수정 후 재시도
            chmod 644 "$file"
            echo "권한 수정 후 재시도 중..."
            
            if codesign --force --verify --verbose --timestamp --options=runtime --entitlements ./entitlements.plist --sign "$DEVELOPER_ID" "$file"; then
                echo "권한 수정 후 서명 성공: $file"
                codesign -vvv --deep "$file" && echo "검증 성공" || echo "검증 실패"
                ((signed_count++))
            else
                echo "권한 수정 후에도 서명 실패: $file"
                ((failed_count++))
            fi
        fi
        echo "--------------------------------"
    done < <(find "$extract_dir" -type f \( -name "*.jnilib" -o -name "*.dylib" -o -name "*.so" \))
    
    echo "서명 결과: 성공 $signed_count, 실패 $failed_count"
    
    # 내부 JAR 재생성
    echo "서명된 네이티브 파일을 내부 JAR에 포함 중..."
    local current_dir=$(pwd)
    cd "$extract_dir" || return 1
    
    # 서명된 네이티브 라이브러리 파일들을 내부 JAR에 업데이트
    while IFS= read -r file; do
        local relative_path="${file#./}"
        echo "내부 JAR 업데이트 중: $relative_path"
        jar uf "$inner_jar" "$relative_path"
    done < <(find . -type f \( -name "*.jnilib" -o -name "*.dylib" -o -name "*.so" \))
    
    cd "$current_dir" || return 1
    
    # 내부 JAR에 실행 권한 부여
    chmod +x "$inner_jar"
    
    # 디렉토리 구조 생성 및 파일 이동
    mkdir -p "$work_dir/$(dirname "$inner_path")"
    mv "$inner_jar" "$work_dir/$inner_path"
    
    return 0
}

#-------------------------------------------------------------------------------
# 메인 실행 부분
#-------------------------------------------------------------------------------
# 1. 외부 JAR에서 내부 JAR 추출 및 서명
if ! extract_and_sign_inner_jar "$OUTER_JAR_ABS" "$INNER_JAR_PATH" "$WORK_DIR_ABS"; then
    echo "오류: 내부 JAR 처리 중 실패"
    rm -rf "$WORK_DIR_ABS"
    exit 1
fi

# 2. 외부 JAR 업데이트 - 안정적인 방법 사용
echo "업데이트된 내부 JAR를 외부 JAR에 포함 중..."

# 외부 JAR 백업 - 백업 디렉토리에 저장
cp "$OUTER_JAR_ABS" "$BACKUP_DIR_ABS/$(basename "$OUTER_JAR_ABS").bak"
echo "외부 JAR 백업 생성: $BACKUP_DIR_ABS/$(basename "$OUTER_JAR_ABS").bak"

# 업데이트된 내부 JAR를 외부 JAR에 포함
echo "외부 JAR 업데이트 중: $INNER_JAR_PATH"
if ! jar uf "$OUTER_JAR_ABS" -C "$WORK_DIR_ABS" "$INNER_JAR_PATH"; then
    echo "오류: 외부 JAR 업데이트 실패"
    echo "백업 파일: $BACKUP_DIR_ABS/$(basename "$OUTER_JAR_ABS").bak"
    rm -rf "$WORK_DIR_ABS"
    exit 1
fi

# 작업 디렉토리 정리
echo "작업 디렉토리 정리 중..."
rm -rf "$WORK_DIR_ABS"

echo "중첩 JAR 서명 및 재패키징 완료!"
echo "백업 파일은 $BACKUP_DIR_ABS 디렉토리에 저장되었습니다."
exit 0

