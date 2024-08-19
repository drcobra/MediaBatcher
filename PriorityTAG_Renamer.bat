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
    REM Use ExifTool to extract SubSecDateTimeOriginal from the image metadata
    for /f "tokens=*" %%j in ('!exifToolPath! -s3 -SubSecDateTimeOriginal "%%~fi"') do set "DateTimeOriginal=%%j"

    REM Check if DateTimeOriginal is empty and fallback to CreationDate
    if "!DateTimeOriginal!"=="" (
        for /f "tokens=*" %%k in ('!exifToolPath! -s3 -CreationDate "%%~fi"') do set "DateTimeOriginal=%%k"
    )

    REM Check if DateTimeOriginal is still empty and fallback to CreateDate
    if "!DateTimeOriginal!"=="" (
        for /f "tokens=*" %%l in ('!exifToolPath! -s3 -CreateDate "%%~fi"') do set "DateTimeOriginal=%%l"
    )

    REM Format the extracted date and time
    set "DatePart=!DateTimeOriginal:~0,10!"
    set "TimePart=!DateTimeOriginal:~11,8!"
    set "SubSecPart=!DateTimeOriginal:~20,3!"
    
    set "FormattedDate=!DatePart:~0,4!-!DatePart:~5,2!-!DatePart:~8,2!"

    REM Check if DateTimeOriginal contains a dot character
    set "CheckDot=!DateTimeOriginal:.=!"

    if "!CheckDot!"=="!DateTimeOriginal!" (
        REM No dot found, use time without SubSecPart
        set "FormattedTime=!TimePart:~0,2!-!TimePart:~3,2!-!TimePart:~6,2!"
    ) else (
        REM Dot found, include SubSecPart in time
        set "FormattedTime=!TimePart:~0,2!-!TimePart:~3,2!-!TimePart:~6,2!.!SubSecPart!"
    )
    
    REM Extract the first part of the filename before the first dash and trim whitespace
    for /f "tokens=1 delims=-" %%m in ("%%~ni") do (
        set "FirstName=%%m"
        rem echo !FirstName!
        set "FirstName=!FirstName:~0,-1!"
        rem echo !FirstName!
    )

    REM Get the original file extension
    set "FileExtension=%%~xi"

    REM Construct the new filename with the original extension
    set "NewFileName=!FormattedDate! !FormattedTime! !FirstName!!FileExtension!"
    rem echo !NewFileName!

    REM Check if the new file name already exists
    if exist "!NewFileName!" (
        REM If file exists, append "CLASH" to the filename
        set "NewFileName=!FormattedDate! !FormattedTime! !FirstName! CLASH!FileExtension!"
    )

    REM Rename the file
    ren "%%~fi" "!NewFileName!"

    REM Check if the rename operation was successful
    if !errorlevel! equ 0 (
        echo Renamed to "!NewFileName!" from "%%~fi".
    ) else (
        echo Error renaming "%%~fi" to "!NewFileName!".
    )

    REM Update FileAccessDate and FileCreateDate using the extracted DateTimeOriginal
    !exifToolPath! -overwrite_original "-FileModifyDate=!DateTimeOriginal!" "-FileCreateDate=!DateTimeOriginal!" "!NewFileName!"

    REM Reset DateTimeOriginal for the next iteration
    set "DateTimeOriginal="
)

echo.
echo Press any key to exit...
pause >nul
