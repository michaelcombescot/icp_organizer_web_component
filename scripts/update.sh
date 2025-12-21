#!/bin/bash

# 1. CONFIGURATION
# ---------------------------------------------------------
# The ID of your Coordinator (ensure this is correct)
COORDINATOR_ID="$(dfx canister id coordinator)"

# The Type of canister to upgrade (Matches your Motoko variant)
# Change 'usersBucket' to 'groupsBucket' as needed
CANISTER_KIND="variant { dynamic = variant { indexes = variant { mainIndex } } }"

# The Path to the new WASM file
WASM_PATH=".dfx/local/canisters/mainIndex/mainIndex.wasm"

# Temporary file to store the arguments
ARG_FILE="upgrade_args.tmp"

# 2. CHECK IF FILES EXIST
# ---------------------------------------------------------
if [ ! -f "$WASM_PATH" ]; then
    echo "Error: WASM file not found at $WASM_PATH"
    echo "Did you run 'dfx build'?"
    exit 1
fi

# 3. CONSTRUCT ARGUMENT FILE (Stream method)
# ---------------------------------------------------------
# We write to a file instead of a variable to avoid "Argument list too long" errors.
# We build the Candid string part by part.

CHAR=$(hexdump -ve '1/1 "%.2x"' "$WASM_PATH")
CHAR_ESCAPED=$(printf "%s" "$CHAR" | sed 's/../\\&/g')

echo -n "($CANISTER_KIND, blob \"" > "$ARG_FILE"
printf "%s" "$CHAR_ESCAPED" >> "$ARG_FILE"
echo -n "\")" >> "$ARG_FILE"

# 4. EXECUTE THE CALL
# ---------------------------------------------------------
echo "🚀 Sending upgrade command to Coordinator..."

# We use --argument-file to read from the temp file we just created
dfx canister call "$COORDINATOR_ID" handlerUpgradeCanisterKind --argument-file "$ARG_FILE"

# 5. CLEANUP
# ---------------------------------------------------------
rm "$ARG_FILE"
echo "✅ Done."