#!/usr/bin/env bash

# promote-to-staging.sh
# Promotes changes from dev branch to staging branch

set -e  # Exit on any error

# Configuration
SOURCE_BRANCH="dev"
TARGET_BRANCH="staging"
REMOTE="origin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Ensure we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    log_error "Not inside a git repository"
    exit 1
fi

# Fetch latest changes
log_info "Fetching latest changes from ${REMOTE}..."
git fetch "$REMOTE"

# Check if branches exist
if ! git show-ref --verify --quiet "refs/remotes/${REMOTE}/${SOURCE_BRANCH}"; then
    log_error "Source branch '${SOURCE_BRANCH}' does not exist on ${REMOTE}"
    exit 1
fi

if ! git show-ref --verify --quiet "refs/remotes/${REMOTE}/${TARGET_BRANCH}"; then
    log_error "Target branch '${TARGET_BRANCH}' does not exist on ${REMOTE}"
    exit 1
fi

# Save current branch to return later
ORIGINAL_BRANCH=$(git branch --show-current)

# Checkout and update target branch
log_info "Checking out ${TARGET_BRANCH}..."
git checkout "$TARGET_BRANCH"
git pull "$REMOTE" "$TARGET_BRANCH"

# Perform the merge
log_info "Merging ${SOURCE_BRANCH} into ${TARGET_BRANCH}..."
if git merge "${REMOTE}/${SOURCE_BRANCH}" --no-edit; then
    log_info "Merge successful. Pushing to ${REMOTE}..."
    git push "$REMOTE" "$TARGET_BRANCH"
    log_info "✅ Successfully promoted ${SOURCE_BRANCH} → ${TARGET_BRANCH}"
else
    log_error "Merge conflict detected!"
    log_warn "Aborting merge and restoring original state..."
    git merge --abort
    git checkout "$ORIGINAL_BRANCH"
    exit 1
fi

# Return to original branch
if [ -n "$ORIGINAL_BRANCH" ]; then
    log_info "Returning to ${ORIGINAL_BRANCH}..."
    git checkout "$ORIGINAL_BRANCH"
fi