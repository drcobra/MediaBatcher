# EXIFtagger 🏷️📸

A Windows Batch script for automating the tagging of photos and videos from different manufacturers.

## Problem 🚨

Devices from various manufacturers use different naming conventions for photos and videos, making it difficult to organize files and maintain a consistent time series across multiple captures. This issue is even more challenging when sharing media between users or devices.

## Solution ✅

EXIFtagger is a Windows batch script that reads and renames media files based on their metadata, organizing them in a time series format. The script leverages [ExifTool by Phil Harvey](https://exiftool.org/) to read and modify metadata.

⚠️ Note: This script only edits the metadata of the files; the actual content of the photos or videos is not modified.

## Installation ⚙️

1. ⬇️ Download the latest release from the [EXIFtagger releases page](https://github.com/drcobra/EXIFtagger/releases).
2. 📂 Create a directory called bin in your working directory.
3. 🔧 Download  exiftool-XX.XX_64.zip from https://exiftool.org/, extract the directory 'exiftool_files' and file 'exiftool(-k).exe', and place 'exiftool(-k).exe' in the bin directory. Rename the file to 'exiftool.exe'.

## Usage 🚀

1. 🖼️ Select multiple photos and videos that you want to tag.
2. 🖱️ Drag and drop the selected files onto the batch script.
3. ✔️ Once you confirm, the script will process each file, one by one.

### Different Uses ⚙️

#### PriorityTAG_Renamer.bat
This script renames files based on the date and time metadata tags. It follows a priority order to ensure the most accurate timestamp is used:
1. SubSecDateTimeOriginal
2. DateTimeOriginal
3. CreationDate
4. CreateDate
5. SubSecMediaCreateDate
6. MediaCreateDate
7. DateTimeCreated

Files are renamed using the first available tag in the list, ensuring proper chronological order based on the most precise metadata.

#### FileName2TAG.bat
This script updates the file's date and time metadata tags based on the filename. The filename should follow one of these formats:

- YYYY-MM-DD HH-MM-SS.mmm (e.g., 2024-08-17 20-05-18.012)
- YYYY-MM-DD HH-MM-SS.mmm XXXXXX (e.g., 2024-08-17 20-05-18.012 Vacation)

This allows for precise timestamp updates directly from the file name.

#### FileName2TAG_noTIME.bat
This script updates only the date metadata tags (no time) using the filename. The filename must be in this format:

- YYYY-MM-DD XXXXXX (e.g., 2024-08-17 SummerTrip)

It's useful when you only want to update the date of the file without altering the time.
