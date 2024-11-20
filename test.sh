#!/bin/bash

lines=(
    "LEC MWF 1:30 PM 2:20 PM 9/5/2024 12/13/2024"
    "LAB T 3:30 PM - 5:20 PM 9/5/2024 12/13/2024"
    "EXAM F 2:30 PM 4:30 PM 12/6/2024 12/6/2024"
    "LEC TTh 5:30 PM 6:50 PM 9/5/2024 12/13/2024 EXAM F 8:30 AM 10:30 AM 12/13/2024 12/13/2024"
)

for line in "${lines[@]}"; do
    # Extract matches using grep
    matches=$(echo "$line" | grep -oE '(LEC|LAB|EXAM)[[:space:]]([MTWThF]+)[[:space:]]([0-9:AMP\ \-]+)[[:space:]]([0-9/]+)[[:space:]]([0-9/]+)')

    while IFS= read -r match; do
        # Extract components using a separate regex in bash
        if [[ $match =~ (LEC|LAB|EXAM)[[:space:]]([MTWThF]+)[[:space:]]([0-9:AMP\ \-]+)[[:space:]]([0-9/]+)[[:space:]]([0-9/]+) ]]; then
            event_type="${BASH_REMATCH[1]}" # LEC, LAB, or EXAM
            days="${BASH_REMATCH[2]}"       # Days (e.g., MWF, TTh)
            time_range="${BASH_REMATCH[3]}" # Time range (e.g., 1:30 PM - 2:20 PM)
            start_date="${BASH_REMATCH[4]}" # Start date (e.g., 9/5/2024)
            end_date="${BASH_REMATCH[5]}"   # End date (e.g., 12/13/2024)

            echo "Event Type: $event_type"
            echo "Days: $days"
            echo "Time Range: $time_range"
            echo "Start Date: $start_date"
            echo "End Date: $end_date"
            echo "------------------"
        fi
    done <<<"$matches"
done
