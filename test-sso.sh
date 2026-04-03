#!/bin/bash
#
# Test SSO form authentication against the form-auth-webapp application.
# Inspired by ClusteringHTTPRequestSamplerSSO.java
#
# Usage: ./test-sso.sh [host] [port1] [port2]
#   host  - default: localhost
#   port1 - WildFly node 1 HTTP port (default: 8180)
#   port2 - WildFly node 2 HTTP port (default: 8480)
#

HOST=${1:-localhost}
PORT1=${2:-8180}
PORT2=${3:-8480}
USERNAME="ssoUser"
PASSWORD="ssoPassw"
APP_PATH="/form-auth-webapp/session"
COOKIE_JAR=$(mktemp /tmp/sso-cookies.XXXXXX)

cleanup() {
    rm -f "$COOKIE_JAR"
}
trap cleanup EXIT

echo "=== SSO Test against $HOST:$PORT1 and $HOST:$PORT2 ==="
echo ""

# --------------------------------------------------------------------------
# Step 1: GET the session URL on node 1 — expect redirect to login form
# --------------------------------------------------------------------------
echo "--- Step 1: GET http://$HOST:$PORT1$APP_PATH (expect login form) ---"
RESPONSE=$(curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" -D - \
    "http://$HOST:$PORT1$APP_PATH")

echo "$RESPONSE" | head -20
echo ""

# Check that we got the login form
if echo "$RESPONSE" | grep -qi "j_security_check"; then
    echo "[OK] Login form received."
else
    echo "[FAIL] Did not receive login form!"
    echo "$RESPONSE"
    exit 1
fi
echo ""

# --------------------------------------------------------------------------
# Step 2: POST credentials to j_security_check on node 1
# --------------------------------------------------------------------------
echo "--- Step 2: POST j_security_check with $USERNAME/$PASSWORD ---"
RESPONSE=$(curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" -D - \
    -L \
    -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "j_username=$USERNAME&j_password=$PASSWORD" \
    "http://$HOST:$PORT1/form-auth-webapp/j_security_check")

echo "$RESPONSE" | head -20
echo ""

# Check for JSESSIONID cookie
JSESSIONID=$(grep -i "JSESSIONID[^S]" "$COOKIE_JAR" | awk '{print $NF}' | head -1)
if [ -z "$JSESSIONID" ]; then
    # try alternate format
    JSESSIONID=$(grep -i "JSESSIONID" "$COOKIE_JAR" | grep -iv "JSESSIONIDSSO" | awk '{print $NF}' | head -1)
fi

# Check for JSESSIONIDSSO cookie
JSESSIONIDSSO=$(grep -i "JSESSIONIDSSO" "$COOKIE_JAR" | awk '{print $NF}' | head -1)

echo "JSESSIONID:    $JSESSIONID"
echo "JSESSIONIDSSO: $JSESSIONIDSSO"
echo ""

if [ -n "$JSESSIONID" ]; then
    echo "[OK] JSESSIONID cookie received."
else
    echo "[FAIL] No JSESSIONID cookie!"
fi

if [ -n "$JSESSIONIDSSO" ]; then
    echo "[OK] JSESSIONIDSSO cookie received."
else
    echo "[WARN] No JSESSIONIDSSO cookie (SSO may not be configured or not working)."
fi
echo ""

# --------------------------------------------------------------------------
# Step 3: GET the session URL on node 1 again — should be authenticated
# --------------------------------------------------------------------------
echo "--- Step 3: GET http://$HOST:$PORT1$APP_PATH (authenticated, expect serial) ---"
RESPONSE=$(curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" -D - \
    "http://$HOST:$PORT1$APP_PATH")

echo "$RESPONSE"
echo ""

# Check that we got a serial number (plain text integer) and not a login form
BODY=$(echo "$RESPONSE" | tail -1)
if echo "$BODY" | grep -qP '^\d+$'; then
    echo "[OK] Got serial: $BODY"
else
    echo "[FAIL] Expected a serial number, got: $BODY"
fi
echo ""

# --------------------------------------------------------------------------
# Step 4: GET the session URL on node 2 — SSO should allow access without
#         re-authentication
# --------------------------------------------------------------------------
echo "--- Step 4: GET http://$HOST:$PORT2$APP_PATH (SSO to node 2, no re-auth expected) ---"
RESPONSE=$(curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" -D - \
    "http://$HOST:$PORT2$APP_PATH")

echo "$RESPONSE"
echo ""

BODY=$(echo "$RESPONSE" | tail -1)
if echo "$BODY" | grep -qP '^\d+$'; then
    echo "[OK] SSO works! Got serial from node 2: $BODY (no re-authentication needed)"
elif echo "$RESPONSE" | grep -qi "j_security_check"; then
    echo "[FAIL] SSO did NOT work — got login form on node 2 (re-authentication required)"
else
    echo "[WARN] Unexpected response from node 2: $BODY"
fi
echo ""

# --------------------------------------------------------------------------
# Summary: print cookies
# --------------------------------------------------------------------------
echo "--- Cookie jar contents ---"
cat "$COOKIE_JAR"
echo ""
echo "=== Done ==="
