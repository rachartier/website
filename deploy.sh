#!/bin/bash

git fetch
if [[ "$(git rev-parse HEAD)" != "$(git rev-parse @{u})" ]]
	then echo "\033[31mCurrent branch is not up-to-date, please pull first!\033[0m"
	exit
fi

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

# Build the project.
hugo -t hermit # if using a theme, replace with `hugo -t <YOURTHEME>`

# Add changes to git.
git add .

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

# Push source and build repos.
git push origin master
git subtree push --prefix=public git@github.com:rachartier/rachartier.github.io.git gh-pages

# Come Back up to the Project Root
cd ..
