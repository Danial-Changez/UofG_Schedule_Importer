extract_building_codes() {
    local fp="$1"
    local codes_part="", build_codes_pattern
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

    echo $build_codes_pattern
}

parse_schedule() {
    local input_file=$1
    local output_file=$2
    local current_course=""
    local column=""
    local key=""
    declare -A schedule_data

    # Read through non-empty lines
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Detect course titles
        if [[ $line =~ ([A-Z]{3,4}\*[0-9]{4}\*[0-9]{2,4}) ]]; then
            current_course="${BASH_REMATCH[1]}"
            column="title"
            schedule_data["$current_course"]=""
            continue
        fi

        # Detect time or location details (associated with the current course)
        if [[ $line =~ ([A-Z]+,\ [[:alnum:]]+) ]]; then
            column="location"
            schedule_data["$current_course"]+="${line}\n"
            continue
        fi

        # Detect multi-line continuation
        if [[ -n $column && $line =~ ^\s ]]; then
            schedule_data["$current_course"]+="${line}\n"
            continue
        fi
    done <"$input_file"

    # Output parsed data
    echo -e "Parsed Schedule Data:\n" >"$output_file"
    for course in "${!schedule_data[@]}"; do
        echo -e "Course: $course\nDetails:\n${schedule_data[$course]}\n" >>"$output_file"
    done
}
