#!/bin/bash

echo "What is the file path of your schedule?"
read path

pdf="$path"
txt="Schedule.txt"
ics="Schedule.ics"
declare -a course_titles
declare -a events

# Check if file exists
if [ ! -f "$pdf" ]; then
    echo -e "Error: File '$pdf' not found\n"
    exit 1
fi

pdftotext "$pdf" "$txt"

event_details=""
current_course=""
# Read through the file line-by-line
while IFS= read -r line; do
    # Check if the line matches the course title format using grep
    if echo "$line" | grep -qE '^[A-Z]{3,4}\*[0-9]{4}\*[0-9]{1,4}.*'; then
        # Store the previous course's events (if any)
        if [ -n "$current_course" ]; then
            course_titles+=("$current_course")
            events+=("$event_details")
        fi

        # Start a new course
        current_course="$line"
        event_details=""  # Reset event details for the new course
    elif echo "$line" | grep -qE '(LEC|LAB|EXAM)'; then
        # Collect event details for the current course
        event_details+="$line "
    fi
done < "$txt"

# Add the last course and its events
if [ -n "$current_course" ]; then
    course_titles+=("$current_course")
    events+=("$event_details")
fi

# Output the results
for i in "${!course_titles[@]}"; do
    echo -e "-------------------"
    echo "Course: ${course_titles[i]}"
    echo "Events: ${events[i]}"
    echo "-------------------"
done
