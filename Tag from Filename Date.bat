@echo off
setlocal enabledelayedexpansion

REM Ensure exiftool.exe exists in the script directory
set "scriptDirectory=%~dp0"
set "exifToolPath=!scriptDirectory!bin\exiftool.exe"

if not exist "!exifToolPath!" (
    echo ExifTool is not installed or not in the script directory.
    pause
    exit /b 1
)

REM Loop through each file passed as an argument
for %%i in (%*) do (
    REM Extract date from the filename
    set "filename=%%~nxi"
    set "date=!filename:~0,10! 00:00:00"
	
	echo date "!date!"
	
    REM Format the date
	set "CorrectDate=!date!"
    rem set "CorrectDate=!date!+00:00"
	rem set "CorrectDate=!date!Z"

    REM Use ExifTool to apply the CorrectDate to the specified tags
	REM File Tags: FileCreateDate FileModifyDate | FileAccessDate
	REM Meta Tags: DateTimeOriginal CreationDate | CreateDate MediaCreateDate DateTimeCreated
    !exifToolPath! -overwrite_original "-FileCreateDate=!CorrectDate!" "-FileModifyDate=!CorrectDate!" "-DateTimeOriginal=!CorrectDate!" "-CreationDate=!CorrectDate!" "-CreateDate=!CorrectDate!" "-ModifyDate=!CorrectDate!" "%%~fi" 


    REM Check if ExifTool operation was successful
    if !errorlevel! equ 0 (
        echo Updated tags for "%%~fi".
    ) else (
        echo Error updating tags for "%%~fi".
    )
)

echo.
echo Press any key to exit...
pause >nul
