# git-pile
Pull Request Layer-Integrated Edits

## What is this script for?

This bash script is a utility for managing Git branches and pull requests in a specific workflow. It's designed to help developers who work with a branching strategy where multiple commits on a main branch need to be split into separate, stacked branches with corresponding pull requests.

The script provides four main functions:

1. `update`: Creates new branches for each commit in the current branch.
2. `push`: Pushes all created branches to the remote repository.
3. `unpush`: Removes all created branches from the remote repository.
4. `prs`: Creates stacked pull requests for all created branches.

## How to use it

### Prerequisites

- Bash shell
- Git
- GitHub CLI (`gh`) installed and authenticated

### Installation

1. Download the script and place it in your path as `git-pile`, e.g. `/usr/local/bin/git-pile`
2. Make it executable:
   ```
   chmod +x /usr/local/bin/git-pile
   ```

This one-liner accomplishes the above:
```
## Installation
sudo su -c "curl -o /usr/local/bin/git-pile https://raw.githubusercontent.com/csweichel/git-pile/main/pile.sh && chmod +x /usr/local/bin/git-pile"
```

### Usage

The script has four subcommands:

1. Create/update branches:
   ```
   git pile update
   ```

2. Push branches to remote:
   ```
   git pile push
   ```

3. Remove branches from remote:
   ```
   git pile unpush
   ```

4. Create pull requests:
   ```
   git pile prs
   ```

### Typical Workflow

1. Make multiple commits on your main branch.
2. Run `git pile update` to create individual branches for each commit.
3. Run `git pile push` to push these branches to your remote repository.
4. Run `git pile prs` to create stacked pull requests for these branches.
5. After merging or if you need to start over, run `git pile unpush` to remove the created branches from the remote repository.

## Caveats and Important Notes

1. **Branch Naming**: The script creates branches with names in the format `<original-branch-name>--<first-10-chars-commit-msg>-<sha256-hash-commit-msg-trimmed-to-20-chars>`. Ensure this doesn't conflict with your existing branch naming conventions.

2. **Force Push**: The `push` subcommand uses force push (`git push -f`). Be cautious as this can overwrite remote branches if they already exist.

3. **Pull Request Duplication**: Running the `prs` command multiple times will create duplicate pull requests. The script doesn't check for existing PRs.

4. **GitHub CLI Dependency**: The script uses GitHub CLI for creating pull requests. Ensure it's installed and properly configured with your GitHub account.

5. **Branch Order**: Pull requests are created based on the order of branch creation. If you need a different order, you'll need to modify the script.

6. **Single Commit Per Branch**: The script assumes each created branch has only one commit. If you make additional commits on these branches, only the latest commit message will be used for the PR title.

7. **Remote Branch Deletion**: The `unpush` command deletes remote branches matching the created branch pattern. Be sure you want to remove these branches before running this command.

8. **Main Branch Commits**: This script is designed to work on commits in your current branch that aren't in the parent branch. Make sure you're on the correct branch before running the script.

9. **Pull Request Base**: The script determines the parent branch for the first PR and then stacks subsequent PRs on top of each other. Ensure this matches your desired PR structure.

10. **Script Modifications**: If you modify your Git workflow or branch naming convention, you may need to adjust the script accordingly.

Always review the changes made by the script and the created pull requests to ensure they match your expectations.