#!/bin/sh
# Cloudflare Pages build: copies only the website's own files into dist/, which is what gets published.
# Everything else in the repository (supabase/*.sql, this script, git files) stays private.
# Cloudflare Pages settings: build command "sh build.sh", output directory "dist".
set -e
rm -rf dist
mkdir dist
cp index.html admin.html privacy.html config.js teams.js league.js admin-sw.js admin.webmanifest favicon.ico dist/
cp -R images fonts vendor dist/
echo "Built dist/ with $(find dist -type f | wc -l | tr -d ' ') files"
