#!/bin/bash
###################################################################
# Script: treehouse_secrets.sh  |  By: John Harper (@rollinz007) 
###################################################################
# Passing secret notes since the 1980s!
# No encryption was harmed in the making of this ENCODING tool

# Color codes
YELLOW="\e[33m"
DARKGREEN="\e[32m"
GREEN="\e[32;1m"
BLUE="\e[94m"
RED="\e[91m"
NC="\e[0m"  # No color

# Function to perform the shift cipher encoding/decoding
shift_cipher() {
  local text="$1"
  local key="$2"
  local direction="$3"

  result=""
  for ((i = 0; i < ${#text}; i++)); do
    char="${text:$i:1}"
    key_char="${key:$((i % ${#key})):1}"
    if [ "$direction" == "encode" ]; then
      char_code=$(( ( ( $(printf '%d' "'$char") - 32 ) + ( $(printf '%d' "'$key_char") - 32 ) ) % 95 + 32 ))
    else
      char_code=$(( ( ( $(printf '%d' "'$char") - 32 ) - ( $(printf '%d' "'$key_char") - 32 ) + 95 ) % 95 + 32 ))
    fi
    result="${result}$(printf "\\$(printf '%03o' "$char_code")")"
  done
  echo "$result"
}

# Function to perform another encoding technique (e.g., ROT13)
other_encoding() {
  local text="$1"
  echo "$text" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
}

# Function to perform a third encoding technique (e.g., base64)
base64_encoding() {
  local text="$1"
  echo -n "$text" | base64 -w 0
}

# Function to perform base64 decoding
base64_decoding() {
  local text="$1"
  echo -n "$text" | base64 -d -i
}

title () {
    echo -e "${GREEN} "
    echo IF9fX19fICAgICAgICAgICAgICAgXyAgICAgICAgICAgICAgICAgICAgICAgICAgCi9fXyAgIFxfIF9fIF9fXyAgX19ffCB8X18gICBfX18gIF8gICBfIF9fXyAgX19fIAogIC8gL1wvICdfXy8gXyBcLyBfIFwgJ18gXCAvIF8gXHwgfCB8IC8gX198LyBfIFwKIC8gLyAgfCB8IHwgIF9fLyAgX18vIHwgfCB8IChfKSB8IHxffCBcX18gXCAgX18vCiBcLyAgIHxffCAgXF9fX3xcX19ffF98IHxffFxfX18vIFxfXyxffF9fXy9cX19ffAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKIF9fICAgICAgICAgICAgICAgICAgICBfICAgICAgICAgICAgICAgICAgICAgICAgCi8gX1wgX19fICBfX18gXyBfXyBfX198IHxfIF9fXyAgICAgICAgICAgICAgICAgIApcIFwgLyBfIFwvIF9ffCAnX18vIF8gXCBfXy8gX198ICAgICAgICAgICAgICAgICAKX1wgXCAgX18vIChfX3wgfCB8ICBfXy8gfF9cX18gXCAgICAgICAgICAgICAgICAgClxfXy9cX19ffFxfX198X3wgIFxfX198XF9ffF9fXy8gICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKCg== |base64 -d
    echo -e "${YELLOW}=================================================================="
    echo -e "${YELLOW} treehouse_secrets.sh | [Version]: 1.0.0 | [Updated]: 10.26.2023"
    echo -e "${YELLOW}=================================================================="
    echo -e "${YELLOW} [By]: John Harper | [GitHub]: https://github.com/rollinz007"
    echo -e "${YELLOW}==================================================================${NC}"
    echo -e "${DARKGREEN}Passing secret notes since the 1980s!${NC}"
    echo
}

# Main script
if [ "$#" -ne 2 ]; then
  title
  echo -e "${BLUE}Usage: $0 [-e|-d] <text or file>${NC}"
  exit 1
fi

option="$1"
input="$2"

if [ "$option" != "-e" ] && [ "$option" != "-d" ]; then
  echo -e "${BLUE}Invalid option. Use -e to encode or -d to decode.${NC}"
  exit 1
fi

echo -n "Enter the key: "
read key

echo -n "Enter the number of rounds: "
read rounds

if [ "$option" == "-e" ]; then
  if [ -f "$input" ]; then
    input=$(<"$input")
  fi

  for ((i = 1; i <= rounds; i++)); do
    input=$(base64_encoding "$input")
    input=$(other_encoding "$input")
    input=$(shift_cipher "$input" "$key" "encode")
  done

  # Generate a unique filename with a timestamp
  encoded_output_file="encoded_$(date +'%Y%m%d%H%M%S').txt"
  echo -e "${GREEN}Encoded result:${NC} $input"
  echo "$input" > "$encoded_output_file"
  echo -e "${GREEN}Encoded data saved to:${NC} $encoded_output_file"
else
  if [ ! -f "$input" ]; then
    echo -e "${RED}Invalid input file. Please provide a valid file to decode.${NC}"
    exit 1
  fi

  input=$(<"$input")
  for ((i = 1; i <= rounds; i++)); do
    input=$(shift_cipher "$input" "$key" "decode")
    input=$(other_encoding "$input")
    input=$(base64_decoding "$input")
  done

  # Generate a unique filename with a timestamp
  decoded_output_file="decoded_$(date +'%Y%m%d%H%M%S').txt"
  echo -e "${GREEN}Decoded result:${NC} $input"
  echo "$input" > "$decoded_output_file"
  echo -e "${GREEN}Decoded data saved to:${NC} $decoded_output_file"
fi
