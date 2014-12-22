#!/bin/bash

echo "rake version:bump:major"
rake version:bump:major

echo "rake gemspec"
rake gemspec

echo "git add ."
git add .

echo "git commit -m 'Update gemspec'"
git commit -m 'Update gemspec'
