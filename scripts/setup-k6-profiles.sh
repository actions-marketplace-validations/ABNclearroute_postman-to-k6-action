#!/bin/bash

# Script to parse load profile YAML and generate k6 execution flags
# Usage: setup-k6-profiles.sh <profile-name> <profiles-yaml-path>

set -e

PROFILE_NAME="${1:-smoke}"
PROFILES_YAML="${2:-profiles/load-profiles.yaml}"

if [ ! -f "$PROFILES_YAML" ]; then
    echo "Error: Profile configuration file not found at $PROFILES_YAML"
    exit 1
fi

# Check if yq is available (for parsing YAML)
if ! command -v yq &> /dev/null; then
    echo "Installing yq for YAML parsing..."
    curl -sSfL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /tmp/yq
    chmod +x /tmp/yq
    YQ="/tmp/yq"
else
    YQ="yq"
fi

# Extract profile configuration
PROFILE_CONFIG=$($YQ eval ".profiles.$PROFILE_NAME" "$PROFILES_YAML")

if [ "$PROFILE_CONFIG" == "null" ] || [ -z "$PROFILE_CONFIG" ]; then
    echo "Error: Profile '$PROFILE_NAME' not found in $PROFILES_YAML"
    echo "Available profiles: $($YQ eval '.profiles | keys | join(", ")' "$PROFILES_YAML")"
    exit 1
fi

echo "Loading profile: $PROFILE_NAME"
echo "$PROFILE_CONFIG" | $YQ eval - > /tmp/profile_config.yaml

# Generate k6 options file with stages
cat > /tmp/k6-options.js << 'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

export const options = {
  stages: STAGES_PLACEHOLDER,
  thresholds: THRESHOLDS_PLACEHOLDER,
};

export default function () {
  // Main test function will be generated from Postman collection
}
EOF

# Build stages array from YAML
STAGES_JSON="["
STAGE_COUNT=$($YQ eval '.profiles.'"$PROFILE_NAME"'.stages | length' "$PROFILES_YAML")

for ((i=0; i<$STAGE_COUNT; i++)); do
    if [ $i -gt 0 ]; then
        STAGES_JSON+=","
    fi
    
    DURATION=$($YQ eval '.profiles.'"$PROFILE_NAME"'.stages['"$i"'].duration' "$PROFILES_YAML")
    TARGET=$($YQ eval '.profiles.'"$PROFILE_NAME"'.stages['"$i"'].target' "$PROFILES_YAML")
    
    STAGE="{ duration: '$DURATION', target: $TARGET"
    
    RAMP_UP=$($YQ eval '.profiles.'"$PROFILE_NAME"'.stages['"$i"'].rampUp' "$PROFILES_YAML" 2>/dev/null)
    if [ "$RAMP_UP" != "null" ] && [ -n "$RAMP_UP" ]; then
        STAGE+=", rampUp: '$RAMP_UP'"
    fi
    
    RAMP_DOWN=$($YQ eval '.profiles.'"$PROFILE_NAME"'.stages['"$i"'].rampDown' "$PROFILES_YAML" 2>/dev/null)
    if [ "$RAMP_DOWN" != "null" ] && [ -n "$RAMP_DOWN" ]; then
        STAGE+=", rampDown: '$RAMP_DOWN'"
    fi
    
    STAGE+=" }"
    STAGES_JSON+="$STAGE"
done

STAGES_JSON+="]"

# Build thresholds object from YAML
THRESHOLDS_JSON="{"
THRESHOLD_KEYS=$($YQ eval '.profiles.'"$PROFILE_NAME"'.thresholds | keys | .[]' "$PROFILES_YAML")

FIRST_THRESHOLD=true
for key in $THRESHOLD_KEYS; do
    if [ "$FIRST_THRESHOLD" = false ]; then
        THRESHOLDS_JSON+=","
    fi
    FIRST_THRESHOLD=false
    
    THRESHOLD_VALUES=$($YQ eval '.profiles.'"$PROFILE_NAME"'.thresholds.'"$key"' | .[]' "$PROFILES_YAML")
    THRESHOLDS_JSON+=" '$key': ["
    
    FIRST_VALUE=true
    for value in $THRESHOLD_VALUES; do
        if [ "$FIRST_VALUE" = false ]; then
            THRESHOLDS_JSON+=","
        fi
        FIRST_VALUE=false
        THRESHOLDS_JSON+=" '$value'"
    done
    
    THRESHOLDS_JSON+=" ]"
done

THRESHOLDS_JSON+=" }"

# Replace placeholders in k6 options file
sed -i "s|STAGES_PLACEHOLDER|$STAGES_JSON|g" /tmp/k6-options.js
sed -i "s|THRESHOLDS_PLACEHOLDER|$THRESHOLDS_JSON|g" /tmp/k6-options.js

echo "Generated k6 options file at /tmp/k6-options.js"
echo "Profile: $PROFILE_NAME loaded successfully"

