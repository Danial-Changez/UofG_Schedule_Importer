#!/bin/bash

# Prompt for schedule file
echo "What is the file path for your schedule?"
read path

sched_pdf="$path"
sched_txt="Schedule.txt"
sched_ics="Schedule.ics"
build_pdf="Building Abbreviations _ Scheduling.pdf"
build_txt="Building Abbreviations _ Scheduling.txt"

# Check if the schedule PDF exists
if [[ ! -f "$sched_pdf" ]]; then
    echo "Error: File '$sched_pdf' not found."
    exit 1
fi

# Convert PDFs to text
pdftotext "$sched_pdf" "$sched_txt"
pdftotext "$build_pdf" "$build_txt"

# Extract building codes
declare -a build_codes
while IFS= read -r line; do
    if [[ $line =~ ^Code ]]; then
        codes_part=$(echo "${line#Code }" | xargs)
        build_codes+=($codes_part)
    fi
done <"$build_txt"

# Create a regex pattern from building codes
build_codes_pattern="\\b($(
    IFS="|"
    echo "${build_codes[*]}"
))\\b"

# Initialize arrays and mappings
declare -a course_titles building room
declare -A day_map=(["M"]=1 ["T"]=2 ["W"]=3 ["Th"]=4 ["F"]=5)

# ICS content header
ics_content="BEGIN:VCALENDAR
VERSION:2.0
CALSCALE:GREGORIAN
"

# Extract course titles, building codes, and room numbers
while IFS= read -r line; do
    # Extract course titles
    if [[ $line =~ ^[A-Z]{3,4}\*[0-9]{4}\*.* ]]; then
        course_titles+=("$line")
    fi

    # Extract building and room information
    while [[ $line =~ (LEC|LAB|EXAM|Electronic)[[:space:]]([A-Z]+|TBD),[[:space:]]([^[:space:]]+|TBD) ]]; do
        building+=("${BASH_REMATCH[2]}")
        room+=("${BASH_REMATCH[3]}")
        line="${line#*"${BASH_REMATCH[0]}"}" # Remove matched portion
    done
done <"$sched_txt"

# Initialize indices
title_index=0
location_index=0

# Generate ICS events
while IFS= read -r line; do
    run=false
    while [[ $line =~ (LEC|LAB|EXAM)[[:space:]]([MTWThF]+)[[:space:]]([0-9:AMP\ \-]+)[[:space:]]([0-9/]+)[[:space:]]([0-9/]+) ]]; do
        run=true
        event_type="${BASH_REMATCH[1]}"
        days="${BASH_REMATCH[2]}"
        time_range="${BASH_REMATCH[3]}"
        start_date="${BASH_REMATCH[4]}"
        end_date="${BASH_REMATCH[5]}"

        # Parse start and end times
        if [[ $time_range =~ ^([0-9]+:[0-9]+[[:space:]]*[APM]+)[[:space:]]*[-]?[[:space:]]*([0-9]+:[0-9]+[[:space:]]*[APM]+)$ ]]; then
            start_time="${BASH_REMATCH[1]}"
            end_time="${BASH_REMATCH[2]}"
        else
            echo "Error parsing time range: $time_range"
            continue
        fi

        # Map days to ICS `BYDAY` format
        byday=""
        for ((i = 0; i < ${#days}; i++)); do
            day="${days:i:1}"
            [[ $day == "T" && ${days:i+1:1} == "h" ]] && day="Th" && ((i++))
            case "$day" in
            M) byday+="MO," ;;
            T) byday+="TU," ;;
            W) byday+="WE," ;;
            Th) byday+="TH," ;;
            F) byday+="FR," ;;
            esac
        done
        byday=${byday%,} # Remove trailing comma

        # Convert start and end dates to ICS format
        dtstart=$(date -d "$start_date $start_time" +"%Y%m%dT%H%M%S")
        dtend=$(date -d "$start_date $end_time" +"%Y%m%dT%H%M%S")
        until=$(date -d "$end_date 23:59:59" +"%Y%m%dT%H%M%S")

        # Add recurring event to ICS content
        ics_content+="BEGIN:VEVENT
UID:$(openssl rand -hex 16)
DTSTAMP:$(date -u +"%Y%m%dT%H%M%SZ")
DTSTART:$dtstart
DTEND:$dtend
RRULE:FREQ=WEEKLY;BYDAY=$byday;UNTIL=$until
SUMMARY:$event_type for ${course_titles[title_index]}
DESCRIPTION:$event_type session for ${course_titles[title_index]}
LOCATION:${building[location_index]} ${room[location_index]}
END:VEVENT
"
        ((location_index++))
        # Remove matched portion of the line for further processing
        line="${line#*"${BASH_REMATCH[0]}"}"
    done

    # Increment title index if events were processed
    if $run; then
        ((title_index++))
    fi
done <"$sched_txt"

# Finalize ICS content
ics_content+="END:VCALENDAR"

# Write ICS content to file
echo "$ics_content" >"$sched_ics"
echo "ICS file generated at $sched_ics"