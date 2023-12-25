#!/bin/bash
echo "[" > index.json

generate_list() {
    for dir in "$1"/*; do
        if [ -d "$dir" ]; then
            echo "{" >> index.json
            echo "\"category\": \"$(basename "$dir")\"," >> index.json
            count=$(find "$dir" -type f -name "*.lua" | wc -l)
            echo "\"count\": \"$count\"," >> index.json
            echo "\"files\": [" >> index.json
            for file in "$dir"/*.lua; do
                if [ -f "$file" ]; then
                    filename=$(basename "$file" .lua)
                    sha256=$(sha256sum "$file" | awk '{ print $1 }')
                    plugin_name=$(perl -ne 'if(/name\s*=\s*"([^"]*)"/){print $1;}' $file)
                    plugin_author=$(perl -ne 'if(/author\s*=\s*"([^"]*)"/){print $1;}' $file)
                    plugin_version=$(perl -ne 'if(/version\s*=\s*"([^"]*)"/){print $1;}' $file)
                    plugin_desc=$(perl -ne 'if(/description\s*=\s*"([^"]*)"/){print $1;}' $file)
                    echo "{" >> index.json
                    echo "\"name\": \"$filename\"," >> index.json
                    echo "\"url\": \"$file\"," >> index.json
                    echo "\"sha256\": \"$sha256\"," >> index.json
                    echo "\"plugin_name\": \"$plugin_name\"," >> index.json
                    echo "\"plugin_author\": \"$plugin_author\"," >> index.json
                    echo "\"plugin_version\": \"$plugin_version\"," >> index.json
                    echo "\"plugin_desc\": \"$plugin_desc\"" >> index.json
                    echo "}," >> index.json
                fi
            done
            # Remove the last comma
            sed -i '$ s/,$//' index.json
            echo "]" >> index.json
            echo "}," >> index.json
        fi
    done
}

generate_list .

# Remove the last comma
sed -i '$ s/,$//' index.json

echo "]" >> index.json