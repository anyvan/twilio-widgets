#!/bin/bash
set -uo pipefail

DOMAIN="anyvan-com"
DOMAIN_OWNER=331151898531
REPOSITORY="anyvan"

echo "🔑 Getting AWS CodeArtifact authentication token..."
CODEARTIFACT_AUTH_TOKEN=$(aws codeartifact get-authorization-token \
      --domain "${DOMAIN}" \
      --domain-owner "${DOMAIN_OWNER}" \
      --query authorizationToken \
      --output text \
      --profile horizontal)

CODEARTIFACT_REPOSITORY_URL=$(aws codeartifact get-repository-endpoint \
    --domain "${DOMAIN}" \
    --domain-owner "${DOMAIN_OWNER}" \
    --repository "${REPOSITORY}" \
    --format npm \
    --query repositoryEndpoint \
    --profile horizontal \
    --output text)

yarn config set npmScopes.anyvan-ui.npmRegistryServer "${CODEARTIFACT_REPOSITORY_URL}"
yarn config set "npmRegistries[\"${CODEARTIFACT_REPOSITORY_URL}\"].npmAuthToken" "${CODEARTIFACT_AUTH_TOKEN}"
yarn config set npmAuthToken "${CODEARTIFACT_AUTH_TOKEN}"

npm config set @anyvan-ui:registry "${CODEARTIFACT_REPOSITORY_URL}"
npm config set //$(echo "${CODEARTIFACT_REPOSITORY_URL}" | sed 's/https:\/\///'):_authToken "${CODEARTIFACT_AUTH_TOKEN}"

echo "✅ Successfully retrieved CodeArtifact credentials"

echo -e "✨ Configuration complete."
echo "- Auth token has been configured"
