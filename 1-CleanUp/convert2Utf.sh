#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] input_path output_path

Convert a HTML file from Aozora Bunko into UTF-8

Available options:
-h, --help      Print this help and exit
input_path      Input HTML filepath (Shift JIS encoding)
output_path     Output HTML filepath (UTF-8 encoding)
EOF
  exit
}
cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
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
msg " - Input file path: $1"
msg " - Output file path: $2"

file_name=$1
html_extension="html"
source_path='Aozora'
temp_path='temp'
target_path="UTF-8"
is_header=1
is_footer=0
p_id=1
div_id=1
if [[ "${file_name##*.}" == "${html_extension}" ]]; then # Remove the file extension from the file name if present
  file_name="${file_name:0:${#file_name}-5}"
fi
# Step 1: Change character encoding
iconv -f SHIFT-JIS -t UTF-8 "${source_path}/${file_name}.${html_extension}" > "${temp_path}/${file_name}-1.${html_extension}"
# Step 2: Update the character encoding declarations in the file
awk '{gsub("Shift_JIS", "UTF-8"); print;}' "${temp_path}/${file_name}-1.${html_extension}" > "${temp_path}/${file_name}-2.${html_extension}"

# Step 3: Apply various fixes, and improve the file structure
rm -f "${temp_path}/${file_name}-3.${html_extension}"
while IFS= read -r line
  do
	if [[ "$line" == *"<div class=\"bibliographical_information\">"* ]]; then
	  is_footer=1
	fi
	if [ $is_header -eq 0 ] && [ $is_footer -eq 0 ]; then #if we are in the main text
	  if [[ "$line" == *"<div"* ]]; then 
	    line=${line/<div/<div id=\"d${div_id}\"} # add id attribut to div tags
		((div_id+=1))
	  fi
	  # Replace non Shift-JIS characters with their UTF-8 equivalents
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-01\/1-01-52.png\" alt=\"※(始め二重山括弧、1-1-52)\" class=\"gaiji\" \/>/《}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-01\/1-01-53.png\" alt=\"※(終わり二重山括弧、1-1-53)\" class=\"gaiji\" \/>/》}
	  if [[ "$line" == *"1-02-22.png"* ]]; then # If there is a ku-no-jiten, generate a warning
	    echo "Warning: Ku-no-jiten replaced 々 in ${line}"
	  fi
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-02\/1-02-22.png\" alt=\"※(二の字点、1-2-22)\" class=\"gaiji\" \/>/々}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-02\/1-02-54.png\" alt=\"※(始め二重括弧、1-2-54)\" class=\"gaiji\" \/>/｟}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-02\/1-02-55.png\" alt=\"※(終わり二重括弧、1-2-55)\" class=\"gaiji\" \/>/｠}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-06\/1-06-57.png\" alt=\"※(ギリシア小文字ファイナルSIGMA、1-6-57)\" class=\"gaiji\" \/>/ς}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-08\/1-08-75.png\" alt=\"※(感嘆符二つ、1-8-75)\" class=\"gaiji\" \/>/!!}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-08\/1-08-77.png\" alt=\"※(疑問符感嘆符、1-8-77)\" class=\"gaiji\" \/>/?!}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-20.png\" alt=\"※(2分の1、1-9-20)\" class=\"gaiji\" \/>/½}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-32.png\" alt=\"※(アキュートアクセント付きE)\" class=\"gaiji\" \/>/É}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-27.png\" alt=\"※(ダイエレシス付きA)\" class=\"gaiji\" \/>/Ä}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-45.png\" alt=\"※(ダイエレシス付きO)\" class=\"gaiji\" \/>/Ö}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-50.png\" alt=\"※(ダイエレシス付きU)\" class=\"gaiji\" \/>/Ü}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-53.png\" alt=\"※(ドイツ語エスツェット)\" class=\"gaiji\" \/>/ß}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-54.png\" alt=\"※(グレーブアクセント付きA小文字)\" class=\"gaiji\" \/>/à}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-55.png\" alt=\"※(アキュートアクセント付きA小文字)\" class=\"gaiji\" \/>/á}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-58.png\" alt=\"※(ダイエレシス付きA小文字)\" class=\"gaiji\" \/>/ä}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-60.png\" alt=\"※(リガチャAE小文字)\" class=\"gaiji\" \/>/æ}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-61.png\" alt=\"※(セディラ付きC小文字)\" class=\"gaiji\" \/>/ç}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-62.png\" alt=\"※(グレーブアクセント付きE小文字)\" class=\"gaiji\" \/>/è}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-63.png\" alt=\"※(アキュートアクセント付きE小文字)\" class=\"gaiji\" \/>/é}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-64.png\" alt=\"※(サーカムフレックスアクセント付きE小文字)\" class=\"gaiji\" /\>/ê}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-69.png\" alt=\"※(ダイエレシス付きI小文字)\" class=\"gaiji\" \/>/ï}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-74.png\" alt=\"※(サーカムフレックスアクセント付きO小文字)\" class=\"gaiji\" \/>/ô}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-76.png\" alt=\"※(ダイエレシス付きO小文字)\" class=\"gaiji\" \/>/ö}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-81.png\" alt=\"※(ダイエレシス付きU小文字)\" class=\"gaiji\" \/>/ü}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-09\/1-09-94.png\" alt=\"※(マクロン付きO小文字)\" class=\"gaiji\" \/>/ō}
	  line=${line//<img [^s]* src=\"..\/..\/..\/gaiji\/1-13\/1-13-21.png\" alt=\"※(ローマ数字1、1-13-21)\" class=\"gaiji\" \/>/I}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-13\/1-13-22.png\" alt=\"※(ローマ数字2、1-13-22)\" class=\"gaiji\" \/>/II}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-13\/1-13-23.png\" alt=\"※(ローマ数字3、1-13-23)\" class=\"gaiji\" \/>/III}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-13\/1-13-24.png\" alt=\"※(ローマ数字4、1-13-24)\" class=\"gaiji\" \/>/IV}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-13\/1-13-25.png\" alt=\"※(ローマ数字5、1-13-25)\" class=\"gaiji\" \/>/V}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-13\/1-13-26.png\" alt=\"※(ローマ数字6、1-13-26)\" class=\"gaiji\" \/>/VI}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-13\/1-13-29.png\" alt=\"※(ローマ数字9、1-13-29)\" class=\"gaiji\" \/>）/IX}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-13\/1-13-89.png\" alt=\"※(直角三角、1-13-89)\" class=\"gaiji\" \/>/◿}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-84\/1-84-30.png\" alt=\"※(「或」の「丿」に代えて「彡」、第3水準1-84-30)\" class=\"gaiji\" \/>/彧}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-84\/1-84-31.png\" alt=\"※(「彳＋低のつくり」、第3水準1-84-31)\" class=\"gaiji\" \/>/彽}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-85\/1-85-18.png\" alt=\"※(「日＋令」、第3水準1-85-18)\" class=\"gaiji\" \/>/昤}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-85\/1-85-25.png\" alt=\"※(「日＋向」、第3水準1-85-25)\" class=\"gaiji\" \/>/晌}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-93\/1-93-25.png\" alt=\"※(「金＋英」、第3水準1-93-25)\" class=\"gaiji\" \/>/鍈}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/1-93\/1-93-66.png\" alt=\"※(「奚＋隹」、第3水準1-93-66)\" class=\"gaiji\" \/>/雞}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/2-13\/2-13-28.png\" alt=\"※(「插」でつくりの縦棒が下に突き抜けている、第4水準2-13-28)\" class=\"gaiji\" \/>/揷}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/2-80\/2-80-78.png\" alt=\"※(「王＋爭」、第4水準2-80-78)\" class=\"gaiji\" \/>/琤}
	  line=${line//<img [^s]*src=\"..\/..\/..\/gaiji\/2-87\/2-87-90.png\" alt=\"※(「郷／虫」の「即のへん」に代えて「皀」、第4水準2-87-90)\" class=\"gaiji\" \/>/蠁}
	  line=${line//※<span class=\"notes\">［＃鋭アクセント付きυ、U+1F7B、19-下-2］<\/span>/ύ}
	  line=${line//※<span class=\"notes\">［＃下側の右ダブル引用符、U+201E、33-上-10］<\/span>/„}
	  line=${line//※<span class=\"notes\">［＃ローマ数字13、50-下-20］<\/span>/XIII}
	  line=${line//※<span class=\"notes\">［＃ローマ数字15、71-上-2］<\/span>/XV}
	  line=${line//※<span class=\"notes\">［＃ローマ数字18、36-下-12］<\/span>/XVIII}
	  line=${line//※<span class=\"notes\">［＃ローマ数字19、37-下-11］<\/span>/XIX}
	  line=${line//※<span class=\"notes\">［＃ローマ数字22、56-下-22］<\/span>/XXII}
	  line=${line//<span class=\"notes\">［＃改段］<\/span>/}
	  line=${line//<span class=\"notes\">［＃改丁］<\/span>/}
	  line=${line//<span class=\"notes\">［＃改ページ］<\/span>/}

	  if [[ "$line" == *"src=\"../../../gaiji/"* ]]; then # If there is some unknown characters, generate an error
	    echo "Error: Unknown character in ${line}"
	  fi
	  if [[ "$line" == *"<span class=\"notes\">"* ]]; then # Convert notes into checkboxes. See https://stackoverflow.com/questions/40336366/in-line-footnotes-with-only-html-css-in-notes
	  	line=`echo $line | sed -E "s/<span class=\"notes\">［＃([^］]*)］<\/span>/<label><sup>＃<\/sup><input type=\"checkbox\" \/><span>\1<\/span><\/label>/g"`
	  fi
	  if [[ "$line" == *"<span class=\"notes\">"* ]]; then # If there is an unknown note format, generate a warning
	    echo "Warning: Note in ${line}"
	  fi
	  
	  if echo "${line:0:1}" | grep -q $'\u3000'; then #If the line starts with an ideographic space
	    if [[ "$line" == *"<br />"* ]]; then # and contains a br tag
	      line2=`echo "<p id=\"p${p_id}\">${line:1}"` # inject p tags instead
		  line="${line2/<br \/>/<\/p>}"
		  nb_br=`echo "$line" | grep -o "<br />" | wc -l`
		  if [ $nb_br -gt 1 ]; then # If there is more than 1 <br /> tag in the line, generate an error
		    echo "Error: Extra <br /> tag in paragraph id=\"p${p_id}\""
	      fi
		  ((p_id+=1)) #Increment the unique identifier of the paragraph
	    fi
	  fi
	fi # End if "in main text"
        if [ $is_footer -eq 0 ]; then # Do not output the footer 
	  echo -e "$line" >> "${temp_path}/${file_name}-3.${html_extension}"
	fi
	if [[ "$line" == *"<div class=\"main_text\">"* ]]; then
	  is_header=0
	fi
  done < "${temp_path}/${file_name}-2.${html_extension}"
  # Close the HTML
  echo -e "</body>" >> "${temp_path}/${file_name}-3.${html_extension}"
  echo -e "</html>" >> "${temp_path}/${file_name}-3.${html_extension}"
  # Final step: copy the file in the output folder
  cp "${temp_path}/${file_name}-3.${html_extension}" "${target_path}/${file_name}.${html_extension}"
