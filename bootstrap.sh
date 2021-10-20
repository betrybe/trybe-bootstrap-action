#!/bin/bash
set -e

# Setup Helm if needed.
HELM=`command -v helm`
if [[ "$HELM" == "" ]]; then
  sudo snap install helm --classic
fi

# Ensure that $GITHUB_TOKEN exists for the remaining of the workflow steps.
if [[ "$GITHUB_TOKEN" != "" ]]; then
  echo "GITHUB_TOKEN=$GITHUB_TOKEN" >> $GITHUB_ENV
fi

# Section: Set Version
if [[ "$ENVIRONMENT" == "preview-app" ]]; then
  VERSION=$(echo "${GITHUB_REF##*refs/heads/}" | tr '/_' '-' | tr [:upper:] [:lower:])
  VALUES_FILE="chart/values-preview-apps.yaml"

elif [[ "$ENVIRONMENT" == "staging" ]]; then
  VERSION="staging"
  VALUES_FILE="chart/values-staging.yaml"
  CHART_FILE="chart/"

else
  VERSION=${GITHUB_SHA:0:9}
  VALUES_FILE="chart/values-production.yaml"

fi

# Helm Linter
helm lint chart/ --strict --values chart/$VALUES_FILE

# Generate a helm "package" for preview apps and production
if [[ "$ENVIRONMENT" != "staging" ]]; then
  CHART_FILE=$(helm package chart/ --app-version=$VERSION | awk -F"/" '{print $NF}')
fi

# Setting environment variables.
echo "VERSION=$VERSION" >> $GITHUB_ENV
echo "CHART_FILE=$CHART_FILE" >> $GITHUB_ENV
echo "VALUES_FILE=$VALUES_FILE" >> $GITHUB_ENV

MSG='
 _____            _
/__   \_ __ _   _| |__   ___
  / /\/ `__| | | | `_ \ / _ \
 / /  | |  | |_| | |_) |  __/
 \/   |_|   \__, |_.__/ \___|
            |___/
   ___ _       _         __
  / _ \ | __ _| |_ __ _ / _| ___  _ __ _ __ ___   __ _
 / /_)/ |/ _` | __/ _` | |_ / _ \| `__| `_ ` _ \ / _` |
/ ___/| | (_| | || (_| |  _| (_) | |  | | | | | | (_| |
\/    |_|\__,_|\__\__,_|_|  \___/|_|  |_| |_| |_|\__,_|

Deploying to:  > $ENVIRONMENT <
Version:       > $VERSION <
'
echo $MSG | envsubst
