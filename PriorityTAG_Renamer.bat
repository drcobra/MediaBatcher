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

    set "OriginalPathFileNameExt=%%~fi"
    set "OriginalPathFileName=%%~ni"
    set "OriginalFileNameExt=%%~nxi"
    set "FilePath=%%~dpi"
    set "FileExtension=%%~xi"

    REM Use ExifTool to extract SubSecDateTimeOriginal from the image metadata
    for /f "tokens=*" %%j in ('!exifToolPath! -s3 -SubSecDateTimeOriginal "!OriginalPathFileNameExt!"') do set "BestDate=%%j"
    echo SubSecDateTimeOriginal "!BestDate!"

    REM Check if BestDate is empty and fallback to DateTimeOriginal
    if "!BestDate!"=="" (
        for /f "tokens=*" %%j in ('!exifToolPath! -s3 -DateTimeOriginal "!OriginalPathFileNameExt!"') do set "BestDate=%%j"
        echo DateTimeOriginal "!BestDate!"
    )

    REM Check if BestDate is empty and fallback to CreationDate
    if "!BestDate!"=="" (
        for /f "tokens=*" %%j in ('!exifToolPath! -s3 -CreationDate "!OriginalPathFileNameExt!"') do set "BestDate=%%j"
        echo CreationDate "!BestDate!"
    )

    REM Check if BestDate is still empty and fallback to CreateDate
    if "!BestDate!"=="" (
        for /f "tokens=*" %%j in ('!exifToolPath! -s3 -CreateDate "!OriginalPathFileNameExt!"') do set "BestDate=%%j"
        echo CreateDate "!BestDate!"
    )

    REM Check if BestDate is still empty and fallback to SubSecMediaCreateDate
    if "!BestDate!"=="" (
        for /f "tokens=*" %%j in ('!exifToolPath! -s3 -SubSecMediaCreateDate "!OriginalPathFileNameExt!"') do set "BestDate=%%j"
        echo SubSecMediaCreateDate "!BestDate!"
    )

    REM Check if BestDate is still empty and fallback to MediaCreateDate
    if "!BestDate!"=="" (
        for /f "tokens=*" %%j in ('!exifToolPath! -s3 -MediaCreateDate "!OriginalPathFileNameExt!"') do set "BestDate=%%j"
        echo MediaCreateDate "!BestDate!"
    )

    REM Check if BestDate is still empty and fallback to DateTimeCreated
    if "!BestDate!"=="" (
        for /f "tokens=*" %%j in ('!exifToolPath! -s3 -DateTimeCreated "!OriginalPathFileNameExt!"') do set "BestDate=%%j"
        echo DateTimeCreated "!BestDate!"
    )

    REM If BestDate is still empty, move the file to the noTAG directory and skip further processing
    if "!BestDate!"=="" (
        echo No TAGs
        REM Create "noTAG" subdirectory if it doesn't exist in the file's directory
        if not exist "!FilePath!noTAG" (
            mkdir "!FilePath!noTAG"
        )
        
        REM Move the file to the "noTAG" directory within the file's directory
        move "!OriginalPathFileNameExt!" "!FilePath!noTAG\"
        echo Moved "!OriginalPathFileNameExt!" to noTAG directory due to missing metadata.
        REM Skip to the next file
        REM Continue to next iteration of the loop

    )

    if not "!BestDate!"=="" (
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
        for /f "tokens=1 delims=-" %%m in ("!OriginalPathFileName!") do (
            set "FirstName=%%m"
            rem echo !FirstName!
            set "FirstName=!FirstName:~0,-1!"
            rem echo !FirstName!
        )

        REM Construct the new filename with the original extension
        set "BaseFileName=!FormattedDate! !FormattedTime! !FirstName!"
        set "NewFileNameExt=!BaseFileName!!FileExtension!"
        rem echo !NewFileNameExt!

        REM Check if the new file name already exists, but skip if it's the same as the current file's name (case-insensitive)
        if exist "!NewFileNameExt!" (
            echo new file name already exists
            set "DuplicateCount=1"

            REM Loop to find a unique filename
            while exist "!FilePath!!NewFileNameExt!" (
                echo while exist "!FilePath!!NewFileNameExt!"
                set /a DuplicateCount+=1
                set "NewFileNameExt=!BaseFileName! DUPLICATE!DuplicateCount!!FileExtension!"
            )
        )

        REM Now NewFileNameExt is guaranteed to be unique, proceed with renaming
        rem echo Final NewFileNameExt: !NewFileNameExt!
        ren "!OriginalPathFileNameExt!" "!NewFileNameExt!"

        REM Check if the rename operation was successful
        if !errorlevel! equ 0 (
            echo Renamed to "!NewFileNameExt!" from "!OriginalPathFileNameExt!".
        ) else (
            echo Error renaming "!OriginalPathFileNameExt!" to "!NewFileNameExt!".
        )

        REM Update FileAccessDate and FileCreateDate using the extracted BestDate
        !exifToolPath! -overwrite_original "-FileModifyDate=!BestDate!" "-FileCreateDate=!BestDate!" "!FilePath!!NewFileNameExt!"
    )
    
    REM Reset BestDate for the next iteration
    set "BestDate="
)

echo.
echo Press any key to exit...
pause >nul
