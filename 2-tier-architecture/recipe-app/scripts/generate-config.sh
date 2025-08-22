#!/bin/sh
API_URL="${API_URL:-https://localhost:8443/api}"
cat <<EOF > /usr/share/nginx/html/config.json
{
  "API_URL": "$API_URL"
}
EOF