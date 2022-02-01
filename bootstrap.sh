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
  VALUES_FILE="$PREFIX_DIR/chart/values-preview-apps.yaml"

  # default hostname for preview-apps
  PREVIEW_APP_HOSTNAME=$REPOSITORY-preview-app-$VERSION.betrybe.dev

elif [[ "$ENVIRONMENT" == "staging" ]]; then
  VERSION="staging"
  VALUES_FILE="$PREFIX_DIR/chart/values-staging.yaml"
  CHART_FILE="$PREFIX_DIR/chart/"

elif [[ "$ENVIRONMENT" == "homologation" ]]; then
  VERSION="homologation"
  VALUES_FILE="$PREFIX_DIR/chart/values-homologation.yaml"
  CHART_FILE="$PREFIX_DIR/chart/"

else
  VERSION=${GITHUB_SHA:0:9}
  VALUES_FILE="$PREFIX_DIR/chart/values-production.yaml"

fi

# Helm Linter
# helm lint $PREFIX_DIR/chart/ --strict --values $VALUES_FILE FIX ME

# Generate a helm "package" for preview apps and production
if [[ "$ENVIRONMENT" == "preview-app" || "$ENVIRONMENT" == "production" ]]; then
  CHART_FILE=$(helm package $PREFIX_DIR/chart/ --app-version=$VERSION | awk -F"/" '{print $NF}')
fi

# Setting environment variables.
echo "ENVIRONMENT=$ENVIRONMENT" >> $GITHUB_ENV
echo "VERSION=$VERSION" >> $GITHUB_ENV
echo "CHART_FILE=$CHART_FILE" >> $GITHUB_ENV
echo "VALUES_FILE=$VALUES_FILE" >> $GITHUB_ENV
echo "PREVIEW_APP_HOSTNAME=$PREVIEW_APP_HOSTNAME" >> $GITHUB_ENV
echo "SECRET_SENTRY_RELEASE=$VERSION" >> $GITHUB_ENV
echo '
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
'
