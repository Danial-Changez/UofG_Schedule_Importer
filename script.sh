#!/bin/bash

echo "What is the file path for your schedule?"
read path

# Paths and filenames
sched_pdf="$path"
sched_txt="Schedule.txt"
sched_ics="Schedule.ics"
build_pdf="Building Abbreviations _ Scheduling.pdf"
build_txt="Building Abbreviations _ Scheduling.txt"

# Arrays for course titles, buildings, and rooms
declare -a course_titles
declare -a building
declare -a room

# Day mapping
declare -A day_map=(["M"]=1 ["T"]=2 ["W"]=3 ["Th"]=4 ["F"]=5)

# Ensure the schedule PDF exists
if [ ! -f "$sched_pdf" ]; then
    echo "Error: File '$sched_pdf' not found"
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

# Start the ICS file content
ics_content="BEGIN:VCALENDAR
VERSION:2.0
CALSCALE:GREGORIAN
"

# Parse schedule text to populate course_titles, building, and room arrays
while IFS= read -r line; do
    # Identify and store course titles
    if [[ $line =~ ^[A-Z]{3,4}\*[0-9]{4}\*.* ]]; then
        course_titles+=("$line")
        continue
    fi

    # Extract building and room information
    while [[ $line =~ (LEC|LAB|EXAM|Electronic)[[:space:]]([A-Z]+|TBD),[[:space:]]([^[:space:]]+|TBD) ]]; do
        building+=("${BASH_REMATCH[2]}")
        room+=("${BASH_REMATCH[3]}")
        line="${line#*"${BASH_REMATCH[0]}"}"
    done
done <"$sched_txt"

# Debug: Check arrays
echo "Debug: course_titles: ${course_titles[@]}"
echo "Debug: building: ${building[@]}"
echo "Debug: room: ${room[@]}"

# Function to process a single line of the schedule file
process_line() {
    local line="$1"
    local local_ics_content=""
    local location_index=0

    # Match event details (e.g., LEC, LAB, EXAM)
    if [[ $line =~ (LEC|LAB|EXAM)[[:space:]]([MTWThF]+)[[:space:]]([0-9:AMP\ \-]+)[[:space:]]([0-9/]+)[[:space:]]([0-9/]+) ]]; then
        local event_type="${BASH_REMATCH[1]}"
        local days="${BASH_REMATCH[2]}"
        local time_range="${BASH_REMATCH[3]}"
        local start_date="${BASH_REMATCH[4]}"
        local end_date="${BASH_REMATCH[5]}"

        # Parse start and end times
        if [[ $time_range =~ ^([0-9]+:[0-9]+[[:space:]]*[APM]+)[[:space:]]*[-]?[[:space:]]*([0-9]+:[0-9]+[[:space:]]*[APM]+)$ ]]; then
            local start_time="${BASH_REMATCH[1]}"
            local end_time="${BASH_REMATCH[2]}"
        else
            echo "Error parsing time range: $time_range"
            return
        fi

        # Map days of the week to numeric values
        local event_day_numbers=()
        for ((i = 0; i < ${#days}; i++)); do
            local day="${days:i:1}"
            [[ $day == "T" && ${days:i+1:1} == "h" ]] && day="Th" && ((i++))
            event_day_numbers+=("${day_map[$day]}")
        done

        # Iterate through date range
        local start_timestamp=$(date -d "$start_date" +%s)
        local end_timestamp=$(date -d "$end_date" +%s)

        while [ "$start_timestamp" -le "$end_timestamp" ]; do
            local day_of_week=$(date -d "@$start_timestamp" +%u)
            if [[ " ${event_day_numbers[@]} " =~ " $day_of_week " ]]; then
                local formatted_date=$(date -d "@$start_timestamp" +"%Y-%m-%d")
                local dtstart=$(date -d "$formatted_date $start_time" +"%Y%m%dT%H%M%S")
                local dtend=$(date -d "$formatted_date $end_time" +"%Y%m%dT%H%M%S")
                local dtstamp=$(date -u +"%Y%m%dT%H%M%S")

                # Add event to local ICS content
                local_ics_content+=$(
                    printf "BEGIN:VEVENT\nUID:%s\nDTSTAMP:%s\nDTSTART:%s\nDTEND:%s\nSUMMARY:%s for %s\nDESCRIPTION:%s session for %s\nLOCATION:%s %s\nEND:VEVENT\n" \
                        "$(openssl rand -hex 16)" "$dtstamp" "$dtstart" "$dtend" \
                        "$event_type" "${course_titles[title_index]}" \
                        "$event_type" "${course_titles[title_index]}" \
                        "${building[location_index]}" "${room[location_index]}"
                )
            fi
            start_timestamp=$((start_timestamp + 86400)) # Increment by one day
        done
        ((location_index++))
    fi

    # Return the local ICS content
    echo "Local Content: $local_ics_content"
}

# Sequential or Parallel Processing
if $use_parallel; then
    echo "Using parallel processing..."
    export -f process_line
    export day_map course_titles building room
    ics_content+=$(cat "$sched_txt" | xargs -P "$parallel_jobs" -I{} bash -c 'process_line "$@"' _ {})
    ((title_index++))
else
    echo "Using sequential processing..."
    while IFS= read -r line; do
        ics_content+=$(process_line "$line")
        ((title_index++))
    done <"$sched_txt"
fi

# Close the ICS content
ics_content+="END:VCALENDAR"

# Write ICS content to file
echo "$ics_content" >"$sched_ics"
echo "ICS file generated at $sched_ics"
