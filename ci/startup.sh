sleep 15

# Function to make HTTP POST request
make_post_request() {
    curl -X POST -s -H "Content-Type: application/json" -H "x-tyk-authorization: ${TYK_IB_TYKAPISETTINGS_GATEWAYCONFIG_ADMINSECRET//[$'\t\r\n ']}" -d "$2" "$1"
}

# Function to make HTTP GET request
make_get_request() {
    curl -X GET "$1" -s  -H "x-tyk-authorization: ${TYK_IB_TYKAPISETTINGS_GATEWAYCONFIG_ADMINSECRET//[$'\t\r\n ']}"
}

# Make POST request to check if Tyk is running
response=$(make_get_request "http://tyk-gateway/hello")

# Check response status and content
if [[ $(echo "$response" | jq -r '.status') != "pass" ]]; then
    echo "Tyk server is not running or the response is invalid."
    exit 1
fi

# Check if OAuth client "sycat-oauth" exists
response=$(make_get_request "http://tyk-gateway/tyk/oauth/clients/1")

if [[ ! "$response" == *"sycat-oauth"* ]]; then
	echo "Creating new OAuth Client"

    # Create new OAuth client
    create_client_response=$(make_post_request "http://tyk-gateway/tyk/oauth/clients/create" '{
        "client_id": "sycat-oauth",
        "policy_id": "default",
        "redirect_uri": "'"${FRONTEND_URI//[$'\t\r\n ']}"'"
    }')

    # Extract redirect_uri and secret from the response
    redirect_uri=$(echo "$create_client_response" | jq -r '.redirect_uri')
    secret=$(echo "$create_client_response" | jq -r '.secret')

    # Read JSON from "./identity-broker/profiles.json"
    json_file=/opt/tyk-identity-broker/profiles.json

    if [ -f "$json_file" ]; then
        # Read JSON file
        json_data=$(cat "$json_file")
		
        # Replace values for IdentityHandlerConfig.OAuth.Secret and IdentityHandlerConfig.OAuth.RedirectURI
        updated_data=$(echo "$json_data" | jq --arg redirect_uri "$redirect_uri" --arg secret "$secret" '.[].IdentityHandlerConfig.OAuth.Secret = $secret | .[].IdentityHandlerConfig.OAuth.RedirectURI = $redirect_uri')

        # Save updated JSON back to file
		echo "Saving profiles"
        echo "$updated_data" > "$json_file"
    fi
fi

# Call gateway reload
make_get_request "http://localhost:8080/tyk/reload"

/opt/tyk-identity-broker/tyk-identity-broker --conf=/opt/tyk-identity-broker/tib.conf