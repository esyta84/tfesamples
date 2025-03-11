#!/bin/bash
# Script to release an IP address from Infoblox using the REST API
# This script is used in the destroy provisioner in Terraform

# Get the IP address to release from the command line
IP_ADDRESS="$1"

# Source environment variables for Infoblox credentials
# These should be set in the environment or in a .env file
if [ -f "${PWD}/.env" ]; then
    source "${PWD}/.env"
fi

# Check for required environment variables
if [ -z "$INFOBLOX_GRID_HOST" ] || [ -z "$INFOBLOX_USERNAME" ] || [ -z "$INFOBLOX_PASSWORD" ]; then
    echo "Error: Missing required environment variables: INFOBLOX_GRID_HOST, INFOBLOX_USERNAME, INFOBLOX_PASSWORD" >&2
    exit 1
fi

# Check if IP address parameter was provided
if [ -z "$IP_ADDRESS" ]; then
    echo "Error: Missing IP address parameter" >&2
    exit 1
fi

# Set default network view if not provided
INFOBLOX_NETWORK_VIEW=${INFOBLOX_NETWORK_VIEW:-"default"}
INFOBLOX_DNS_VIEW=${INFOBLOX_DNS_VIEW:-"default"}

# Find the fixed address record for the IP
FIXED_ADDR_REF=$(curl -s -k -u "${INFOBLOX_USERNAME}:${INFOBLOX_PASSWORD}" \
    -H "Content-Type: application/json" \
    "https://${INFOBLOX_GRID_HOST}/wapi/v2.11/fixedaddress?ipv4addr=${IP_ADDRESS}&network_view=${INFOBLOX_NETWORK_VIEW}" | \
    jq -r '.[0]._ref')

# Find the A record for the IP
A_RECORD_REF=$(curl -s -k -u "${INFOBLOX_USERNAME}:${INFOBLOX_PASSWORD}" \
    -H "Content-Type: application/json" \
    "https://${INFOBLOX_GRID_HOST}/wapi/v2.11/record:a?ipv4addr=${IP_ADDRESS}&view=${INFOBLOX_DNS_VIEW}" | \
    jq -r '.[0]._ref')

# Find the PTR record for the IP
# Convert IP to reverse notation for PTR lookup
REVERSE_IP=$(echo $IP_ADDRESS | awk -F'.' '{print $4"."$3"."$2"."$1".in-addr.arpa"}')
PTR_RECORD_REF=$(curl -s -k -u "${INFOBLOX_USERNAME}:${INFOBLOX_PASSWORD}" \
    -H "Content-Type: application/json" \
    "https://${INFOBLOX_GRID_HOST}/wapi/v2.11/record:ptr?ptrdname~=${REVERSE_IP}&view=${INFOBLOX_DNS_VIEW}" | \
    jq -r '.[0]._ref')

# Delete the fixed address record if found
if [ -n "$FIXED_ADDR_REF" ] && [ "$FIXED_ADDR_REF" != "null" ]; then
    echo "Deleting fixed address record: $FIXED_ADDR_REF"
    curl -s -k -u "${INFOBLOX_USERNAME}:${INFOBLOX_PASSWORD}" \
        -H "Content-Type: application/json" \
        -X DELETE \
        "https://${INFOBLOX_GRID_HOST}/wapi/v2.11/${FIXED_ADDR_REF}"
else
    echo "No fixed address record found for IP ${IP_ADDRESS}"
fi

# Delete the A record if found
if [ -n "$A_RECORD_REF" ] && [ "$A_RECORD_REF" != "null" ]; then
    echo "Deleting A record: $A_RECORD_REF"
    curl -s -k -u "${INFOBLOX_USERNAME}:${INFOBLOX_PASSWORD}" \
        -H "Content-Type: application/json" \
        -X DELETE \
        "https://${INFOBLOX_GRID_HOST}/wapi/v2.11/${A_RECORD_REF}"
else
    echo "No A record found for IP ${IP_ADDRESS}"
fi

# Delete the PTR record if found
if [ -n "$PTR_RECORD_REF" ] && [ "$PTR_RECORD_REF" != "null" ]; then
    echo "Deleting PTR record: $PTR_RECORD_REF"
    curl -s -k -u "${INFOBLOX_USERNAME}:${INFOBLOX_PASSWORD}" \
        -H "Content-Type: application/json" \
        -X DELETE \
        "https://${INFOBLOX_GRID_HOST}/wapi/v2.11/${PTR_RECORD_REF}"
else
    echo "No PTR record found for IP ${IP_ADDRESS}"
fi

echo "IP address ${IP_ADDRESS} released successfully from Infoblox"