#!/bin/bash

# 개발자 ID 및 인증 정보
DEVELOPER_ID="Developer ID Application: {개발자 이름} ({TEAM_ID})"
APPLE_ID="{APPLE_ID}"
APPLE_PASSWORD="{APP_SPECIFIC_PASSWORD}"
TEAM_ID="{TEAM_ID}"

# 앱 정보
APP_NAME="eGovFrameDev-4.3.0-Mac-AArch64.app"
DMG_NAME="eGovFrameDev-4.3.0-Mac-AArch64.dmg"
APP_BUNDLE_ID="org.egovframe.platform.ide"

# 추출된 JAR 디렉토리 목록
EXTRACTED_DIRS=(
    "extracted_jna_5.8.0"
    "extracted_jna_5.6.0"
    "extracted_jna_5.14.0"
    "extracted_lz4_java_1.4.1"
    "extracted_snappy_java_1.1.10.5"
    "extracted_kotlin_compiler_1.9.20"
)

# JAR 파일 경로와 추출 디렉토리 매핑 (연관 배열 대신 일반 배열 사용)
JAR_PATHS=(
    "$APP_NAME/Contents/Eclipse/configuration/org.eclipse.osgi/1055/0/.cp/dependency/jna-5.8.0.jar"
    "$APP_NAME/Contents/Eclipse/configuration/org.eclipse.osgi/1103/0/.cp/lib/jna-5.6.0.jar"
    "$APP_NAME/Contents/Eclipse/plugins/org.springframework.tooling.boot.ls_1.54.0.202405011602/servers/spring-boot-language-server/BOOT-INF/lib/jna-5.14.0.jar"
    "$APP_NAME/Contents/Eclipse/configuration/org.eclipse.osgi/1103/0/.cp/lib/lz4-java-1.4.1.jar"
    "$APP_NAME/Contents/Eclipse/plugins/org.springframework.tooling.boot.ls_1.54.0.202405011602/servers/spring-boot-language-server/BOOT-INF/lib/snappy-java-1.1.10.5.jar"
    "$APP_NAME/Contents/Eclipse/plugins/org.springframework.tooling.boot.ls_1.54.0.202405011602/servers/spring-boot-language-server/BOOT-INF/lib/kotlin-compiler-embeddable-1.9.20.jar"
)
EXTRACT_DIRS=(
    "extracted_jna_5.8.0"
    "extracted_jna_5.6.0"
    "extracted_jna_5.14.0"
    "extracted_lz4_java_1.4.1"
    "extracted_snappy_java_1.1.10.5"
    "extracted_kotlin_compiler_1.9.20"
)

# 중첩 JAR 정보
OUTER_JARS=(
    "$APP_NAME/Contents/Eclipse/plugins/net.sourceforge.pmd.eclipse.plugin_7.4.0.v20240726-0845-r.jar"
    "$APP_NAME/Contents/Eclipse/plugins/org.polarion.eclipse.team.svn.connector.svnkit1_10_6.1.0.jar"
    "$APP_NAME/Contents/Eclipse/plugins/org.polarion.eclipse.team.svn.connector.svnkit1_10_6.1.0.jar"
    "$APP_NAME/Contents/Eclipse/plugins/org.springframework.ide.eclipse.docker.client_4.22.1.202405011620.jar"
)

INNER_JAR_PATHS=(
    "target/lib/jna.jar"
    "lib/lz4-java-1.4.1.jar"
    "lib/jna-5.6.0.jar"
    "dependency/jna-5.8.0.jar"
)

# 작업 디렉토리
WORK_DIR="temp_work_dir"

# DMG 관련 설정
DMG_TEMP_DIR="dmg_temp"
DMG_VOLUME_NAME="eGovFrameDev"
