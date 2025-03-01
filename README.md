# eGovFrame CodeSign Scripts

macOS용 전자정부 표준프레임워크 개발환경(`eGovFrameDev-4.3.0-Mac-AArch64.app`)의 코드 서명 및 공증을 자동화하는 스크립트입니다.

## 기능

- JAR 파일 내 네이티브 라이브러리 서명
- 중첩 JAR(JAR 내의 JAR) 처리
- 앱 서명
- DMG 이미지 생성
- Apple 공증(Notarization) 자동화

## 사전 준비

1. Apple Developer ID Application 인증서
2. Apple Developer 계정 정보
   - Apple ID
   - App-specific password
   - Team ID

## 설정

`00_config.sh` 파일에서 다음 정보를 설정합니다:

```sh
# 개발자 ID 및 인증 정보
DEVELOPER_ID="Developer ID Application: Your Name (TEAM_ID)"
APPLE_ID="your.email@example.com"
APPLE_PASSWORD="your-app-specific-password"
TEAM_ID="YOUR_TEAM_ID"

# 앱 정보
APP_NAME="eGovFrameDev-4.3.0-Mac-AArch64.app"
DMG_NAME="eGovFrameDev-4.3.0-Mac-AArch64.dmg"
APP_BUNDLE_ID="org.egovframe.platform.ide"
```

## 실행 방법

1. 서명할 애플리케이션을 프로젝트 루트 디렉토리에 복사합니다.

2. 스크립트 실행 (옵션은 선택사항):
```bash
# 앱 서명까지만 실행
./run.sh --sign-only

# DMG 생성까지 실행
./run.sh --with-dmg

# 노타리까지 모두 실행 (기본값)
./run.sh --full
# 또는
./run.sh
```

### 실행 옵션

- `--sign-only`: JAR 파일 처리 및 앱 서명까지만 실행
- `--with-dmg`: DMG 생성까지 실행
- `--full`: 노타리까지 모든 과정 실행 (기본값)
- `--help` 또는 `-h`: 사용법 출력

## 스크립트 구성

### 00_config.sh
- 전체 프로젝트의 공통 설정 파일
- 개발자 인증서, 앱 정보, 경로 설정 등

### 01_extract_jars.sh
- JAR 파일에서 네이티브 라이브러리가 포함된 파일 추출
- 추출된 파일은 `extracted_*` 디렉토리에 저장

### 02_sign_native_libraries.sh
- 추출된 네이티브 라이브러리(.jnilib, .dylib)에 대한 코드 서명
- `codesign` 명령어를 사용하여 서명

### 03_repackage_jars.sh
- 서명된 네이티브 라이브러리를 JAR 파일로 재패키징
- 원본 JAR 구조 유지

### 04_sign_nested_jars.sh
- JAR 내부에 포함된 다른 JAR 파일 처리
- 중첩된 JAR의 네이티브 라이브러리 서명

### 05_create_dmg.sh
- 서명된 앱을 포함하는 DMG 이미지 생성
- Applications 폴더 심볼릭 링크 포함

## 로그 확인

- 실행 로그: `./logs/run_[timestamp].log`
- 정리 작업 로그: `./logs/clean_[timestamp].log`
- 노타리 제출 로그: `./logs/notary_output_[timestamp].log`

## 주의사항

- 네이티브 라이브러리 서명 시 `--deep` 옵션을 사용하지 않도록 주의하세요. 라이브러리 구조가 손상될 수 있습니다.
- 실행 전 반드시 `clean.sh`를 실행하여 이전 작업 파일을 정리하세요.

## 디렉토리 구조

```
.
├── 00_config.sh           # 설정 파일
├── 01_extract_jars.sh     # JAR 추출 스크립트
├── 02_sign_native_libraries.sh  # 라이브러리 서명 스크립트
├── 03_repackage_jars.sh   # JAR 재패키징 스크립트
├── 04_sign_nested_jars.sh # 중첩 JAR 처리 스크립트
├── 05_create_dmg.sh       # DMG 생성 스크립트
├── run.sh                 # 메인 실행 스크립트
├── clean.sh              # 정리 스크립트
├── logs/                 # 로그 파일 디렉토리
└── entitlements.plist    # 권한 설정 파일
```
