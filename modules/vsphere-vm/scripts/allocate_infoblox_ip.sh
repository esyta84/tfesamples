#!/bin/bash
# Script to allocate an IP address from Infoblox using the REST API
# This script is used as an external data source in Terraform

# Read input from stdin
eval "$(jq -r '@sh "GRID_HOST=\(.grid_host) USERNAME=\(.username) PASSWORD=\(.password) NETWORK=\(.network) NETWORK_VIEW=\(.network_view) HOSTNAME=\(.hostname) DOMAIN=\(.domain) TENANT_ID=\(.tenant_id) VM_NAME=\(.vm_name) OS_TYPE=\(.os_type) EXT_ATTRS=\(.ext_attrs)"')"

# Set defaults for optional parameters
NETWORK_VIEW=${NETWORK_VIEW:-"default"}
DOMAIN=${DOMAIN:-""}
TENANT_ID=${TENANT_ID:-""}

# Ensure required parameters are provided
if [ -z "$GRID_HOST" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$NETWORK" ]; then
    echo '{"error": "Missing required parameters"}' >&2
    exit 1
fi

# Construct FQDN if domain is provided
if [ -n "$DOMAIN" ]; then
    FQDN="${HOSTNAME}.${DOMAIN}"
else
    FQDN="${HOSTNAME}"
fi

# Extract network address and CIDR
NETWORK_ADDR=$(echo $NETWORK | cut -d'/' -f1)
CIDR=$(echo $NETWORK | cut -d'/' -f2)

# Prepare extensible attributes JSON if provided
EXT_ATTRS_JSON=""
if [ -n "$EXT_ATTRS" ] && [ "$EXT_ATTRS" != "null" ]; then
    # Convert from escaped JSON to proper format for API
    EXT_ATTRS_OBJ=$(echo $EXT_ATTRS | jq -c '.')
    
    # Build extensible attributes JSON structure
    EXT_ATTRS_JSON='"extattrs": {'
    
    # Process each attribute
    FIRST=true
    for key in $(echo $EXT_ATTRS_OBJ | jq -r 'keys[]'); do
        value=$(echo $EXT_ATTRS_OBJ | jq -r --arg k "$key" '.[$k]')
        
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            EXT_ATTRS_JSON+=", "
        fi
        
        EXT_ATTRS_JSON+="\"$key\": {\"value\": \"$value\"}"
    done
    
    EXT_ATTRS_JSON+='}, '
fi

# Add comment for tracking
COMMENT="Created by Terraform vsphere-vm module for VM ${VM_NAME} (${OS_TYPE})"

# Create request body to allocate next available IP
REQUEST_BODY="{
    \"network\": \"${NETWORK}\",
    \"network_view\": \"${NETWORK_VIEW}\",
    ${EXT_ATTRS_JSON}
    \"comment\": \"${COMMENT}\"
}"

# Use tenant context if provided
TENANT_HEADER=""
if [ -n "$TENANT_ID" ]; then
    TENANT_HEADER="-H \"X-NIOS-Tenant-Id: ${TENANT_ID}\""
fi

# Make the API call to allocate the IP
RESPONSE=$(curl -s -k -u "${USERNAME}:${PASSWORD}" \
    -H "Content-Type: application/json" \
    ${TENANT_HEADER} \
    -X POST \
    -d "${REQUEST_BODY}" \
    "https://${GRID_HOST}/wapi/v2.11/network?_function=next_available_ip")

# Check for errors
if echo "$RESPONSE" | grep -q "Error"; then
    echo "{\"error\": $(echo $RESPONSE | jq -c '.text')}" >&2
    exit 1
fi

# Extract the allocated IP
IPV4_ADDRESS=$(echo $RESPONSE | jq -r '.ips[0]')

if [ -z "$IPV4_ADDRESS" ] || [ "$IPV4_ADDRESS" == "null" ]; then
    echo '{"error": "Failed to allocate IP address"}' >&2
    exit 1
fi

# Output the result as JSON
jq -n --arg ipv4_address "$IPV4_ADDRESS" --arg hostname "$HOSTNAME" --arg fqdn "$FQDN" '{"ipv4_address": $ipv4_address, "hostname": $hostname, "fqdn": $fqdn}'