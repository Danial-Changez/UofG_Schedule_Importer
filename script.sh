#!/bin/bash

echo "What is the file path for your schedule?"
read path

# Paths and filenames
sched_pdf="$path"
sched_txt="Schedule.txt"
sched_ics="Schedule.ics"
build_pdf="Building Abbreviations _ Scheduling.pdf"
build_txt="Building Abbreviations _ Scheduling.txt"

# Arrays for course titles and building codes
declare -a course_titles
declare -a build_codes

# Day mapping (only needs to be declared once)
declare -A day_map
day_map=(["M"]=1 ["T"]=2 ["W"]=3 ["Th"]=4 ["F"]=5)

# Check if schedule PDF exists
if [ ! -f "$sched_pdf" ]; then
    echo -e "Error: File '$sched_pdf' not found"
    exit 1
fi

# Convert PDFs to text
pdftotext "$sched_pdf" "$sched_txt"
pdftotext "$build_pdf" "$build_txt"

# Load building codes into an array
while IFS= read -r line; do
    if [[ $line == Code* ]]; then
        build_codes+=(${line#Code }) # Extract codes after 'Code '
    fi
done <"$build_txt"

# Create a regex pattern from building codes
build_codes_pattern=$(
    IFS="|"
    echo "\b(${build_codes[*]})\b"
)

# Start the ICS file
cat >"$sched_ics" <<EOF
BEGIN:VCALENDAR
VERSION:2.0
CALSCALE:GREGORIAN
EOF

index=0
# Read the schedule file line by line
while IFS= read -r line; do
    # Identify course titles (e.g., CIS*2520*0110: Data Structures)
    if [[ $line =~ ^[A-Z]{3,4}\*[0-9]{4}\*.* ]]; then
        course_titles+=("$line")

    # Identify and process events like LEC, LAB, or EXAM
    elif [[ $line =~ (LEC|LAB|EXAM|Electronic) && ! $line =~ ONLINE ]]; then
        if [[ ! $line =~ $build_codes_pattern ]]; then
            # Extract matches for event details
            matches=$(echo "$line" | grep -oE '(LEC|LAB|EXAM)[[:space:]]([MTWThF]+)[[:space:]]([0-9:AMP\ \-]+)[[:space:]]([0-9/]+)[[:space:]]([0-9/]+)')
            while IFS= read -r match; do
                if [[ $match =~ (LEC|LAB|EXAM)[[:space:]]([MTWThF]+)[[:space:]]([0-9:AMP\ \-]+)[[:space:]]([0-9/]+)[[:space:]]([0-9/]+) ]]; then
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

                    # Extract days of the week
                    event_day_numbers=()
                    for ((i = 0; i < ${#days}; i++)); do
                        day="${days:i:1}"
                        [[ $day == "T" && ${days:i+1:1} == "h" ]] && day="Th" && ((i++)) # Handle 'Th'
                        event_day_numbers+=("${day_map[$day]}")
                    done

                    # Iterate through date range
                    current_date=$(date -I -d "$start_date")
                    end_date_iso=$(date -I -d "$end_date")
                    while [[ "$current_date" < $(date -I -d "$end_date + 1 day") ]]; do
                        day_of_week=$(date -d "$current_date" +%u)
                        if [[ " ${event_day_numbers[@]} " =~ " $day_of_week " ]]; then
                            dtstart=$(date -d "$current_date $start_time" +"%Y%m%dT%H%M%S")
                            dtend=$(date -d "$current_date $end_time" +"%Y%m%dT%H%M%S")
                            dtstamp=$(date -u +"%Y%m%dT%H%M%SZ")

                            # Add event to ICS file
                            cat >>"$sched_ics" <<EOF
BEGIN:VEVENT
UID:$(openssl rand -hex 16)
DTSTAMP:$dtstamp
DTSTART:$dtstart
DTEND:$dtend
SUMMARY:$event_type for '${course_titles[index]}'
DESCRIPTION:$event_type session for '${course_titles[index]}'
LOCATION:Room TBD
END:VEVENT
EOF
                        fi
                        current_date=$(date -I -d "$current_date + 1 day")
                    done
                fi
            done <<<"$matches"
            ((index++))
        fi
    fi
done <"$sched_txt"

# Close the ICS file
echo "END:VCALENDAR" >>"$sched_ics"

echo "ICS file generated at $sched_ics"
