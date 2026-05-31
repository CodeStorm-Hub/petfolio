name: CodeQL

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '30 4 * * 1'

concurrency:
  group: codeql-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  analyze:
    name: Analyze (${{ matrix.language }})
    runs-on: ${{ matrix.language == 'swift' && 'macos-latest' || 'ubuntu-latest' }}
    timeout-minutes: ${{ matrix.language == 'swift' && 180 || 90 }}
    permissions:
      security-events: write
      packages: read
      actions: read
      contents: read

    strategy:
      fail-fast: false
      matrix:
        include:
          - language: actions
            build-mode: none
          - language: java-kotlin
            build-mode: manual
          - language: swift
            build-mode: manual
          - language: javascript-typescript
            build-mode: none

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Java
        if: matrix.language == 'java-kotlin'
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
          cache: gradle

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v4
        with:
          languages: ${{ matrix.language }}
          build-mode: ${{ matrix.build-mode }}
          dependency-caching: ${{ matrix.language == 'java-kotlin' }}

      - name: Set up Flutter
        if: matrix.build-mode == 'manual'
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Resolve Dart dependencies
        if: matrix.build-mode == 'manual'
        run: flutter pub get

      - name: Build Android for CodeQL
        if: matrix.language == 'java-kotlin'
        run: flutter build apk --debug

      - name: Build iOS for CodeQL
        if: matrix.language == 'swift'
        env:
          CODE_SIGNING_ALLOWED: 'NO'
          CODE_SIGNING_REQUIRED: 'NO'
        run: |
          cd ios
          pod install
          xcodebuild build \
            -workspace Runner.xcworkspace \
            -scheme Runner \
            -configuration Debug \
            -sdk iphonesimulator \
            -destination 'generic/platform=iOS Simulator' \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGNING_REQUIRED=NO \
            COMPILER_INDEX_STORE_ENABLE=NO

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v4
        with:
          category: '/language:${{ matrix.language }}'
