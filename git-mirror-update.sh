#!/bin/sh
# A small shell script for git mirror update.

GIT_USER="git"
GIT_HOME="/opt/scm/git"
SU="su $GIT_USER -c"

for repos in $GIT_HOME/*; do
    if [ -d $repos ]; then
        $SU "cd $repos && git remote update"
        echo "Git mirror $repos updated."
    fi
done
exit 0
