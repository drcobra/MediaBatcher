@echo off
setlocal enabledelayedexpansion

REM Ensure ImageMagick is installed and accessible
set "scriptDirectory=%~dp0"
set "magickPath=%scriptDirectory%bin\ImageMagick\magick.exe"

REM Define maximum dimensions, target DPI, and JPEG compression quality
set "maxSize=2480"
set "targetDPI=300"
set "jpegQuality=80"

REM Check if ImageMagick is installed
"%magickPath%" -version >nul 2>&1
if errorlevel 1 (
    echo ImageMagick is not installed or not in PATH.
    pause
    exit /b 1
)

REM Process each file passed as an argument
for %%i in (%*) do (
    REM Gather file details
    set "inputFile=%%~fi"
    set "outputFile=%%~dpni_DPI%targetDPI%%%~xi"

    echo Processing "%%i"...

    REM Resize, adjust DPI, and set JPEG compression quality
    "%magickPath%" "%%~fi" -units PixelsPerInch -density %targetDPI% -resize %maxSize%x%maxSize%^> -quality %jpegQuality% "%%~dpni_DPI%targetDPI%%%~xi"

    REM Check if the operation succeeded
    if exist "%%~dpni_DPI%targetDPI%%%~xi" (
        echo Successfully processed: "%%~dpni_DPI%targetDPI%%%~xi"
    ) else (
        echo Failed to process: "%%i"
    )
)

echo.
echo Processing complete! Press any key to exit...
pause >nul
