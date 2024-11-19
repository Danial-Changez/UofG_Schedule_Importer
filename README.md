# Parser for Guelph University Student's PDF Schedule

This Bash script processes a Guelph University student's schedule, downloaded as a PDF from WebAdvisor, and extracts key details. It organizes the extracted information into variables and aims to generate an `.ics` file for easy import into calendar applications such as Google Calendar, Apple Calendar, or Outlook.

## Table of Contents
- [Features](#features)
- [Goals](#goals)
- [Prerequisites](#prerequisites)
  - [Required Tools](#required-tools)
- [Usage](#usage)
  - [Steps to Run](#steps-to-run)
- [Example Input and Output](#example-input-and-output)
  - [Example Input (PDF Content)](#example-input-pdf-content)
  - [Example Output (Script Variables)](#example-output-script-variables)




## Features

1. **PDF Conversion**:
   - Converts the WebAdvisor PDF schedule into a plain text file using `pdftotext`.
   
2. **Data Parsing**:
   - Extracts course titles (e.g., `CIS*2520*0110: Data Structures`) into a `course_titles` array.
   - Extracts event details (e.g., lectures, labs, exams) into an `events` array.
   
3. **Output Display**:
   - Prints the parsed course titles and events for validation and review.


## Goals

1. **Store Schedule Data**:
   - Dynamically extract and organize course titles and event details (later to be separated accordingly into LEC, LAB, EXAM) into Bash variables.

2. **Generate `.ics` File**:
   - Format the parsed data into an iCalendar (`.ics`) file for easy import into calendar applications.

3. **Automation**:
   - Automate the parsing of Guelph University student schedules downloaded as PDFs from WebAdvisor.


## Prerequisites

### Required Tools

1. **`pdftotext`**:
   - A command-line tool for converting PDFs to plain text files.
   - Part of the `poppler-utils` package.

   **Installation Options**:

   #### For Linux/macOS:
   ```bash
   sudo apt install poppler-utils
   
   brew install poppler
   ```
   
   #### For Windows (via Chocolatey):
   - Install [Chocolatey](https://ultahost.com/knowledge-base/install-chocolatey-on-windows-10/) if it’s not already installed.
   - Follow the guide to set up Chocolatey on Windows.
   - Install `pdftotext` using Chocolatey:
     
     ```powershell
     choco install poppler
     ```
   - Ensure the `poppler` tools are available in your PATH by restarting your Git Bash or terminal.

2. **Bash**:
   - The script requires a Bash-compatible shell (e.g., Git Bash on Windows, or Bash on Linux/macOS).

### Supported Input File
- The script processes Guelph University student's schedule downloaded as PDFs from WebAdvisor.

## Usage

### Steps to Run

1. **Run the Script**:
   ```bash
   ./script.sh
   ```
   
2. **Provide the PDF Path**:
   When prompted, enter the full path to your downloaded WebAdvisor schedule PDF:

   ```bash
   What is the file path of your schedule?
   ```
   
3. **View the Output**:
   The script will:
   - Extract and display course titles and their associated events in the terminal.
   - Example output:
     
     ```markdown
     -------------------
     Course: CIS*2520*0110: Data Structures
     Events: LEC MWF 1:30 PM - 2:20 PM LAB T 3:30 PM - 5:20 PM EXAM F 2:30 PM - 4:30 PM 
     -------------------

## Example Input and Output

### Example Input (PDF Content)

A typical schedule structure downloaded from WebAdvisor:

```
CIS*2520*0110: Data Structures
LEC MWF 1:30 PM - 2:20 PM 9/5/2024 - 12/13/2024
LAB T 3:30 PM - 5:20 PM 9/5/2024 - 12/13/2024
EXAM F 2:30 PM - 4:30 PM 12/6/2024 - 12/6/2024
```

### Example Output (Script Variables)

```bash
Course: CIS*2520*0110: Data Structures
Events: LEC MWF 1:30 PM - 2:20 PM LAB T 3:30 PM - 5:20 PM EXAM F 2:30 PM - 4:30 PM 
```


## Future Enhancements

1. **Generate `.ics` File**:
   - Automate the creation of an `.ics` file compatible with calendar applications.

2. **Error Handling**:
   - Handle invalid PDF files or missing schedule information.

3. **Automated Import to Calendar Apps**:
   - Explore ways to automate the process of importing `.ics` files into the user's calendar application, with a focus on Google Calendar.
   - Potential options include:
     - Providing a script to upload the `.ics` file via Google Calendar API.
     - Offering simple instructions for manual import if automation isn't possible.
