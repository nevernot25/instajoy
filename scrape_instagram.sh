#!/bin/bash

# Instagram Scraper Script with AI Analysis
# Usage: ./scrape_instagram.sh <username> [anthropic_api_key]

USERNAME=${1:-villawillberg}
API_KEY="fbe3a9cfa7msh52125e1ddc815d8p1c9075jsn5a5afb01aefe"
ANTHROPIC_KEY=${2:-}
OUTPUT_FILE="${USERNAME}_instagram_data.txt"

echo "Scraping Instagram data for @${USERNAME}..."

# Fetch Profile Information
PROFILE_DATA=$(curl -s --request POST \
  --url https://instagram120.p.rapidapi.com/api/instagram/profile \
  --header 'Content-Type: application/json' \
  --header 'x-rapidapi-host: instagram120.p.rapidapi.com' \
  --header "x-rapidapi-key: ${API_KEY}" \
  --data "{\"username\":\"${USERNAME}\"}")

# Fetch Location/Extended Info
LOCATION_DATA=$(curl -s --request GET \
  --url "https://instagram-scraper-stable-api.p.rapidapi.com/get_ig_user_about.php?username_or_url=${USERNAME}" \
  --header 'x-rapidapi-host: instagram-scraper-stable-api.p.rapidapi.com' \
  --header "x-rapidapi-key: ${API_KEY}")

# Fetch Posts
POSTS_DATA=$(curl -s --request POST \
  --url https://instagram120.p.rapidapi.com/api/instagram/posts \
  --header 'Content-Type: application/json' \
  --header 'x-rapidapi-host: instagram120.p.rapidapi.com' \
  --header "x-rapidapi-key: ${API_KEY}" \
  --data "{\"username\":\"${USERNAME}\",\"maxId\":\"\"}")

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq not installed. Install with: brew install jq"
    exit 1
fi

# Extract data for AI analysis
FULL_NAME=$(echo "$PROFILE_DATA" | jq -r '.result.full_name // "N/A"')
BIOGRAPHY=$(echo "$PROFILE_DATA" | jq -r '.result.biography // "N/A"')
ALL_CAPTIONS=$(echo "$POSTS_DATA" | jq -r '.result.edges[]?.node.caption.text // ""' | head -20)

# AI Analysis
if [ -n "$ANTHROPIC_KEY" ]; then
    echo "Running AI analysis..."

    # Build prompt with proper escaping using jq
    PROMPT=$(jq -n \
        --arg name "$FULL_NAME" \
        --arg bio "$BIOGRAPHY" \
        --arg captions "$ALL_CAPTIONS" \
        '"Analyze this Instagram account and provide:\n1. Account Category (e.g., Travel, Lifestyle, Fashion, Food, Fitness, Business, Tech, Home/Interior, Family, etc.)\n2. Estimated Gender (Male/Female/Neutral/Unknown)\n3. Estimated Age Range (e.g., 18-24, 25-34, 35-44, 45+)\n4. Content Themes (3-5 main topics)\n\nAccount Info:\nName: \($name)\nBio: \($bio)\n\nRecent Captions:\n\($captions)\n\nProvide a brief analysis in this format:\nCategory: [category]\nGender: [gender]\nAge Range: [age range]\nThemes: [theme1, theme2, theme3]\nSummary: [2-3 sentence summary]"')

    # Create JSON payload using jq
    PAYLOAD=$(jq -n \
        --arg prompt "$PROMPT" \
        '{
            "model": "claude-3-haiku-20240307",
            "max_tokens": 500,
            "messages": [{
                "role": "user",
                "content": $prompt
            }]
        }')

    API_RESULT=$(curl -s https://api.anthropic.com/v1/messages \
        -H "Content-Type: application/json" \
        -H "x-api-key: ${ANTHROPIC_KEY}" \
        -H "anthropic-version: 2023-06-01" \
        -d "$PAYLOAD")

    AI_RESPONSE=$(echo "$API_RESULT" | jq -r 'if .content then .content[0].text else if .error then .error.message else "Analysis failed" end end')
else
    AI_RESPONSE="AI Analysis not available. Provide Anthropic API key as second argument.
Run: ./scrape_instagram.sh ${USERNAME} YOUR_API_KEY"
fi

# Create output file
{
    echo "=========================================="
    echo "INSTAGRAM DATA FOR @${USERNAME}"
    echo "=========================================="
    echo ""
    echo "Username: $(echo "$PROFILE_DATA" | jq -r '.result.username // "N/A"')"
    echo "Full Name: ${FULL_NAME}"
    echo "User ID: $(echo "$PROFILE_DATA" | jq -r '.result.id // "N/A"')"
    echo "Country: $(echo "$LOCATION_DATA" | jq -r '.creation_country // "N/A"')"
    echo "Date Joined: $(echo "$LOCATION_DATA" | jq -r '.date_joined // "N/A"')"
    echo "Verified On: $(echo "$LOCATION_DATA" | jq -r '.verified_on // "Not verified"')"
    echo "Former Usernames: $(echo "$LOCATION_DATA" | jq -r '.no_of_former_usernames // "0"')"
    echo "Followers: $(echo "$PROFILE_DATA" | jq -r '.result.edge_followed_by.count // "N/A"')"
    echo "Following: $(echo "$PROFILE_DATA" | jq -r '.result.edge_follow.count // "N/A"')"
    echo "Total Posts: $(echo "$PROFILE_DATA" | jq -r '.result.edge_owner_to_timeline_media.count // "N/A"')"
    echo ""
    echo "Biography:"
    echo "${BIOGRAPHY}"
    echo ""
    echo "=========================================="
    echo "AI ANALYSIS"
    echo "=========================================="
    echo ""
    echo "${AI_RESPONSE}"
    echo ""
    echo "=========================================="
    echo "POST CAPTIONS"
    echo "=========================================="
    echo ""

    echo "$POSTS_DATA" | jq -r '.result.edges[]? | "Date: \(.node.taken_at | strftime("%Y-%m-%d"))\n\(.node.caption.text // "No caption")\n\n---\n"'

} > "$OUTPUT_FILE"

cat "$OUTPUT_FILE"
echo ""
echo "Data saved to: $OUTPUT_FILE"
