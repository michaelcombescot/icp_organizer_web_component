#!/bin/bash

# 1. CONFIGURATION
# ---------------------------------------------------------
# The ID of your Coordinator (ensure this is correct)
COORDINATOR_ID="$(dfx canister id organizerCoordinator)"

# The Type of canister to upgrade (Matches your Motoko variant)
# Change 'usersBucket' to 'groupsBucket' as needed
CANISTER_KIND="variant { dynamic = variant { indexes = variant { mainIndex } } }"

# The Path to the new WASM file
WASM_PATH=".dfx/local/canisters/organizerMainIndex/organizerMainIndex.wasm"

# Temporary file to store the arguments
ARG_FILE="upgrade_args.tmp"

# 2. CHECK IF FILES EXIST
# ---------------------------------------------------------
if [ ! -f "$WASM_PATH" ]; then
    echo "Error: WASM file not found at $WASM_PATH"
    echo "Did you run 'dfx build'?"
    exit 1
fi

echo " preparing upgrade for $CANISTER_KIND..."

# 3. CONSTRUCT ARGUMENT FILE (Stream method)
# ---------------------------------------------------------
# We write to a file instead of a variable to avoid "Argument list too long" errors.
# We build the Candid string part by part.

# Part A: Open parenthesis + Arg 1 + Comma + Arg 2 Start (blob ")
echo -n "($CANISTER_KIND, blob \"" > "$ARG_FILE"

# Part B: Hexdump the WASM (escaped hex codes like \00\a4...)
# This command works on both Linux and macOS
hexdump -ve '1/1 "\\%02x"' "$WASM_PATH" >> "$ARG_FILE"

# Part C: Close the blob string (") and the parenthesis )
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