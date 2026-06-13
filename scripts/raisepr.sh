#!/bin/bash

set -e

# Usage:
# ./gitflow.sh feature/login-screen "Added login UI"

BRANCH_NAME=$1
COMMIT_MSG=$2

if [ -z "$BRANCH_NAME" ]; then
  echo "❌ Branch name required"
  echo 'Usage: ./gitflow.sh branch-name "commit message"'
  exit 1
fi

if [ -z "$COMMIT_MSG" ]; then
  COMMIT_MSG="Code changes"
fi

echo "🚀 Starting Git Flow..."

# Save current branch
CURRENT_BRANCH=$(git branch --show-current)

echo "📥 Fetching latest changes..."
git fetch origin

# Checkout main and pull latest
git checkout main
git pull origin main

# Create new branch
echo "🌿 Creating branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"

# Add all changes
git add .

# Commit if changes exist
if git diff --cached --quiet; then
    echo "⚠️ No changes to commit"
else
    git commit -m "$COMMIT_MSG"
fi

echo "📥 Fetching latest main..."
git fetch origin
git checkout main
git pull origin main

git checkout "$BRANCH_NAME"

echo "🔀 Merging latest main..."

if ! git merge origin/main; then
    echo ""
    echo "❌ Merge conflicts detected."
    echo "Resolve conflicts manually and run:"
    echo "git add ."
    echo "git commit"
    exit 1
fi

echo "✅ Merge successful"

echo "🧪 Running tests before push..."
"$(dirname "$0")/run_tests.sh"

echo "⬆️ Pushing branch..."
git push -u origin "$BRANCH_NAME"

echo "📨 Creating Pull Request..."

gh pr create \
  --base main \
  --head "$BRANCH_NAME" \
  --title "$COMMIT_MSG" \
  --body "Auto-generated PR"

echo "🎉 Done!"