#!/bin/bash

echo "rake version:bump:patch"
rake version:bump:minor

echo "rake gemspec"
rake gemspec

echo "git add ."
git add .

echo "git commit -m 'Update gemspec'"
git commit -m 'Update gemspec'
