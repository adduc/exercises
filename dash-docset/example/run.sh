#!/bin/bash
##
# @see https://kapeli.com/docsets#dashDocset
##

# error out on failed commands, undefined variables, and failed pipes
set -o errexit -o nounset -o pipefail

NAME=example
VERSION=0.0.4

rm -rf "${NAME}".docset

mkdir -p "${NAME}".docset/Contents/Resources/Documents/

# docset metadata
cat > "${NAME}".docset/Contents/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>${NAME}</string>

	<key>CFBundleName</key>
	<string>${NAME^}</string>

	<key>DocSetPlatformFamily</key>
	<string>${NAME}</string>

	<key>isDashDocset</key>
	<true/>

	<key>dashIndexFilePath</key>
	<string>index.html</string>
</dict>
</plist>
EOF

# Main Page for docset
cat > "${NAME}".docset/Contents/Resources/Documents/index.html <<EOF
${NAME^} ${VERSION}
EOF

# example page to be indexed
cat > "${NAME}".docset/Contents/Resources/Documents/example.html <<EOF
Hello, world!
EOF

# create sqlite database
sqlite3 "${NAME}".docset/Contents/Resources/docSet.dsidx <<EOF
CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);

INSERT INTO searchIndex
  (name, type, path) VALUES
  ('example', 'File', 'example.html');
EOF

tar czf "${NAME}".docset.tgz "${NAME}".docset
rm -rf "${NAME}".docset

# create docset feed
cat > ${NAME}.xml <<EOF
<entry>
    <version>${VERSION}</version>
    <url>http://localhost:8080/${NAME}.docset.tgz</url>
</entry>
EOF

echo "To install ${NAME} docset, add this feed to Dash/Zeal:"
echo "http://localhost:8080/${NAME}.xml"

# Start a web server to serve the docset and feed
php -S localhost:8080