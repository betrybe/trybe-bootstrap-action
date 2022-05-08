#!/bin/bash
set -e

# If the repository is a monorepo then the envvar `$PIPELINE_MODE` must
# be set to "monorepo" in order to the pipeline work properly.
sub_dir="."
if [[ "$PIPELINE_MODE" == "monorepo" ]]; then
  if [[ -z ${REPOSITORY_PATH} ]]; then
    REPOSITORY_PATH=""
  fi
  sub_dir="$REPOSITORY_PATH$REPOSITORY"
fi

# Setup Helm if needed.
if [[ -z "$(command -v helm)" ]]; then
  sudo snap install helm --classic
fi

# Ensure that 'templates' folder is up-to-date
echo "----------------------------"
git clone https://x-access-token:$BOOTSTRAP_TOKEN@github.com/betrybe/trybe-pipeline-template.git \
  && cp -fR trybe-pipeline-template/chart/templates $sub_dir/chart/ \
  && echo "Using LIVE helm templates!" \
  || echo "Using STATIC helm templates!"
echo "----------------------------"

# Section: Set Version
version=${GITHUB_SHA:0:9}
values_file="$sub_dir/chart/values-production.yaml"
chart_file=""
preview_app_hostname=""
if [[ "$ENVIRONMENT" == "preview-app" ]]; then
  #version=$(echo "${GITHUB_REF##*refs/heads/}" | tr '/_' '-' | tr [:upper:] [:lower:])
  version=$(echo "${GITHUB_REF##*refs/heads/}" | tr '/_' '-' | awk -F "/" '{print $4}'
  values_file="$sub_dir/chart/values-preview-apps.yaml"

  # Default hostname for preview-apps
  preview_app_hostname=$REPOSITORY-preview-app-$version.betrybe.dev

  #echo "automation/refs/pull/4684/merge" | awk -F "/" '{print $4}'
  #awk -F "/" '{print $4}'

elif [[ "$ENVIRONMENT" == "staging" ]] || [[ "$ENVIRONMENT" == "homologation" ]]; then
  version="$ENVIRONMENT"
  values_file="$sub_dir/chart/values-$ENVIRONMENT.yaml"
  chart_file="$sub_dir/chart/"

fi
# Generate a helm "package" for preview apps and production
if [[ "$ENVIRONMENT" == "preview-app" || "$ENVIRONMENT" == "production" ]]; then
  chart_file=$(helm package $sub_dir/chart/ --app-version=$version | awk -F"/" '{print $NF}')
fi

# Helm Linter
helm lint $sub_dir/chart/ --values $values_file

# Setting environment variables.
echo "ENVIRONMENT=$ENVIRONMENT" >> $GITHUB_ENV
echo "VERSION=$version" >> $GITHUB_ENV
echo "CHART_FILE=$chart_file" >> $GITHUB_ENV
echo "VALUES_FILE=$values_file" >> $GITHUB_ENV
echo "PREVIEW_APP_HOSTNAME=$preview_app_hostname" >> $GITHUB_ENV
echo "SECRET_SENTRY_RELEASE=${GITHUB_SHA:0:9}" >> $GITHUB_ENV
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
