#!/bin/bash

# Check if the schedule file path is provided as an argument
if [ -z "$1" ]; then
    echo "Error: No schedule file path provided."
    exit 1
fi

# Paths and filenames
sched_pdf="$1"
sched_txt="Schedule.txt"
sched_ics="Schedule.ics"
build_pdf="Building Abbreviations _ Scheduling.pdf"
build_txt="Building Abbreviations _ Scheduling.txt"

# Arrays for storing course titles, building names, and room numbers
declare -a course_titles
declare -a building
declare -a room

# Day mapping to numeric values for easier comparisons
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

# Determine the number of parallel jobs based on CPU cores
if [ "$cpu_cores" -gt 1 ]; then
    parallel_jobs=$((cpu_cores - 1)) # Use one less than the total cores to leave the system responsive
else
    parallel_jobs=1 # Fall back to single-threaded execution
fi

# Notify the user of the number of parallel jobs
echo "Using $parallel_jobs parallel jobs"

# Convert PDFs to text for processing
pdftotext "$sched_pdf" "$sched_txt"
pdftotext "$build_pdf" "$build_txt"

# Extract building codes from the building abbreviations file
declare -a build_codes
while IFS= read -r line; do
    if [[ $line =~ ^Code ]]; then
        # Extract building codes from lines starting with "Code"
        codes_part=$(echo "${line#Code }" | xargs)
        build_codes+=($codes_part)
    fi
done <"$build_txt"

# Create a regex pattern for matching building codes
build_codes_pattern="\\b($(
    IFS="|"
    echo "${build_codes[*]}"
))\\b"

# Start building the ICS file content
ics_content="BEGIN:VCALENDAR"

# Check if xargs is available and use it for parallel processing if possible
if command -v xargs &>/dev/null && [ "$parallel_jobs" -gt 1 ]; then
    # Export necessary variables and functions for parallel processing
    export -f process_line
    export day_map build_codes build_codes_pattern ics_content

    # Use xargs for parallel processing
    cat "$sched_txt" | xargs -P "$parallel_jobs" -I{} bash -c 'process_line "$@"' _ {}
else
    # Fall back to sequential processing if xargs is not available or parallelism is not supported
    echo "Parallel processing not available, falling back to sequential execution."
    while IFS= read -r line; do
        process_line "$line"
    done <"$sched_txt"
fi

# Close the ICS file content
ics_content+="END:VCALENDAR"

# Write all ICS content to the file at once
echo "$ics_content" >"$sched_ics"
echo "ICS file generated at $sched_ics"