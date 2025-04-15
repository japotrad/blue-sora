#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] input_path output_path

Convert the 1st bibliographic record of a RIS file into XML

Available options:
-h, --help      Print this help and exit
input_path      Input RIS filepath
output_path     Output XML filepath
EOF
  exit
}
cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  if [ "$#" -ne 2 ]; then
    usage
    exit 1
  fi
  if ! [ -e "$1" ]; then
    msg "${RED}Parameter error (input_path): ${NOFORMAT} $1 file not found"
    exit 1
  fi
  return 0
}
setup_colors
parse_params "$@"

msg "${BLUE}Read parameters:${NOFORMAT}"
input_path=$1
msg " - Input file path: ${input_path}"
output_path=$2
msg " - Output file path: ${output_path}"

input_file_name=$(basename ${input_path})
output_file_name=$(basename ${output_path})



# Step 0: Create the file header
echo -e '<?xml version="1.0" encoding="UTF-8"?>' > "${output_path}"
echo -e '<!DOCTYPE ris SYSTEM "ris.dtd">' >> "${output_path}"
echo -e '<ris xmlns="https://github.com/japotrad/blue-sora/ris">' >> "${output_path}"

# Step 1: Process the input RIS file
is_header=1 # The header is what is above the first line starting with "TY  - "
is_abstract=0 #This variable becomes true during the processing of multilingual "AB" tag.
while IFS= read -r line
  do
	if [ $is_header -eq 0 ]; then #if we are in the 1st bib record
	  if [[ "${line:0:5}" == "ER  -" ]]; then # End of the 1st RIS bib record.
	    break
	  fi
	  line=${line/[$'\r']} # Remove the Carriage Return character 0x0D (if any)
	  # Multi-line fields - Other lines
	  if [ $is_abstract -eq 1 ] && [[ ${line:2:4} != "  - " ]]; then
	    echo -e "$line" >> "${output_path}"
		continue
	  fi
	  if [[ ${line:2:4} == "  - " ]]; then # if the line start with "??  - "
	    if [ $is_abstract -eq 1 ] && [[ ${line:0:2} != "AB" ]]; then # Add the closing XML tag for the previous multi-line tag
		    truncate -s-1 "${output_path}"
	        echo -e "</AB>" >> "${output_path}"
			is_abstract=0
		fi
	    if [[ ${line:0:2} == "A1" ]]; then # Replace A1 tag with AU
		  line=`echo "AU${line:2}"`
		fi
		if [[ ${line:0:2} == "AU" ]] || [[ ${line:0:2} == "A4" ]]; then # For authors and translators
		  if [[ ${line:6} == *","* ]]; then # If their name contains a comma
		     full_name=${line:6}
			 last_name=`echo "${full_name%,*}"` # The last name is located before the comma
			 last_name=`echo "${last_name# }"` # Remove leading whitespace
			 last_name=`echo "${last_name% }"` # Remove trailing whitespace
			 first_name=`echo "${full_name#*,}"` # The first name is located after the comma
			 first_name=`echo "${first_name# }"` # Remove leading whitespace
			 first_name=`echo "${first_name% }"` # Remove trailing whitespace
		     line=`echo "${line:0:6}<LAST>${last_name}</LAST><FIRST>${first_name}</FIRST>"` # Split the last name and the first name the XML way
		  fi
		fi
		if [[ ${line:0:2} == "T1" ]] || [[ ${line:0:2} == "CT" ]]; then # Replace T1 and CT tag with TI
		  line=`echo "TI${line:2}"`
		fi
		# Single-line fields
		if [[ ${line:0:2} == "TI" ]] || [[ ${line:0:2} == "AU" ]] || [[ ${line:0:2} == "A4" ]] || [[ ${line:0:2} == "PY" ]] || [[ ${line:0:2} == "UR" ]]; then
		  echo -e "  <${line:0:2}>${line:6}</${line:0:2}>" >> "${output_path}" # Turn the TI, AU, A4, PY and UR tags into XML.
		  continue
	    fi
		# Multi-line fields - First line
		if [[ ${line:0:2} == "AB" ]]; then
		  is_abstract=1
		  echo -e "  <${line:0:2}>${line:6}" >> "${output_path}" # The XML tag is left unclosed.
		  continue
		fi
	  fi # End if "line starting with a tag"
	fi # End if "1st bib record"
	if [ "${line:0:6}" == "TY  - " ]; then
	    is_header=0
	fi
  done < "${input_path}"
  # Close the XML
  echo -e "</ris>" >> "${output_path}"
  cleanup
