@echo off
setlocal enabledelayedexpansion

REM Ensure exiftool.exe exists in the script directory
set "scriptDirectory=%~dp0"
set "exifToolPath=!scriptDirectory!bin\ExifTool\exiftool.exe"

if not exist "!exifToolPath!" (
    echo ExifTool is not installed or not in the script directory.
    pause
    exit /b 1
)

REM Loop through each file passed as an argument
for %%i in (%*) do (
    REM Extract filename
    set "filename=%%~nxi"
    echo Processing file: "!filename!"

    REM Extract the first 19 characters for the date part (YYYY-MM-DD HH-MM-SS)
    set "date=!filename:~0,19!"

    REM Check if the 20th character is a dot (.) indicating microseconds
    set "dot=!filename:~19,1!"
    if "!dot!"=="." (
        REM Filename contains microseconds, so extract them
        set "microseconds=!filename:~20,3!"
        set "CorrectDate=!date!.!microseconds!"
    ) else (
        REM Filename does not contain microseconds
        set "CorrectDate=!date!"
    )

    echo CorrectDate "!CorrectDate!"

    REM Use ExifTool to apply the CorrectDate to the specified tags
	REM File Tags: FileCreateDate FileModifyDate | FileAccessDate
	REM Meta Tags: DateTimeOriginal CreationDate | CreateDate MediaCreateDate DateTimeCreated
    !exifToolPath! -overwrite_original "-FileCreateDate=!CorrectDate!" "-FileModifyDate=!CorrectDate!" "-DateTimeOriginal=!CorrectDate!" "-CreationDate=!CorrectDate!" "-CreateDate=!CorrectDate!" "-DateCreated=!CorrectDate!" "-ModifyDate=!CorrectDate!" "%%~fi"

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
