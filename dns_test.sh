#!/bin/bash

# Define a list of DNS servers to test (single or pairs)
dns_servers=(
  "8.8.8.8 8.8.4.4"                     # Google DNS
  "1.1.1.1 1.0.0.1"                     # Cloudflare DNS
  "9.9.9.9 149.112.112.112"             # Quad9
  "208.67.222.222 208.67.220.220"       # OpenDNS Home
  "76.76.2.0 76.76.10.0"                # Control D
  "185.228.168.9 185.228.169.9"         # CleanBrowsing
  "76.76.19.19 76.223.122.150"          # Alternate DNS
  "94.140.14.14 94.140.15.15"           # AdGuard DNS
  "8.26.56.26 8.20.247.20"              # Comodo Secure DNS
  "205.171.3.65 205.171.2.65"           # CenturyLink (Level3)
  "149.112.121.10 149.112.122.10"       # CIRA Canadian Shield
  "38.103.195.4 138.197.140.189"        # OpenNIC
  "216.146.35.35 216.146.36.36"         # Dyn
  "77.88.8.8 77.88.8.1"                 # Yandex DNS
  "74.82.42.42"                         # Hurricane Electric
  "94.130.180.225 78.47.64.161"         # DNS for Family
  "185.236.104.104 185.236.105.105"     # FlashStart
  "80.80.80.80 80.80.81.81"             # Freenom World
)


# Domain to query for testing DNS response
test_domain="example.org"


echo "Testing DNS response times..."

# Create a temporary file to store response times
temp_file=$(mktemp)

# Function to perform dig and write results
perform_dig() {
    local dns_entry=$1


    local total_time=0
    local dns_count=0
    local delim=""
    local joined=""
    local dns

    # Split the entry into individual addresses
    for dns in $dns_entry; do
        # Set a timeout of 1 second (1000 ms) for the dig command
        local response_time=$(dig +time=1 @$dns $test_domain +stats | grep 'Query time:' | awk '{print $4}')
        # If response time is empty or not a number, skip this DNS server
        if ! [[ $response_time =~ ^[0-9]+$ ]]; then
            echo "Skipping $dns due to timeout or invalid response time"
            continue 2
        fi
        total_time=$((total_time + response_time))
        dns_count=$((dns_count + 1))
        joined="$joined$delim$dns"
        delim="|"
    done

    if [ $dns_count -eq 0 ]; then
        continue
    fi

    # Calculate average response time
    local avg_time=$((total_time / dns_count))

    # Write the average response time and DNS entry to the temp file
    # Do not include 'ms' in the temp file to allow numeric sorting
    printf "%-50s %d\n" "$joined" "$avg_time" >> "$temp_file"

}

# Loop through the list of DNS servers (single or pairs) and test each
for dns_entry in "${dns_servers[@]}"; do
  perform_dig "$dns_entry" &
done

wait

echo "Ranking the DNS servers..."

# Sort the temp file by average response time and display the results
sort -k2 -n "$temp_file" | while read -r dns_entry avg_time; do
    printf "%-50s %-4d ms\n" "$dns_entry" "$avg_time"
done

# Remove the temporary file
rm "$temp_file"

echo "Ranking complete. The fastest DNS server (pair) is the best."
