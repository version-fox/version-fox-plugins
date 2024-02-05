readme_file="README.md"
json_file="index.json"
json=$(cat ${json_file})

table_start="<table>\n<tr>\n<th>Name</th>\n<th>Version</th>\n<th>Author</th>\n<th>Description</th>\n</tr>"
table_end="</table>"

table_content=""
for row in $(echo "${json}" | jq -r '.[] | @base64'); do
  _jq() {
   echo ${row} | base64 --decode | jq -r ${1}
  }

  category=$(_jq '.category')
  files=$(_jq '.files')

  for file in $(echo "${files}" | jq -r '.[] | @base64'); do
      _jq_file() {
       echo ${file} | base64 --decode | jq -r ${1}
      }

      name="${category}/$(_jq_file '.name')"
      version=$(_jq_file '.plugin_version')
      author=$(_jq_file '.plugin_author')
      desc=$(_jq_file '.plugin_desc')

      name="<small><b>${name}</b></small>"  # Make the name bold
      version="<small>${version}</small>"  # Change the font size
      author="<small>${author}</small>"  # Change the font size
      desc="<small>${desc}</small>"  # Change the font size
      desc=${desc//$'\n'/<br>}  # Replace newline characters with <br> tags

      table_content="${table_content}\n<tr>\n<td>${name}</td>\n<td>${version}</td>\n<td>${author}</td>\n<td>${desc}</td>\n</tr>"
  done
done
echo "=======successfully generated table content========"
echo "$table_content"
# Insert the table into the README file
sed -i "/<!-- TABLE_START -->/,/<!-- TABLE_END -->/c\\<!-- TABLE_START -->\n${table_start}${table_content}\n${table_end}\n<!-- TABLE_END -->" ${readme_file}
echo "=======successfully updated README file========"
cat ${readme_file}