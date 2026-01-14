@echo off
setlocal enabledelayedexpansion

REM Ensure ImageMagick is installed and accessible
set "scriptDirectory=%~dp0"
set "magickPath=%scriptDirectory%bin\ImageMagick\magick.exe"  REM Adjust path if necessary

REM Check if ImageMagick is installed
"%magickPath%" -version >nul 2>&1
if errorlevel 1 (
    echo ImageMagick is not installed or not accessible.
    pause
    exit /b 1
)

REM Check if files were dropped
if "%~1"=="" (
    echo No files provided. Drag and drop files onto this script.
    pause
    exit /b 1
)

REM Initialize the file list
set "fileList="

REM Loop through all dropped files
for %%i in (%*) do (
    REM Check if the file exists and is a supported image type
    if exist "%%~fi" (
        for %%j in (jpg jpeg png bmp tiff) do (
            if /i "%%~xi"==".%%j" (
                set "fileList=!fileList! "%%~fi""
            )
        )
    )
)

REM Check if any supported image files were found
if "!fileList!"=="" (
    echo No supported image files found among the dropped files.
    pause
    exit /b 1
)

REM Extract base name for the output PDF from the first file
for %%i in (%fileList%) do (
    set "firstFile=%%~nxi"
    set "destDir=%%~dpi"
    goto :foundFirstFile
)
:foundFirstFile
for /f "delims=." %%a in ("%firstFile%") do set "baseName=%%a"

REM Define output PDF file name based on the first file's name
set "outputPDF=%destDir%%baseName%.pdf"

REM Create a single PDF from all specified files
"%magickPath%" !fileList! "%outputPDF%"

REM Check if PDF was created successfully
if exist "%outputPDF%" (
    echo Successfully created PDF: "%outputPDF%"
) else (
    echo Failed to create PDF.
)

pause
