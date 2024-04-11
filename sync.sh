#!/bin/bash
# Clone https://github.com/winglang/wing, but only libs/tree-sitter-wing
# and copy the files to the current repository.

rm -rf tmp
git clone --depth 1 https://github.com/winglang/wing.git tmp
pushd tmp
WING_VERSION=$(git describe --tags `git rev-list --tags --max-count=1` | sed 's/v//')
popd
cp -rf tmp/libs/tree-sitter-wing/ ./
rm -rf tmp


# Extra changes that are special for this repo

## Update 0.0.0 in package.json to match the version of the wing repo
jq ".version = \"$WING_VERSION\"" package.json > new.package.json

## Remove "volta" section from package.json
jq 'del(.volta)' new.package.json > package.json

rm -f new.package.json

## Add replace .gitignore
echo "node_modules" > .gitignore
echo "build" >> .gitignore

## Remove unnecessary files
rm -f turbo.json .gitattributes tree-sitter-dsl.d.ts jsconfig.json

pnpm install
pnpm build:generate
pnpm test:update
