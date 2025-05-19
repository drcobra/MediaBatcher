@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
set PERL_UNICODE=SDA


REM Ensure exiftool.exe exists in the script directory
set "scriptDirectory=%~dp0"
set "exifToolPath=!scriptDirectory!bin\ExifTool\exiftool.exe"
set "DefaultUser=%USERNAME%"

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

    REM Determine the FileSource based on the file name structure
    setlocal enabledelayedexpansion
    set "FirstChar=!OriginalPathFileName:~0,4!"
    if "!FirstChar!" geq "1900" if "!FirstChar!" leq "2100" (
        set "FileSource=processed"
        echo FileSource: processed
    ) else (
        REM Check if the file name contains " - " (space-dash-space) using string substitution
        set "TempName=!OriginalPathFileName: - =!"
        if not "!TempName!"=="!OriginalPathFileName!" (
            REM Contains a dash, assume it's from dropbox
            set "FileSource=dropbox"
            echo FileSource: dropbox
        ) else (
            REM No dash, assume it's from mycamera
            set "FileSource=mycamera"
            echo FileSource: mycamera
            set "FirstName=!DefaultUser!"
        )
    )

    REM Extract FirstName based on FileSource
    if "!FileSource!"=="dropbox" (
        REM Extract the first part of the filename before the first dash (Dropbox)
        for /f "tokens=1 delims=-" %%m in ("!OriginalPathFileName!") do (
            set "FirstName=%%m"
            set "FirstName=!FirstName:~0,-1!"
        )
    ) else if "!FileSource!"=="processed" (
        REM Extract everything after the date and time (Processed)
        REM Remove the date, time, and optional milliseconds before extracting the name
        for /f "tokens=2,* delims= " %%m in ("!OriginalPathFileName!") do (
            set "FirstName=%%n"
        )
    )

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

        if "!BestDate:~19,1!"=="." (  REM if there are mili seconds
            set "SubSecPart=!BestDate:~20,3!"
        ) else (
            set "SubSecPart=000"
        )

        REM Normalize SubSecPart (microseconds)
        if "!SubSecPart!" neq "" (
            if "!SubSecPart:~0,1!"=="+" (  REM if the 1st mili is + timezone
                set "SubSecPart=000"
            ) else if "!SubSecPart:~0,1!"==" " (  REM if the 1st mili is space
                set "SubSecPart=000"
            ) else if "!SubSecPart:~1,1!"=="+" (  REM if the 2rd mili is + timezone
                set "SubSecPart=00!SubSecPart:~0,1!"
            ) else if "!SubSecPart:~1,1!"==" " (  REM if the 2rd mili is space
                set "SubSecPart=00!SubSecPart:~0,1!"
            ) else if "!SubSecPart:~1,1!"=="" (  REM if the 2rd mili is missing
                set "SubSecPart=00!SubSecPart:~0,1!"
            ) else if "!SubSecPart:~2,1!"=="+" (  REM if the 3rd mili is + timezone
                set "SubSecPart=0!SubSecPart:~0,2!"
            ) else if "!SubSecPart:~2,1!"==" " (  REM if the 3rd mili is space
                set "SubSecPart=0!SubSecPart:~0,2!"
            ) else if "!SubSecPart:~2,1!"=="" (  REM if the 3rd mili is missing
                set "SubSecPart=0!SubSecPart!"
            ) else (
                set "SubSecPart=!SubSecPart:~0,3!!"
            )
        ) else (
            set "SubSecPart=000"
        )
        
        set "FormattedDate=!DatePart:~0,4!-!DatePart:~5,2!-!DatePart:~8,2!"
        set "FormattedTime=!TimePart:~0,2!-!TimePart:~3,2!-!TimePart:~6,2!.!SubSecPart!"

        REM Construct the new filename with the original extension
		set "BaseFileName=!FormattedDate! !FormattedTime!"
        rem set "BaseFileName=!FormattedDate! !FormattedTime! !FirstName!"
        set "NewFileNameExt=!BaseFileName!!FileExtension!"
        rem echo !NewFileNameExt!


        REM Check if the new file name already exists, but skip if it's the same as the current file's name (case-insensitive)
        set "DuplicateCount=1"
        set "UniqueName=!NewFileNameExt!"
        set "FileExists=1"
        for %%d in (0 1 2 3 4 5 6 7 8 9) do (
            if exist "!FilePath!!UniqueName!" (
                set "UniqueName=!BaseFileName! DUPLICATE!DuplicateCount!!FileExtension!"
                set /a DuplicateCount+=1
                set "FileExists=1"
            ) else (
                set "FileExists=0"
                set "NewFileNameExt=!UniqueName!"
                break
            )
        )

        if "!FileExists!"=="1" (
            REM If all iterations failed, use the final unique name
            set "NewFileNameExt=!UniqueName!"
        )

        REM Now NewFileNameExt is guaranteed to be unique, proceed with renaming
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
