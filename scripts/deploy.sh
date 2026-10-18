#!/usr/bin/env bash

set -Eeuo pipefail

APP_NAME="${APP_NAME:-cicd-portfolio}"
PUBLIC_PORT="${PUBLIC_PORT:-80}"

CURRENT_IMAGE="${APP_NAME}-app:latest"
ROLLBACK_IMAGE="${APP_NAME}-app:rollback"

echo "Starting deployment..."

# Save the currently working image
if docker image inspect "$CURRENT_IMAGE" >/dev/null 2>&1; then
    echo "Saving current image for rollback..."
    docker tag "$CURRENT_IMAGE" "$ROLLBACK_IMAGE"
fi

rollback() {
    echo "Deployment failed."

    if docker image inspect "$ROLLBACK_IMAGE" >/dev/null 2>&1; then
        echo "Rolling back to previous image..."

        docker tag "$ROLLBACK_IMAGE" "$CURRENT_IMAGE"

        docker compose up -d \
            --no-build \
            --force-recreate

        echo "Rollback completed."
    else
        echo "No previous image exists for rollback."
    fi
}

trap rollback ERR

echo "Building new application image..."
docker compose build app

echo "Deploying new application..."
docker compose up -d \
    --no-deps \
    --force-recreate app

echo "Waiting for application health check..."

for i in {1..15}; do

    STATUS=$(docker inspect \
        --format='{{.State.Health.Status}}' \
        "${APP_NAME}-app" 2>/dev/null || true)

    echo "Health status: $STATUS"

    if [ "$STATUS" = "healthy" ]; then
        break
    fi

    if [ "$STATUS" = "unhealthy" ]; then
        echo "Application became unhealthy."
        exit 1
    fi

    sleep 2
done

STATUS=$(docker inspect \
    --format='{{.State.Health.Status}}' \
    "${APP_NAME}-app")

if [ "$STATUS" != "healthy" ]; then
    echo "Application did not become healthy."
    exit 1
fi

echo "Starting Nginx..."
docker compose up -d nginx

echo "Testing public endpoint..."

curl --fail \
    --retry 10 \
    --retry-delay 2 \
    --retry-connrefused \
    "http://localhost:${PUBLIC_PORT}"

echo "Deployment successful."
