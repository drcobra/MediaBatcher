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
    for /f "tokens=*" %%j in ('!exifToolPath! -s3 -SubSecDateTimeOriginal "%%~fi"') do set "BestDate=%%j"

    REM Check if BestDate is empty and fallback to DateTimeOriginal
    if "!BestDate!"=="" (
        for /f "tokens=*" %%j in ('!exifToolPath! -s3 -DateTimeOriginal "%%~fi"') do set "BestDate=%%j"
    )

    REM Check if BestDate is empty and fallback to CreationDate
    if "!BestDate!"=="" (
        for /f "tokens=*" %%j in ('!exifToolPath! -s3 -CreationDate "%%~fi"') do set "BestDate=%%j"
    )

    REM Check if BestDate is still empty and fallback to CreateDate
    if "!BestDate!"=="" (
        for /f "tokens=*" %%j in ('!exifToolPath! -s3 -CreateDate "%%~fi"') do set "BestDate=%%j"
    )

    REM Check if BestDate is still empty and fallback to SubSecMediaCreateDate
    if "!BestDate!"=="" (
        for /f "tokens=*" %%j in ('!exifToolPath! -s3 -SubSecMediaCreateDate "%%~fi"') do set "BestDate=%%j"
    )

    REM Check if BestDate is still empty and fallback to MediaCreateDate
    if "!BestDate!"=="" (
        for /f "tokens=*" %%j in ('!exifToolPath! -s3 -MediaCreateDate "%%~fi"') do set "BestDate=%%j"
    )

    REM Check if BestDate is still empty and fallback to DateTimeCreated
    if "!BestDate!"=="" (
        for /f "tokens=*" %%j in ('!exifToolPath! -s3 -DateTimeCreated "%%~fi"') do set "BestDate=%%j"
    )

    REM Format the extracted date and time
    set "DatePart=!BestDate:~0,10!"
    set "TimePart=!BestDate:~11,8!"
    set "SubSecPart=!BestDate:~20,3!"
    
    set "FormattedDate=!DatePart:~0,4!-!DatePart:~5,2!-!DatePart:~8,2!"

    REM Check if BestDate contains a dot character
    set "CheckDot=!BestDate:.=!"

    if "!CheckDot!"=="!BestDate!" (
        REM No dot found, use time without SubSecPart
        set "FormattedTime=!TimePart:~0,2!-!TimePart:~3,2!-!TimePart:~6,2!.000"
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

    REM Update FileAccessDate and FileCreateDate using the extracted BestDate
    !exifToolPath! -overwrite_original "-FileModifyDate=!BestDate!" "-FileCreateDate=!BestDate!" "!NewFileName!"

    REM Reset BestDate for the next iteration
    set "BestDate="
)

echo.
echo Press any key to exit...
pause >nul
