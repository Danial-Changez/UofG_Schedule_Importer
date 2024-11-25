# Parser for Guelph University Student's PDF Schedule

This Bash script processes a Guelph University student's schedule (downloaded as a PDF from WebAdvisor) and extracts key details. It generates a `.ics` file for seamless import into calendar applications such as Google Calendar, Apple Calendar, or Outlook.

## Table of Contents
- [Features](#features)
- [Goals](#goals)
- [Prerequisites](#prerequisites)
  - [Required Tools](#required-tools)
- [Usage](#usage)
  - [Steps to Run](#steps-to-run)
- [Example Input and Output](#example-input-and-output)
  - [Example Input (PDF Content)](#example-input-pdf-content)
  - [Example Output (`.ics` File)](#example-output-ics-file)
- [Future Enhancements](#future-enhancements)

## Features

1. **PDF Conversion**:
   - Converts the WebAdvisor schedule PDF into a plain text format using `pdftotext`.

2. **Data Parsing**:
   - Extracts course titles, event details (e.g., lectures, labs, exams), and time ranges.
   - Handles both building names and room numbers.

3. **`.ics` File Generation**:
   - Outputs an iCalendar (`.ics`) file containing all course events.
   - Supports multiple calendar applications for easy import.

4. **Dynamic Parallel Processing**:
   - Utilizes multiple CPU cores (if available) to process the schedule faster.
   - Automatically detects system capabilities and falls back to sequential execution when necessary.

5. **Cross-Platform Compatibility**:
   - Works on Linux, macOS, and Windows (via Git Bash or WSL).

## Goals

1. **Efficient Schedule Parsing**:
   - Extract and structure course titles and events from WebAdvisor schedules.

2. **Calendar Integration**:
   - Automate the generation of `.ics` files for easy import into calendar applications.

3. **User-Friendliness**:
   - Ensure the script is straightforward to use, even for those with limited technical knowledge.


## Prerequisites

### Required Tools

1. **`pdftotext`**:
   - Converts PDF files to plain text for processing.
   - Part of the `poppler-utils` package.

   **Installation**:
   - **Linux/macOS**:
     ```bash
     sudo apt install poppler-utils   # For Linux
     brew install poppler            # For macOS
     ```
   - **Windows (via Chocolatey)**:
     ```powershell
     choco install poppler
     ```

2. **Bash Shell**:
   - Required to run the script.
   - **Windows**: Install [Git Bash](https://gitforwindows.org/) or use Windows Subsystem for Linux (WSL).
   - **Linux/macOS**: Bash is pre-installed.

## Usage

### Steps to Run

1. **Download Your Schedule**:
   - Export your schedule as a PDF from Guelph University's WebAdvisor system.

2. **Run the Script**:
   - Open your terminal and run the script:
     ```bash
     ./script.sh
     ```

3. **Enter the Schedule Path**:
   - When prompted, enter the full file path to your downloaded PDF:
     ```plaintext
     What is the file path of your schedule?
     ```

4. **Wait for Processing**:
   - The script processes the schedule and generates an `.ics` file.
   - If your system has multiple CPU cores, the script will process the schedule in parallel for faster execution.

5. **Locate Your `.ics` File**:
   - Once complete, the `.ics` file will be saved in the same directory as the script:
     ```plaintext
     ICS file generated at Schedule.ics
     ```

6. **Import the `.ics` File**:
   - Import the `.ics` file into your preferred calendar application:
     - **Google Calendar**: [How to Import `.ics` Files](https://support.google.com/calendar/answer/37118?hl=en).
     - **Apple Calendar**: Drag and drop the file into the Calendar app.
     - **Outlook**: Go to `File > Open & Export > Import/Export`.

## Example Input and Output

### Example Input (PDF Content)

A typical schedule from WebAdvisor might look like this:

```plaintext
CIS*2520*0110: Data Structures
LEC MWF 1:30 PM - 2:20 PM 9/5/2024 - 12/13/2024
LAB T 3:30 PM - 5:20 PM 9/5/2024 - 12/13/2024
EXAM F 2:30 PM - 4:30 PM 12/6/2024 - 12/6/2024
```

### Example Output (`.ics` File)

The generated `.ics` file will look like this:

```plaintext
BEGIN:VCALENDAR
VERSION:2.0
CALSCALE:GREGORIAN
BEGIN:VEVENT
UID:80b12ad2e8273f9b6dbeebef9a027cea
DTSTAMP:20241125T024329Z
DTSTART:20240906T133000
DTEND:20240906T142000
SUMMARY:LEC for CIS*2520*0110: Data Structures
DESCRIPTION:LEC session for CIS*2520*0110: Data Structures
LOCATION:MCKN 233
END:VEVENT
...
END:VCALENDAR
```

## Future Enhancements

1. **Advanced Error Handling**:
   - Better validation for input PDF files.
   - Warnings for unsupported or incorrectly formatted schedules.

3. **Automatic Calendar Integration**:
   - Explore options for directly uploading the `.ics` file to Google Calendar or other apps using APIs.

3. **Improved User Interface**: **(With help from Matthew Jarzynowski)**
   - Replace terminal-based prompts with a graphical user interface (GUI) for broader accessibility.