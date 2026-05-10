@echo off
set SRC=C:\Users\USER\.gemini\antigravity\brain\27006fbc-6ba5-45a3-8a1c-756dca21e24a
set DEST=assets\images

echo Installation des assets B-GLORY...

copy "%SRC%\b_glory_tirage_icon_1778266044171.png" "%DEST%\app_icon.png" /Y
copy "%SRC%\b_glory_tirage_logo_premium_1778267069910.png" "%DEST%\logo.png" /Y
copy "%SRC%\b_glory_tirage_splash_match_logo_1778268170713.png" "%DEST%\splash.png" /Y

echo Assets installes avec succes !
echo Generation des icones et splash screen...

call flutter pub get
call flutter pub run flutter_launcher_icons
call flutter pub run flutter_native_splash:create

echo.
echo NOTE: Pour voir le changement d'icone sur Android, il est souvent 
echo       necessaire de DESINSTALLER l'application du telephone puis
echo       de la REINSTALLER avec 'flutter run'.

pause
