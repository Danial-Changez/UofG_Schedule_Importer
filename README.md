# Parser for Guelph University Student's PDF Schedule

This Bash script automates converting a University of Guelph student's schedule (downloaded as a PDF from WebAdvisor) into a `.ics` file for easy import into calendar applications such as Google, Apple, or Outlook Calendar. The script processes lectures, labs, and exams while handling recurring events to optimize performance.

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
   - Outputs a `.ics` file compatible with calendar applications like Google Calendar, Apple Calendar, and Outlook.

4. **Fast Execution**:
   - Efficient parsing and caching mechanisms ensure quick execution, even for complex schedules.

## Goals

1. **Automate Schedule Parsing**:
   - Extract and organize course titles and event details from the PDF into structured data.

2. **Generate `.ics` File**:
   - Automate the creation of an iCalendar file for easy import into calendar applications.

3. **Optimize Performance**:
   - Handle recurring events to minimize file size and reduce execution time.

## Prerequisites

### Required Tools

1. **`pdftotext`**:
   - Converts PDF files to plain text for processing.
   - Part of the `poppler-utils` package.

   #### Installation Options:
   **For Linux/macOS**:
     ```bash
     sudo apt install poppler-utils
     ```

   **For Windows (via Chocolatey)**:
   - Install [Chocolatey](https://ultahost.com/knowledge-base/install-chocolatey-on-windows-10/) if it’s not already installed.
   - Install `pdftotext` using Chocolatey:
     ```powershell
     choco install poppler
     ```

3. **Bash**:
   - The script requires a Bash-compatible shell (e.g., Git Bash on Windows, or Bash on Linux/macOS).

## Usage

### Steps to Run

1. **Download the Schedule PDF from WebAdvisor**:
   - Log in to **WebAdvisor** using your University of Guelph student account.
   - Navigate to the **Student Planning** section.
   - Select **Plan your Degree & Register for Classes**.
   - Locate the **Print** button on the page (as shown below) and click it:

     ![Print Button](https://github.com/user-attachments/assets/416127fa-d3ed-4fd6-b94a-cf27b476ba6a)

   - A new tab will open with your schedule in a printable format. Follow these steps to save it as a PDF:
     - Press **Ctrl + P** (or **Cmd + P** on Mac) to open the print dialog.
     - Change the **Destination** to **Save as PDF**.
     - Click **Save** to download the schedule:

       ![Save as PDF](https://github.com/user-attachments/assets/e0d6876f-b085-4f6d-8bb0-f4c538161292)

2. **Run the Script**:
   ```bash
   ./script.sh
   ```

3. **Provide the PDF Path**:
   When prompted, enter the full path to your downloaded WebAdvisor schedule PDF.

4. **View the Output**:
   - The script will generate a `Schedule.ics` file in the current directory.

## Example Input and Output

### Example Input (PDF Content)

A typical schedule from WebAdvisor might look like this:

```plaintext
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
  
3. **Implement Outlook and Google Calendar APIs**
   - Offer direct imports from the script into Outlook or Google Calendar using their respective APIs.

4. **Improved User Interface** (**With Help from Matthew Jarzynowski**):
   - Provide clearer prompts and progress messages for users.
