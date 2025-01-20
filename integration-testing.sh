#!/bin/bash
echo "Integration test......."

# Check AWS CLI version
aws --version

# Fetch all EC2 instances and store the output
Data=$(aws ec2 describe-instances)
echo "Data = $Data"

# Extract URL or IP of an EC2 instance with the tag "dev-deploy"
URL=$(aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | select(.Tags[].Value == "app-dev") | .PublicIpAddress')
echo "URL Data - $URL"

# Check if URL was retrieved
if [[ "$URL" != '' ]]; then
    # Fetch the HTTP status code of the /live endpoint
    http_code=$(curl -s -o /dev/null -w "%{http_code}" http://$URL:3000/live)
    echo "http_code - $http_code"

    # Fetch data from the /planet endpoint
    planet_data=$(curl -s -XPOST http://$URL:3000/planet -H "Content-Type: application/json" -d '{"id": "3"}')
    echo "planet_data - $planet_data"

    # Extract the name field from the JSON response
    planet_name=$(echo $planet_data | jq .name -r)
    echo "planet_name - $planet_name"

    # Verify the HTTP status code and planet name
    if [[ $http_code -eq 200 && $planet_name == "Earth" ]]; then
        echo "HTTP Status Code and Planet Name Tests Passed"
    else
        echo "One or more test(s) failed"
        exit 1
    fi
else
    echo "Could not fetch a token/URL; Check/Debug line 6"
    exit 1
fi
