#!/bin/sh
# A small shell script for git mirror sync.

GIT_USER="git"
GIT_HOME="/opt/scm/git"
SU="su $GIT_USER -c"

for repos in $GIT_HOME/*; do
    if [ -d $repos ]; then
        $SU "cd $repos && git push"
        echo "Git mirror $repos synced."
    fi
done
exit 0

