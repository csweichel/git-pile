#!/bin/bash

set -e

# Function to get the parent branch
get_parent_branch() {
    local branch="$1"
    local parent=$(git show-branch | grep '\*' | grep -v "${branch}" | head -n1 | sed 's/.*\[\(.*\)\].*/\1/' | sed 's/[\^~].*//')
    if [ -z "$parent" ]; then
        echo "main"
    else
        echo "$parent"
    fi
}

# Function to sanitize commit message
sanitize_commit_msg() {
    local msg="$1"
    # Remove square brackets and spaces
    echo "$msg" | sed 's/\[//g; s/\]//g' | tr -d '[:space:]'
}

# Function to create branches for new commits
create_branches() {
    local current_branch="$1"
    local parent_branch="$2"

    # Find the common ancestor commit
    common_ancestor=$(git merge-base "$current_branch" "$parent_branch")

    # Get all commit hashes in the current branch that are not in the parent branch
    commit_hashes=$(git rev-list --ancestry-path ${common_ancestor}..${current_branch})

    # Loop through each commit
    for commit in $commit_hashes; do
        # Get the commit message
        commit_msg=$(git log --format=%B -n 1 $commit)
        
        # Sanitize the commit message
        sanitized_msg=$(sanitize_commit_msg "$commit_msg")
        
        # Get the first 10 characters of the sanitized commit message
        commit_msg_short=$(echo "$sanitized_msg" | cut -c 1-10)
        
        # Calculate SHA256 hash of the original commit message and trim to 20 characters
        commit_msg_hash=$(echo "$commit_msg" | sha256sum | cut -c 1-20)
        
        # Create the new branch name
        new_branch_name="${current_branch}--${commit_msg_short}-${commit_msg_hash}"
        
        echo "Creating branch for commit: $commit ($commit_msg)"

        # If the branch exists, delete it
        git branch -D "$new_branch_name" 2>/dev/null || true

        # Create the new branch
        git branch "$new_branch_name" "$commit"

        # Check out the new branch
        git checkout "$new_branch_name"

        # Return to the original branch
        git checkout "$current_branch"

        # Make sure everything's clean
        git reset --hard
        
        echo "Created/Updated branch: $new_branch_name and applied commit"
    done
}

# Subcommand: update
update_command() {
    # Get the current branch name
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    # Get the parent branch
    parent_branch=$(get_parent_branch "$current_branch")

    echo "Current branch: $current_branch"
    echo "Parent branch: $parent_branch"

    create_branches "$current_branch" "$parent_branch"

    echo "All branches have been created/updated and commits applied."
}

# Subcommand: push
push_command() {
    # Get the current branch name
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    # Get all branches with the current branch as prefix
    branches=$(git branch | grep "^  ${current_branch}--" | sed 's/^ *//g')

    # Force push all branches
    for branch in $branches; do
        git push -f --set-upstream origin "$branch"
        echo "Pushed branch: $branch"
    done

    echo "All branches have been pushed."
}

# Subcommand: unpush
unpush_command() {
    # Get the current branch name
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    # Get all remote branches with the current branch as prefix
    remote_branches=$(git ls-remote --heads origin "${current_branch}--*" | cut -f2)

    # Remove all matching remote branches
    for branch in $remote_branches; do
        git push origin --delete "${branch#refs/heads/}"
        echo "Removed remote branch: ${branch#refs/heads/}"
    done

    echo "All generated remote branches have been removed."
}

# Subcommand: prs
prs_command() {
    # Get the current branch name
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    # Get the parent branch
    parent_branch=$(get_parent_branch "$current_branch")

    echo "Current branch: $current_branch"
    echo "Parent branch: $parent_branch"

    # Get all branches with the current branch as prefix, in the order they were created
    branches=$(git branch --sort=creatordate | grep "^  ${current_branch}--" | sed 's/^ *//g')

    # Initialize variables
    previous_branch="$parent_branch"
    first_branch=true

    # Create pull requests for all branches
    while IFS= read -r branch; do
        # Get the commit message from the branch
        commit_msg=$(git log -n 1 --format=%B "$branch")
        
        # Determine the base branch
        if [ "$first_branch" = true ]; then
            base_branch="$parent_branch"
            first_branch=false
        else
            base_branch="$previous_branch"
        fi
        
        # Create pull request
        # Note: This uses GitHub CLI. Make sure it's installed and configured.
        echo gh pr create --base "$base_branch" --head "$branch" --title "$commit_msg" --body "Automatically created pull request for $branch"
        echo "Created pull request for branch: $branch (base: $base_branch)"

        # Update previous_branch for the next iteration
        previous_branch="$branch"
    done <<< "$branches"

    echo "Stacked pull requests have been created for all branches."
}

# Main script
case "$1" in
    update)
        update_command
        ;;
    push)
        push_command
        ;;
    unpush)
        unpush_command
        ;;
    prs)
        prs_command
        ;;
    *)
        echo "Usage: $0 {update|push|unpush|prs}"
        exit 1
        ;;
esac
