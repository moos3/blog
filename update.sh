#!/usr/bin/env bash

echo "Updating the Site"
hugo -t casper
git add -A
git commit -m "Updating the Site"
git push origin master
git subtree push --prefix=public git@github.com:moos3/blog.git gh-pages
echo "Update and push completed"
