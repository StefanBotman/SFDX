#!/bin/bash -c

set -o errexit    # always exit on error
set -o pipefail   # don't ignore exit codes when piping output
set -o nounset    # fail on unset variables

#################################################################
# Script to setup a fully configured pipeline for Salesforce DX #
#################################################################

### Declare values

# Create a unique var to append
TICKS=$(echo $(date +%s | cut -b1-13))

# Name of your team (optional)
HEROKU_TEAM_NAME=""
#cicd-dev"
HEROKU_BASE_APP_NAME="cicd" 

# Name of the Heroku apps you'll use
HEROKU_DEV_APP_NAME="${HEROKU_BASE_APP_NAME}dev"
HEROKU_STAGING_APP_NAME="${HEROKU_BASE_APP_NAME}staging"
HEROKU_PROD_APP_NAME="${HEROKU_BASE_APP_NAME}prod"

# Pipeline
HEROKU_PIPELINE_NAME="cicd"
#"pipeline$TICKS"

# Usernames or aliases of the orgs you're using
DEV_HUB_USERNAME="DevHub"
DEV_USERNAME="CICDDev"
STAGING_USERNAME="CICDTest"
PROD_USERNAME="CICDProd"

# Repository with your code
GITHUB_REPO="StefanBotman/SFDX"

### Setup script

# Support a Heroku team
HEROKU_TEAM_FLAG=""
if [ ! "$HEROKU_TEAM_NAME" == "" ]; then
  HEROKU_TEAM_FLAG="-t $HEROKU_TEAM_NAME"
fi

HEROKU_REGION="eu"

# Create three Heroku apps to map to orgs
echo "Creating the orgs"
echo "heroku apps:create $HEROKU_DEV_APP_NAME $HEROKU_TEAM_FLAG --region $HEROKU_REGION --remote development"
#heroku apps:create $HEROKU_DEV_APP_NAME $HEROKU_TEAM_FLAG --region $HEROKU_REGION --remote development
echo "Dev done, staging next"
#heroku apps:create $HEROKU_STAGING_APP_NAME $HEROKU_TEAM_FLAG --region $HEROKU_REGION --remote staging
echo "Staging done, prod next"
#heroku apps:create $HEROKU_PROD_APP_NAME $HEROKU_TEAM_FLAG --region $HEROKU_REGION --remote production
echo "Prod done, continuing"
# Set the stage (since STAGE isn't required, review apps don't get one)
#heroku config:set STAGE=DEV -a $HEROKU_DEV_APP_NAME
#heroku config:set STAGE=STAGING -a $HEROKU_STAGING_APP_NAME
#heroku config:set STAGE=PROD -a $HEROKU_PROD_APP_NAME

# Turn on debug logging
#heroku config:set SFDX_BUILDPACK_DEBUG=false -a $HEROKU_DEV_APP_NAME
#heroku config:set SFDX_BUILDPACK_DEBUG=false -a $HEROKU_STAGING_APP_NAME
#heroku config:set SFDX_BUILDPACK_DEBUG=false -a $HEROKU_PROD_APP_NAME

# Setup sfdxUrl's for auth
echo "set auth urls"
devHubSfdxAuthUrl=$(sfdx force:org:display --verbose -u $DEV_HUB_USERNAME --json | jq -r .result.sfdxAuthUrl)
#heroku config:set DEV_HUB_SFDX_AUTH_URL=$devHubSfdxAuthUrl -a $HEROKU_DEV_APP_NAME
echo "set dev hub auth url"
devSfdxAuthUrl=$(sfdx force:org:display --verbose -u $DEV_USERNAME --json | jq -r .result.sfdxAuthUrl)
#heroku config:set SFDX_AUTH_URL=$devSfdxAuthUrl -a $HEROKU_DEV_APP_NAME &
echo "set dev auth url"
stagingSfdxAuthUrl=$(sfdx force:org:display --verbose -u $STAGING_USERNAME --json | jq -r .result.sfdxAuthUrl)
#heroku config:set SFDX_AUTH_URL=$stagingSfdxAuthUrl -a $HEROKU_STAGING_APP_NAME & wait
echo "set staging auth url"
stagingSfdxAuthUrl=$(sfdx force:org:display --verbose -u $PROD_USERNAME --json | jq -r .result.sfdxAuthUrl)
#heroku config:set SFDX_AUTH_URL=$stagingSfdxAuthUrl -a $HEROKU_PROD_APP_NAME & wait
echo "set prod auth url"
# Add buildpacks to apps
#heroku buildpacks:add -i 1 https://github.com/wadewegner/salesforce-cli-buildpack#v3 -a $HEROKU_DEV_APP_NAME & wait
echo "add buildpack v3 for dev"
#heroku buildpacks:add -i 1 https://github.com/wadewegner/salesforce-cli-buildpack#v3 -a $HEROKU_STAGING_APP_NAME & wait
echo "add buildpack v3 for staging"
#heroku buildpacks:add -i 1 https://github.com/wadewegner/salesforce-cli-buildpack#v3 -a $HEROKU_PROD_APP_NAME & wait
echo "add buildpack v3 for prod"

#heroku buildpacks:add -i 2 https://github.com/wadewegner/salesforce-dx-buildpack#v3 -a $HEROKU_DEV_APP_NAME & wait
echo "add buildpack dx v3 for dev"
#heroku buildpacks:add -i 2 https://github.com/wadewegner/salesforce-dx-buildpack#v3 -a $HEROKU_STAGING_APP_NAME & wait
echo "add buildpack dx v3 for staging"
#heroku buildpacks:add -i 2 https://github.com/wadewegner/salesforce-dx-buildpack#v3 -a $HEROKU_PROD_APP_NAME & wait
echo "add buildpack dx v3 for prod"

# Create Pipeline
# Valid stages: "test", "review", "development", "staging", "production"
#heroku pipelines:create $HEROKU_PIPELINE_NAME -a $HEROKU_DEV_APP_NAME -s development $HEROKU_TEAM_FLAG & wait
heroku pipelines:add $HEROKU_PIPELINE_NAME -a $HEROKU_STAGING_APP_NAME -s staging & wait
heroku pipelines:add $HEROKU_PIPELINE_NAME -a $HEROKU_PROD_APP_NAME -s production & wait
# bug: https://github.com/heroku/heroku-pipelines/issues/80
# heroku pipelines:setup $HEROKU_PIPELINE_NAME $GITHUB_REPO -y $HEROKU_TEAM_FLAG

heroku ci:config:set -p $HEROKU_PIPELINE_NAME DEV_HUB_SFDX_AUTH_URL=$devHubSfdxAuthUrl & wait
heroku ci:config:set -p $HEROKU_PIPELINE_NAME SFDX_AUTH_URL=$devSfdxAuthUrl & wait
heroku ci:config:set -p $HEROKU_PIPELINE_NAME SFDX_BUILDPACK_DEBUG=false & wait

# Clean up script
echo "heroku pipelines:destroy $HEROKU_PIPELINE_NAME
heroku apps:destroy -a $HEROKU_DEV_APP_NAME -c $HEROKU_DEV_APP_NAME
heroku apps:destroy -a $HEROKU_STAGING_APP_NAME -c $HEROKU_STAGING_APP_NAME
heroku apps:destroy -a $HEROKU_PROD_APP_NAME -c $HEROKU_PROD_APP_NAME" > destroy.sh

echo ""
echo "Run ./destroy.sh to remove resources"
echo ""
