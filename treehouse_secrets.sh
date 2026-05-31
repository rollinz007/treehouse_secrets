#!/bin/bash
###################################################################
# Script: treehouse_secrets.sh  |  By: John Harper (@rollinz007)
###################################################################
# Passing secret notes since the 1980s!
# No encryption was harmed in the making of this ENCODING tool
#
# Encoding pipeline (each round, in order):
#   ENCODE: base64 → ROT13 → shift cipher
#   DECODE: shift cipher (reverse) → ROT13 → base64 decode
#
# Usage:
#   treehouse_secrets.sh -e <text or file>   Encode text or a file
#   treehouse_secrets.sh -d <encoded file>   Decode an encoded file
#   treehouse_secrets.sh --help              Show this help message
#
# Notes:
#   - The shift cipher operates on printable ASCII (0x20–0x7E only).
#     Unicode or binary input will not encode/decode correctly.
###################################################################

# Color codes
YELLOW="\e[33m"
DARKGREEN="\e[32m"
GREEN="\e[32;1m"
BLUE="\e[94m"
RED="\e[91m"
NC="\e[0m"

# ---------------------------------------------------------------------------
# ASCII lookup tables — built once at startup, used by shift_cipher
# ---------------------------------------------------------------------------
declare -A ORD   # char  -> ordinal
declare -a CHR   # ordinal -> char

for (( _i = 32; _i <= 126; _i++ )); do
    _c=$(printf "\\$(printf '%03o' "$_i")")
    ORD["$_c"]=$_i
    CHR[$_i]="$_c"
done
unset _i _c

