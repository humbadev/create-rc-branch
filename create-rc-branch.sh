#!/bin/bash
set -e

# ===========================================
# Check required parameters
# ===========================================
if [ -z "$1" ]; then
  echo "DEV_BRANCH parameter is required!"
  echo "Usage: ./create-rc-ready.sh DEV_BRANCH TEAM_RC_BRANCH"
  exit 1
fi

if [ -z "$2" ]; then
  echo "TEAM_RC_BRANCH parameter is required!"
  echo "Usage: ./create-rc-ready.sh DEV_BRANCH TEAM_RC_BRANCH"
  exit 1
fi

DEV_BRANCH="$1"
TEAM_RC_BRANCH="$2"
RC_BRANCH="${DEV_BRANCH/-dev/-rc-ready}"

echo "=================================================="
echo "🚀 Creating RC branch for team: $TEAM_RC_BRANCH"
echo "Source branch: $DEV_BRANCH"
echo "Target branch: $RC_BRANCH"
echo "=================================================="
echo

# ===========================================
# Step 1: Checkout and update team RC branch
# ===========================================
echo "🔄 Checking out base RC branch '$TEAM_RC_BRANCH'..."
git checkout "$TEAM_RC_BRANCH"
git pull --rebase origin "$TEAM_RC_BRANCH"
echo "✅ Base branch is up to date."
echo

# ===========================================
# Step 2: Create new ticket-specific RC branch
# ===========================================
echo "🌿 Creating new RC branch: $RC_BRANCH..."
git checkout -b "$RC_BRANCH"
echo "✅ New branch '$RC_BRANCH' created from '$TEAM_RC_BRANCH'."
echo

# ===========================================
# Step 3: Cherry-pick commits from dev branch
# ===========================================
echo "📌 Fetching latest commits from $DEV_BRANCH..."
git fetch origin "$DEV_BRANCH"

# Find merge base between team RC and dev branch
MERGE_BASE=$(git merge-base "$TEAM_RC_BRANCH" "origin/$DEV_BRANCH")

# Get commits newer than merge base
git log "$MERGE_BASE..origin/$DEV_BRANCH" --pretty=format:"%h" --reverse > commits.txt

if [ ! -s commits.txt ]; then
  echo "ℹ️ No new commits to cherry-pick from $DEV_BRANCH"
  echo "✅ RC branch '$RC_BRANCH' is up-to-date with team base."
  rm commits.txt
else
  echo "🔍 Commits to cherry-pick:"
  git log "$MERGE_BASE..origin/$DEV_BRANCH" --oneline
  echo

  while read commit_hash; do
    if [ -n "$commit_hash" ]; then
      echo "🍒 Cherry-picking commit: $commit_hash"
      if ! git cherry-pick "$commit_hash"; then
        echo "⚠️ Cherry-pick conflict at commit $commit_hash! Aborting."
        git cherry-pick --abort
        rm commits.txt
        exit 1
      fi
    fi
  done < commits.txt

  rm commits.txt
  echo "✅ All commits cherry-picked successfully."
fi
echo

# ===========================================
# Step 4: Compare branches
# ===========================================
echo "🔍 Comparing $DEV_BRANCH and $RC_BRANCH..."
if git diff --quiet "origin/$DEV_BRANCH" "$RC_BRANCH"; then
  echo "✅ Branches match! $RC_BRANCH is up-to-date with $DEV_BRANCH."
else
  echo "ℹ️ Differences exist - expected since RC branch is based on team RC."
  echo "📊 Summary of changes:"
  git log "$TEAM_RC_BRANCH..$RC_BRANCH" --oneline
fi
echo

# ===========================================
# Step 5: Push RC branch to Bitbucket
# ===========================================
echo "🚀 Pushing RC branch to Bitbucket..."
git push -u origin "$RC_BRANCH" || {
  echo "❌ Push failed! Manual intervention required."
  exit 1
}
echo "✅ Branch '$RC_BRANCH' pushed successfully."
echo "=================================================="
echo "🎉 RC branch '$RC_BRANCH' is ready!"
echo "📋 Summary:"
echo "   • Base: $TEAM_RC_BRANCH"
echo "   • Created: $RC_BRANCH"
echo "   • Source: $DEV_BRANCH"
echo "=================================================="
