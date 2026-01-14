@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

set "scriptDir=%~dp0"
set "exifTool=%scriptDir%bin\ExifTool\exiftool.exe"
set "kmlFile=%scriptDir%geotags.kml"

if not exist "%exifTool%" (
    echo ExifTool not found: "%exifTool%"
    pause
    exit /b 1
)

REM Start KML
(
    echo ^<?xml version="1.0" encoding="UTF-8"?^>
    echo ^<kml xmlns="http://www.opengis.net/kml/2.2"^>
    echo   ^<Document^>
) > "%kmlFile%"

REM Loop over each image
for %%I in (%*) do (
    set "img=%%~fI"
    set "gpslat="
    set "gpslon="
    set "datetime="

    for /f "usebackq delims=" %%A in (`"%exifTool%" -s3 -GPSLatitude "%%~fI"`) do set "gpslat=%%A"
    for /f "usebackq delims=" %%A in (`"%exifTool%" -s3 -GPSLongitude "%%~fI"`) do set "gpslon=%%A"
    for /f "usebackq delims=" %%A in (`"%exifTool%" -s3 -DateTimeOriginal "%%~fI"`) do set "datetime=%%A"

    if defined gpslat if defined gpslon (
        echo Processing: %%~nxI
        (
            echo     ^<Placemark^>
            echo       ^<name^>%%~nxI^</name^>
            if defined datetime echo       ^<TimeStamp^>^<when^>!datetime!^</when^>^</TimeStamp^>
            echo       ^<Point^>
            echo         ^<coordinates^>!gpslon!,!gpslat!,0^</coordinates^>
            echo       ^</Point^>
            echo     ^</Placemark^>
        ) >> "%kmlFile%"
    ) else (
        echo Skipping %%~nxI - No GPS data
    )
)

REM End KML
(
    echo   ^</Document^>
    echo ^</kml^>
) >> "%kmlFile%"

echo.
echo ✅ Done. KML saved to: "%kmlFile%"
pause
