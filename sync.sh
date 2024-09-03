#!/bin/bash
set -euxo pipefail

# Clone https://github.com/winglang/wing, but only libs/tree-sitter-wing
# and copy the files to the current repository.

# Clean everything except sync.sh
ls | grep -xv "sync.sh" | xargs rm -rf || true
rm -f .gitignore

rm -rf tmp
git clone https://github.com/winglang/wing.git tmp

# Get the latest published version, so we aren't trying to sync with a broken build
pushd tmp
WING_VERSION=$(git describe --tags `git rev-list --tags --max-count=1` | sed 's/v//')
git checkout "v$WING_VERSION"
popd

# Copy files from tmp/packages/@winglang/tree-sitter-wing to current dir
rsync -av --progress tmp/packages/@winglang/tree-sitter-wing/ .
rm -rf tmp

echo "Retrieved wing version: $WING_VERSION"

# Extra changes that are special for this repo

## Remove "volta" section from package.json
jq 'del(.volta)' package.json > new.package.json
mv -f new.package.json package.json

## Add replace .gitignore
echo "node_modules
build
target" > .gitignore

# Update other versions
perl -pi -e s,0.0.0,$WING_VERSION,g Cargo.toml pyproject.toml Makefile package.json

## Remove extra files
rm -f turbo.json .gitattributes tree-sitter-dsl.d.ts jsconfig.json

pnpm install
pnpm install # second time to make sure nodegyp runs
pnpm tree-sitter generate
pnpm test
