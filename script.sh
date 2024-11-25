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

# Detect the number of CPU cores for parallel processing
if command -v nproc &>/dev/null; then
    cpu_cores=$(nproc --all) # For Linux and WSL
elif [[ "$OSTYPE" == "darwin"* ]]; then
    cpu_cores=$(sysctl -n hw.ncpu) # For macOS
else
    cpu_cores=1 # Default to single-core if detection fails
fi

# Determine the number of parallel jobs
if [ "$cpu_cores" -gt 1 ]; then
    parallel_jobs=$((cpu_cores - 1)) # Use one less than the total cores
else
    parallel_jobs=1 # Fall back to single-threaded execution
fi

# Notify the user about processing mode
if command -v xargs &>/dev/null && [ "$parallel_jobs" -gt 1 ]; then
    echo "Using $parallel_jobs parallel jobs for processing."
    use_parallel=true
else
    echo "Parallel processing not available, falling back to sequential execution."
    use_parallel=false
fi

# Convert PDFs to text for processing
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

# Create a regex pattern for matching building codes
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
            local start_time="${BASH_REMATCH[1]}"
            local end_time="${BASH_REMATCH[2]}"
        else
            echo "Error parsing time range: $time_range"
            return
        fi

        # Map days to ICS `BYDAY` format
        byday=""
        for ((i = 0; i < ${#days}; i++)); do
            local day="${days:i:1}"
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
