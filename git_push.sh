#!/bin/bash

# Script to identify repository and push to the right branch
# Created for Shelfwise LLC

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display messages
print_message() {
  echo -e "${2}${1}${NC}"
}

# Get current directory name
REPO_DIR=$(basename "$(pwd)")
print_message "Repository: $REPO_DIR" "$BLUE"

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
print_message "Current branch: $CURRENT_BRANCH" "$BLUE"

# Get remote URL
REMOTE_URL=$(git remote get-url origin)
print_message "Remote URL: $REMOTE_URL" "$BLUE"

# Check if we have any commits
if [ -z "$(git log -1 --pretty=%H 2>/dev/null)" ]; then
  print_message "No commits found. Please make at least one commit before pushing." "$RED"
  exit 1
fi

# Check if remote repository exists
print_message "Checking if remote repository exists..." "$YELLOW"
git ls-remote --exit-code origin &>/dev/null
REMOTE_EXISTS=$?

if [ $REMOTE_EXISTS -ne 0 ]; then
  print_message "Remote repository does not exist or is not accessible." "$RED"
  print_message "Please check your GitHub credentials and repository permissions." "$YELLOW"
  exit 1
fi

# Check if branch exists on remote
print_message "Checking if branch exists on remote..." "$YELLOW"
REMOTE_BRANCH_EXISTS=$(git ls-remote --heads origin $CURRENT_BRANCH | wc -l)

# Push to the right branch
if [ $REMOTE_BRANCH_EXISTS -eq 0 ]; then
  print_message "Branch '$CURRENT_BRANCH' does not exist on remote. Creating it..." "$YELLOW"
  git push -u origin $CURRENT_BRANCH
  PUSH_RESULT=$?
else
  print_message "Branch '$CURRENT_BRANCH' exists on remote. Pushing updates..." "$YELLOW"
  git push origin $CURRENT_BRANCH
  PUSH_RESULT=$?
fi

# Check push result
if [ $PUSH_RESULT -eq 0 ]; then
  print_message "Successfully pushed to $CURRENT_BRANCH branch of $REPO_DIR repository." "$GREEN"
else
  print_message "Failed to push to remote repository." "$RED"
  print_message "Please check your GitHub credentials and repository permissions." "$YELLOW"
  exit 1
fi

exit 0
