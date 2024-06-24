#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is required but it's not installed. Please install jq and try again."
    exit 1
fi

# Check if the scan file exists
if [ ! -f "scan.txt" ]; then
    echo "The scan file 'scan.txt' does not exist. Please provide the scan file."
    exit 1
fi

# Function to parse the scan file and generate JSON
parse_scan_to_json() {
    local scan_file=$1
    local json_output="["

    while IFS= read -r line; do
        if [[ $line =~ ^Nmap\ scan\ report\ for\ (.*) ]]; then
            if [[ "$json_output" != "[" ]]; then
                json_output="${json_output}]},"
            fi
            target=${BASH_REMATCH[1]}
            json_output="${json_output}{\"target\": \"$target\", \"ports\": ["
            first_port=true
        elif [[ $line =~ ^Host\ is\ up ]]; then
            continue
        elif [[ $line =~ ^PORT ]]; then
            continue
        elif [[ $line =~ ^([0-9]+)/tcp\ +(open|closed|filtered)\ +([a-zA-Z0-9-]+)\ +(.*)$ ]]; then
            port=${BASH_REMATCH[1]}
            state=${BASH_REMATCH[2]}
            service=${BASH_REMATCH[3]}
            version=${BASH_REMATCH[4]}
            if [ "$first_port" = false ]; then
                json_output="${json_output},"
            fi
            first_port=false
            json_output="${json_output}{\"port\": \"$port\", \"state\": \"$state\", \"service\": \"$service\", \"version\": \"$version\"}"
        elif [[ $line =~ ^Service\ Info:\ OS:\ (.*) ]]; then
            os_info=${BASH_REMATCH[1]}
            json_output="${json_output}], \"os_info\": \"$os_info\"}"
        fi
    done < "$scan_file"

    json_output="${json_output}]}]"

    # Format the JSON output
    echo "$json_output" | jq .
}

# Parse the scan file and generate JSON output
parse_scan_to_json "scan.txt"
