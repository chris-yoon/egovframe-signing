#!/bin/bash

# 공통 설정 파일 로드
source ./00_config.sh

# 임시 디렉토리 생성
mkdir -p "$DMG_TEMP_DIR"

# .app 파일 복사
cp -R "$APP_NAME" "$DMG_TEMP_DIR/"

# /Applications 심볼릭 링크 추가
ln -s /Applications "$DMG_TEMP_DIR/Applications"

# DMG 생성
hdiutil create -srcfolder "$DMG_TEMP_DIR" -volname "$DMG_VOLUME_NAME" "$DMG_NAME"

# DMG 서명 (필요시 주석 해제)
#codesign --force --timestamp --sign "$DEVELOPER_ID" "$DMG_NAME"

# 정리
rm -rf "$DMG_TEMP_DIR"

echo "DMG 생성 완료!"
