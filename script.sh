#!/bin/bash

echo "What is the file path of your schedule?"
read path

sched_pdf="$path"
sched_txt="Schedule.txt"
sched_ics="Schedule.ics"

build_pdf="Building Abbreviations _ Scheduling.pdf"
build_txt="Building Abbreviations _ Scheduling.txt"

declare -a course_titles
declare -a events
declare -a build_codes

# Check if file exists
if [ ! -f "$sched_pdf" ]; then
    echo -e "Error: File '$sched_pdf' not found"
    exit 1
fi

# Convert PDFs to text
pdftotext "$sched_pdf" "$sched_txt"
pdftotext "$build_pdf" "$build_txt"

# Load building codes into an array
while IFS= read -r line; do
    if [ $line == Code* ]; then
        # Extract codes after 'Code' and split into array
        codes="${line#Code }" # Remove "Code " prefix
        build_codes+=($codes)
    fi
done < "$build_txt"

# Create a single regex pattern from building codes rather than looping
build_codes_pattern=$(IFS="|"; echo "\b(${build_codes[*]})\b") # Join with '|' and add word boundaries

# Read the schedule file line by line
while IFS= read -r line; do
    # Check if the line matches the course title format (replaced grep as it increased execution time exponentially)
    if [[ $line =~ ^[A-Z]{3,4}\*[0-9]{4}\*[0-9]{1,4}.* ]]; then
        # Store the previous course's events (if any)
            course_titles+=("$line")
    elif [[ $line =~ (LEC|LAB|EXAM) ]]; then
        # Check if the line matches the building code pattern
        if [[ ! $line =~ $build_codes_pattern ]]; then
            events+=("$line")
        fi
    fi
done < "$sched_txt"

# Output the results
for i in "${!course_titles[@]}"; do
    echo -e "-------------------"
    echo "Course: ${course_titles[i]}"
    echo "Events: ${events[i]}"
    echo "-------------------"
done
