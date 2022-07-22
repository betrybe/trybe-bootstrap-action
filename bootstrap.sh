#!/bin/bash
set -e
PIPELINE_REPOSITORY="betrybe/trybe-pipeline-template"

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

# Check if we are using LIVE or STATIC helm templates.
if [[ $TEMPLATE_MODE != "static" ]]; then

  git clone https://x-access-token:$BOOTSTRAP_TOKEN@github.com/$PIPELINE_REPOSITORY.git \
    && cp -fR trybe-pipeline-template/chart/templates $sub_dir/chart/
  result=$?

  if [[ $result -eq 0 ]]; then
    echo -e "\nUsing LIVE helm templates!"
  else
    echo -e "\nHOLD HOLD HOLD\nCloning '$PIPELINE_REPOSITORY' has failed and \$TEMPLATE_MODE is not 'static'."
    exit 1
  fi
else
  echo -e "\nUsing STATIC helm templates! (forced by TEMPLATE_MODE=static)"
fi

# Section: Set Version
version=${GITHUB_SHA:0:9}
values_file="$sub_dir/chart/values-production.yaml"
chart_file=""
preview_app_hostname=""
if [[ "$ENVIRONMENT" == "preview-app" ]]; then
  version=$(echo "${GITHUB_REF##*refs/heads/}" | awk -F "/" '{print $3}')
  values_file="$sub_dir/chart/values-preview-apps.yaml"

  # Default hostname for preview-apps
  preview_app_hostname=$REPOSITORY-preview-app-$version.betrybe.dev

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
'
