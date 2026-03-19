#!/bin/sh
set -eu

HOSTNAME_VALUE="$(hostname 2>/dev/null || true)"
if [ -z "$HOSTNAME_VALUE" ]; then
  HOSTNAME_VALUE="unknown"
fi

STARTED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
MESSAGE="Hello, instance: ${HOSTNAME_VALUE}, started at: ${STARTED_AT}"

escape_html() {
  # Minimal HTML escaping for safe embedding into index.html.
  # This is defensive: hostname/start time shouldn't normally contain these,
  # but it's cheap to keep it correct.
  printf '%s' "$1" \
    | sed -e 's/&/\&amp;/g' \
          -e 's/</\&lt;/g' \
          -e 's/>/\&gt;/g' \
          -e 's/"/\&quot;/g' \
          -e "s/'/\&#39;/g"
}

ESCAPED_MESSAGE="$(escape_html "$MESSAGE")"

cat > /usr/share/nginx/html/index.html <<EOF
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>hello-world-front</title>
    <style>
      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; margin: 0; padding: 2rem; }
      p { font-size: 1.1rem; }
    </style>
  </head>
  <body>
    <div id="root">
      <p>${ESCAPED_MESSAGE}</p>
    </div>
  </body>
</html>
EOF

exec nginx -g "daemon off;"

