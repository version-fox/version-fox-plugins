readme_file="README.md"
json_file="index.json"
json=$(cat ${json_file})

table_start="| Name | Version | Author | Description |"
table_header="|------|---------|--------|-------------|"

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

      table_content="${table_content}\n| ${name} | ${version} | ${author} | ${desc} |"
  done
done
echo "=======successfully generated table content========"
echo "$table_header"
echo "$table_content"
# Insert the table into the README file
sed -i "/<!-- TABLE_START -->/,/<!-- TABLE_END -->/c\\<!-- TABLE_START -->\n${table_start}\n${table_header}${table_content}\n<!-- TABLE_END -->" ${readme_file}

echo "=======successfully updated README file========"
cat ${readme_file}