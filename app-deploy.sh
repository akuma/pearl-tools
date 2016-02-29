#!/bin/sh
# A shell script for deploy apps to test/production server.
# Usage: app-deploy.sh [rsync|git|other] [APP] [BRANCH] [RSYNC SRC] [RSYNC DST]

DEPLOY_TYPE=$1
APP=$2
BRANCH=$3
RSYNC_SRC=$PWD/$4
RSYNC_DST=$5

APP_ROOT="~/app-deploy"
APP_HOME=$APP_ROOT/$APP

RSYNC_CMD="rsync -avzc --progress --delete --exclude=.git --exclude=*.log --exclude=*.java"

if [ $DEPLOY_TYPE = "rsync" ]; then
    echo "Rsyncing $RSYNC_SRC -> $RSYNC_DST..."
    $RSYNC_CMD $RSYNC_SRC $RSYNC_DST
    exit 0
fi

# First, change to app home
cd $APP_HOME
git checkout .
git checkout $BRANCH

if [ $DEPLOY_TYPE = "git" ]; then
    echo "Pulling $APP from source server..."
    git pull origin $BRANCH

    echo "Pushing $APP to prodution server..."
    git push zhx $BRANCH
else
    echo "Pulling $APP from prodution server..."
    git pull origin $BRANCH

    echo "Rsyncing $RSYNC_SRC -> $APP_HOME..."
    $RSYNC_CMD $RSYNC_SRC .

    # Commit changes
    git add .
    git commit -am "Publish $APP: $BUILD_TAG"

    # Push changes to prodution server
    echo "Pushing $APP to prodution server..."
    git push -u origin $BRANCH
fi

exit 0
