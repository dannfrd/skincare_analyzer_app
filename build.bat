@echo off
setlocal
cd /d "%~dp0"
title Dermify - Build Tool
color 0A

:menu
cls
echo ========================================
echo   DERMIFY - BUILD TOOL
echo ========================================
echo.
echo 1. Development Build (Debug)
echo 2. Production Build (Release)
echo 3. Custom URL Build
echo 4. Run Development
echo 5. Run Production
echo 6. Clean Project
echo 7. Exit
echo.
echo ========================================
set /p choice="Pilih opsi (1-7): "

if "%choice%"=="1" goto dev_build
if "%choice%"=="2" goto prod_build
if "%choice%"=="3" goto custom_build
if "%choice%"=="4" goto run_dev
if "%choice%"=="5" goto run_prod
if "%choice%"=="6" goto clean
if "%choice%"=="7" goto end

echo Pilihan tidak valid!
pause
goto menu

:dev_build
cls
echo ========================================
echo   DEVELOPMENT BUILD
echo ========================================
echo Environment: Development
echo Backend: Local (10.0.2.2:8000 for emulator)
echo.
call flutter clean
if errorlevel 1 goto build_failed
call flutter pub get
if errorlevel 1 goto build_failed
call flutter build apk --debug --dart-define=ENV=dev --build-name=1.0.0
if errorlevel 1 goto build_failed
if not exist "build\app\outputs\flutter-apk\app-debug.apk" goto apk_missing
rename "build\app\outputs\flutter-apk\app-debug.apk" "Dermify-debug.apk"
echo.
echo ========================================
echo Build selesai!
echo APK: build\app\outputs\flutter-apk\Dermify-debug.apk
echo ========================================
pause
goto menu

:prod_build
cls
echo ========================================
echo   PRODUCTION BUILD
echo ========================================
echo Environment: Production
echo Backend: http://43.156.119.43
echo.
call flutter clean
if errorlevel 1 goto build_failed
call flutter pub get
if errorlevel 1 goto build_failed
call flutter build apk --release --dart-define=ENV=production
if errorlevel 1 goto build_failed
if not exist "build\app\outputs\flutter-apk\app-release.apk" goto apk_missing
rename "build\app\outputs\flutter-apk\app-release.apk" "Dermify.apk"
echo.
echo ========================================
echo Build selesai!
echo APK: build\app\outputs\flutter-apk\Dermify.apk
echo ========================================
pause
goto menu

:custom_build
cls
echo ========================================
echo   CUSTOM URL BUILD
echo ========================================
echo.
set /p custom_url="Masukkan API URL (contoh: http://192.168.1.100:8000): "
if "%custom_url%"=="" (
    echo Error: URL tidak boleh kosong!
    pause
    goto menu
)
echo.
echo Building dengan URL: %custom_url%
echo.
call flutter clean
if errorlevel 1 goto build_failed
call flutter pub get
if errorlevel 1 goto build_failed
call flutter build apk --release --dart-define=API_BASE_URL=%custom_url%
if errorlevel 1 goto build_failed
if not exist "build\app\outputs\flutter-apk\app-release.apk" goto apk_missing
rename "build\app\outputs\flutter-apk\app-release.apk" "Dermify-custom.apk"
echo.
echo ========================================
echo Build selesai!
echo APK: build\app\outputs\flutter-apk\Dermify-custom.apk
echo ========================================
pause
goto menu

:run_dev
cls
echo ========================================
echo   RUN DEVELOPMENT
echo ========================================
echo Environment: Development
echo Backend: Local
echo.
call flutter run --dart-define=ENV=dev
pause
goto menu

:run_prod
cls
echo ========================================
echo   RUN PRODUCTION
echo ========================================
echo Environment: Production
echo Backend: http://43.156.119.43
echo.
call flutter run --dart-define=ENV=production
pause
goto menu

:clean
cls
echo ========================================
echo   CLEAN PROJECT
echo ========================================
echo.
call flutter clean
if errorlevel 1 goto clean_failed
echo.
echo Project berhasil dibersihkan!
echo ========================================
pause
goto menu

:build_failed
echo.
echo ========================================
echo BUILD GAGAL. Periksa pesan error Flutter di atas.
echo ========================================
pause
goto menu

:apk_missing
echo.
echo ========================================
echo BUILD GAGAL. Flutter tidak menghasilkan file APK.
echo ========================================
pause
goto menu

:clean_failed
echo.
echo ========================================
echo CLEAN GAGAL. Periksa pesan error Flutter di atas.
echo ========================================
pause
goto menu

:end
cls
echo.
echo Terima kasih!
timeout /t 2
endlocal
exit /b
