#!/bin/bash

# 공통 설정 파일 로드
source ./00_config.sh

# 외부 JAR 파일 경로
OUTER_JAR="$1"
# 내부 JAR 경로 (외부 JAR 내 상대 경로)
INNER_JAR_PATH="$2"

# 인자가 충분히 제공되지 않았을 경우 사용법 출력 후 종료
if [ -z "$OUTER_JAR" ] || [ -z "$INNER_JAR_PATH" ]; then
    echo "사용법: $0 <외부_JAR_파일> <내부_JAR_상대_경로>"
    echo "예: $0 net.sourceforge.pmd.eclipse.plugin_7.4.0.v20240726-0845-r.jar target/lib/jna.jar"
    exit 1
fi

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

# 1. 외부 JAR에서 내부 JAR 추출
echo "내부 JAR 추출 중: $INNER_JAR_PATH -> $WORK_DIR_ABS"
unzip -j "$OUTER_JAR_ABS" "$INNER_JAR_PATH" -d "$WORK_DIR_ABS"
INNER_JAR="$WORK_DIR_ABS/$(basename "$INNER_JAR_PATH")"

if [ ! -f "$INNER_JAR" ]; then
    echo "오류: 내부 JAR '$INNER_JAR_PATH'를 추출하지 못했습니다."
    rm -rf "$WORK_DIR_ABS"
    exit 1
fi

# 2. 내부 JAR에서 네이티브 파일 추출
echo "네이티브 파일 추출 중: $INNER_JAR -> $WORK_DIR_ABS/inner_extracted"
mkdir -p "$WORK_DIR_ABS/inner_extracted"
unzip "$INNER_JAR" -d "$WORK_DIR_ABS/inner_extracted"

# 3. 네이티브 파일 서명
echo "네이티브 라이브러리(.jnilib, .dylib, .so) 서명 중..."
find "$WORK_DIR_ABS/inner_extracted" -type f \( -name "*.jnilib" -o -name "*.dylib" -o -name "*.so" \) | while read -r file; do
    echo "서명 중: $file"
    codesign --force --verify --verbose --timestamp --options=runtime --entitlements ./entitlements.plist --sign "$DEVELOPER_ID" "$file"
    
    if [ $? -eq 0 ]; then
        echo "서명 성공: $file"
        codesign -vvv --deep "$file"
        [ $? -eq 0 ] && echo "검증 성공" || echo "검증 실패"
    else
        echo "서명 실패: $file"
        # 서명 실패 시 파일 권한 수정 후 재시도
        chmod 644 "$file"
        echo "권한 수정 후 재시도 중..."
        codesign --force --verify --verbose --timestamp --options=runtime --entitlements ./entitlements.plist --sign "$DEVELOPER_ID" "$file"
        if [ $? -eq 0 ]; then
            echo "권한 수정 후 서명 성공: $file"
            codesign -vvv --deep "$file"
            [ $? -eq 0 ] && echo "검증 성공" || echo "검증 실패"
        else
            echo "권한 수정 후에도 서명 실패: $file"
        fi
    fi
    echo "--------------------------------"
done

# 4. 내부 JAR 재생성
echo "서명된 네이티브 파일을 내부 JAR에 포함 중..."
CURRENT_DIR=$(pwd)
cd "$WORK_DIR_ABS/inner_extracted" || exit 1

# 서명된 네이티브 라이브러리 파일들을 내부 JAR에 업데이트
find . -type f \( -name "*.jnilib" -o -name "*.dylib" -o -name "*.so" \) | while read -r file; do
    RELATIVE_PATH="${file#./}"
    echo "내부 JAR 업데이트 중: $RELATIVE_PATH"
    jar uf "$INNER_JAR" "$RELATIVE_PATH"
done

cd "$CURRENT_DIR" || exit 1

# 내부 JAR에 실행 권한 부여
chmod +x "$INNER_JAR"
# 디렉토리 구조 생성
mkdir -p "$WORK_DIR_ABS/$(dirname "$INNER_JAR_PATH")"

# 파일 이동 (경로 구조 유지)
mv "$INNER_JAR" "$WORK_DIR_ABS/$INNER_JAR_PATH"

# 5. 외부 JAR 업데이트 - 안정적인 방법 사용
echo "업데이트된 내부 JAR를 외부 JAR에 포함 중..."

# 외부 JAR 백업 - 백업 디렉토리에 저장
cp "$OUTER_JAR_ABS" "$BACKUP_DIR_ABS/$(basename "$OUTER_JAR_ABS").bak"
echo "외부 JAR 백업 생성: $BACKUP_DIR_ABS/$(basename "$OUTER_JAR_ABS").bak"

# 업데이트된 내부 JAR를 외부 JAR에 포함
echo "외부 JAR 업데이트 중: $INNER_JAR_PATH"
jar uf "$OUTER_JAR_ABS" -C "$WORK_DIR_ABS" "$INNER_JAR_PATH"

# 작업 디렉토리 정리
echo "작업 디렉토리 정리 중..."
rm -rf "$WORK_DIR_ABS"

echo "중첩 JAR 서명 및 재패키징 완료!"
echo "백업 파일은 $BACKUP_DIR_ABS 디렉토리에 저장되었습니다."

