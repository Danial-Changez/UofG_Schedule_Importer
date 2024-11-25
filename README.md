# Parser for Guelph University Student's PDF Schedule

This Bash script automates the process of converting a Guelph University student's schedule (downloaded as a PDF from WebAdvisor) into a `.ics` file for easy import into calendar applications such as Google Calendar, Apple Calendar, or Outlook. The script processes lectures, labs, and exams while efficiently handling recurring events to optimize performance.

## Table of Contents
- [Features](#features)
- [Goals](#goals)
- [Prerequisites](#prerequisites)
  - [Required Tools](#required-tools)
- [Usage](#usage)
  - [Steps to Run](#steps-to-run)
- [Example Input and Output](#example-input-and-output)
  - [Example Input (PDF Content)](#example-input-pdf-content)
  - [Example Output (ICS File)](#example-output-ics-file)
- [Performance](#performance)
- [Future Enhancements](#future-enhancements)

## Features

1. **PDF Conversion**:
   - Converts the WebAdvisor PDF schedule into a plain text file using `pdftotext`.

2. **Recurring Event Support**:
   - Generates optimized recurring events for lectures, labs, and exams using ICS `RRULE` format.

3. **Calendar Integration**:
   - Outputs an `.ics` file compatible with calendar applications like Google Calendar, Apple Calendar, and Outlook.

4. **Fast Execution**:
   - Efficient parsing and caching mechanisms ensure quick execution, even for complex schedules.

## Goals

1. **Automate Schedule Parsing**:
   - Extract and organize course titles and event details from the PDF into structured data.

2. **Generate `.ics` File**:
   - Automate the creation of a fully compliant iCalendar file for easy import into calendar applications.

3. **Optimize Performance**:
   - Handle recurring events to minimize file size and maximize processing speed.

## Prerequisites

### Required Tools

1. **`pdftotext`**:
   - A command-line tool for converting PDFs to plain text files.
   - Part of the `poppler-utils` package.

   **Installation Options**:

   #### For Linux/macOS:
   ```bash
   sudo apt install poppler-utils
   ```

   #### For Windows (via Chocolatey):
   - Install [Chocolatey](https://ultahost.com/knowledge-base/install-chocolatey-on-windows-10/) if it’s not already installed.
   - Install `pdftotext` using Chocolatey:
     ```powershell
     choco install poppler
     ```

2. **Bash**:
   - The script requires a Bash-compatible shell (e.g., Git Bash on Windows, or Bash on Linux/macOS).

---

## Usage

### Steps to Run

1. **Run the Script**:
   ```bash
   ./script.sh
   ```

2. **Provide the PDF Path**:
   When prompted, enter the full path to your downloaded WebAdvisor schedule PDF.

3. **View the Output**:
   - The script will generate a `Schedule.ics` file in the current directory.

## Example Input and Output

### Example Input (PDF Content)

A typical schedule structure downloaded from WebAdvisor:

```
CIS*2520*0110: Data Structures
LEC MWF 1:30 PM - 2:20 PM 9/5/2024 - 12/13/2024
LAB T 3:30 PM - 5:20 PM 9/5/2024 - 12/13/2024
EXAM F 2:30 PM - 4:30 PM 12/6/2024 - 12/6/2024
```

### Example Output (ICS File)

```ics
BEGIN:VCALENDAR
VERSION:2.0
CALSCALE:GREGORIAN
BEGIN:VEVENT
UID:abcd1234
DTSTAMP:20230901T123456Z
DTSTART:20230905T133000
DTEND:20230905T142000
RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR;UNTIL=20231213T235959Z
SUMMARY:Lecture for CIS*2520*0110
DESCRIPTION:Lecture session for CIS*2520*0110
LOCATION:Mackinnon Building Room 101
END:VEVENT
END:VCALENDAR
```

## Performance

### Execution Time
- The script is optimized for performance and can process schedules in less than **2 seconds** for typical inputs.

## Future Enhancements

1. **Error Handling**:
   - Improve validation for missing or malformed input files.

2. **Additional Features**:
   - Add support for holidays or exceptions in the schedule.

3. **Improved User Interface** (**With Help from Matthew Jarzynowski**):
   - Provide clearer prompts and progress messages for users.