# ---------------------------------------------------------------------------
# title — print the banner
# ---------------------------------------------------------------------------
title() {
    echo -e "${GREEN}"
    cat << 'EOF'
 _____               _                          
/__   \_ __ ___  ___| |__   ___  _   _ ___  ___ 
  / /\/ '__/ _ \/ _ \ '_ \ / _ \| | | / __|/ _ \
 / /  | | |  __/  __/ | | | (_) | |_| \__ \  __/
 \/   |_|  \___|\___|_| |_|\___/ \__,_|___/\___|
                                                
 __                    _                        
/ _\ ___  ___ _ __ ___| |_ ___                  
\ \ / _ \/ __| '__/ _ \ __/ __|                 
_\ \  __/ (__| | |  __/ |_\__ \                 
\__/\___|\___|_|  \___|\__|___/                 
                                                
EOF
    echo -e "${YELLOW}=================================================================="
    echo -e "${YELLOW} treehouse_secrets.sh | [Version]: 1.2.0 | [Updated]: 2026"
    echo -e "${YELLOW}=================================================================="
    echo -e "${YELLOW} [By]: John Harper | [GitHub]: https://github.com/rollinz007"
    echo -e "${YELLOW}==================================================================${NC}"
    echo -e "${DARKGREEN}Passing secret notes since the 1980s!${NC}"
    echo
}

# ---------------------------------------------------------------------------
# usage — print usage and exit
# ---------------------------------------------------------------------------
usage() {
    echo -e "${BLUE}Usage: $0 [-e|-d] <text or file>${NC}"
    echo -e "${BLUE}       $0 --help${NC}"
    echo
    echo -e "${BLUE}  -e <text|file>   Encode the given text string or file${NC}"
    echo -e "${BLUE}  -d <file>        Decode the given encoded file${NC}"
    echo -e "${BLUE}  --help           Show this help message${NC}"
    exit 1
}

# ---------------------------------------------------------------------------
# shift_cipher <text> <key> <encode|decode>
#   Vigenère-style shift over printable ASCII (0x20–0x7E, 95 chars).
#   Characters outside that range are passed through unchanged.
#
#   Uses the ORD and CHR lookup tables built at startup
# ---------------------------------------------------------------------------
shift_cipher() {
    local text="$1"
    local key="$2"
    local direction="$3"
    local key_len="${#key}"
    local chars=()          # accumulate output chars; join once at the end
    local char char_code key_char key_code

    for (( i = 0; i < ${#text}; i++ )); do
        char="${text:$i:1}"
        char_code="${ORD["$char"]}"   # table lookup — no fork

        if [[ -n "$char_code" ]]; then
            # Printable ASCII: apply the shift
            key_char="${key:$(( i % key_len )):1}"
            key_code="${ORD["$key_char"]}"

            if [[ "$direction" == "encode" ]]; then
                char_code=$(( ( (char_code - 32) + (key_code - 32) ) % 95 + 32 ))
            else
                char_code=$(( ( (char_code - 32) - (key_code - 32) + 95 ) % 95 + 32 ))
            fi
            chars+=("${CHR[$char_code]}")   # table lookup — no fork
        else
            # Outside printable ASCII: pass through unchanged
            chars+=("$char")
        fi
    done

    # Join array into a single string with no separator
    local IFS=""
    echo "${chars[*]}"
}

# ---------------------------------------------------------------------------
# rot13 <text>
#   Applies ROT13 substitution (self-inverse, so same function for both directions).
# ---------------------------------------------------------------------------
rot13() {
    echo "$1" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
}

# ---------------------------------------------------------------------------
# b64_encode <text>   — portable base64 encoding (strips newlines)
# b64_decode <text>   — portable base64 decoding
# ---------------------------------------------------------------------------
b64_encode() {
    echo -n "$1" | base64 | tr -d '\n'
}

b64_decode() {
    echo -n "$1" | base64 --decode
}

# ---------------------------------------------------------------------------
# validate_rounds <value>
#   Ensures the value is a positive integer; exits with an error if not.
# ---------------------------------------------------------------------------
validate_rounds() {
    if [[ ! "$1" =~ ^[1-9][0-9]*$ ]]; then
        echo -e "${RED}Error: rounds must be a positive integer (got: '$1').${NC}" >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

# Handle --help before the argument-count check
if [[ "$1" == "--help" ]]; then
    title
    usage
fi

if [[ "$#" -ne 2 ]]; then
    title
    usage
fi

option="$1"
input="$2"

if [[ "$option" != "-e" ]] && [[ "$option" != "-d" ]]; then
    echo -e "${RED}Invalid option '$option'. Use -e to encode or -d to decode.${NC}" >&2
    usage
fi

# Read the key silently so it doesn't appear on screen or in shell history
read -rsp "Enter the key: " key
echo   # newline after silent input

# Validate key is non-empty (empty key causes divide-by-zero in the cipher)
if [[ -z "$key" ]]; then
    echo -e "${RED}Error: key cannot be empty.${NC}" >&2
    exit 1
fi

read -rp "Enter the number of rounds: " rounds
validate_rounds "$rounds"

# ---------------------------------------------------------------------------
# Encode path
# ---------------------------------------------------------------------------
if [[ "$option" == "-e" ]]; then
    # Accept either a file path or a raw text string
    if [[ -f "$input" ]]; then
        input=$(<"$input")
    fi

    for ((i = 1; i <= rounds; i++)); do
        input=$(b64_encode "$input")
        input=$(rot13 "$input")
        input=$(shift_cipher "$input" "$key" "encode")
    done

    # Use mktemp so concurrent runs never collide
    encoded_output_file=$(mktemp ./encoded_XXXXXX.txt)
    echo -e "${GREEN}Encoded result:${NC} $input"
    echo "$input" > "$encoded_output_file"
    echo -e "${GREEN}Encoded data saved to:${NC} $encoded_output_file"

# ---------------------------------------------------------------------------
# Decode path
# ---------------------------------------------------------------------------
else
    if [[ ! -f "$input" ]]; then
        echo -e "${RED}Error: '$input' is not a valid file. Please provide a valid encoded file to decode.${NC}" >&2
        exit 1
    fi

    input=$(<"$input")

    for ((i = 1; i <= rounds; i++)); do
        input=$(shift_cipher "$input" "$key" "decode")
        input=$(rot13 "$input")
        input=$(b64_decode "$input")
    done

    decoded_output_file=$(mktemp ./decoded_XXXXXX.txt)
    echo -e "${GREEN}Decoded result:${NC} $input"
    echo "$input" > "$decoded_output_file"
    echo -e "${GREEN}Decoded data saved to:${NC} $decoded_output_file"
fi
