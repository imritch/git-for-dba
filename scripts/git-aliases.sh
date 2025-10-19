#!/bin/bash
# Git Aliases for DBAs
# Run this script to set up helpful Git aliases

echo "Setting up Git aliases for DBAs..."

# Pretty log with graph
git config --global alias.lg "log --oneline --graph --all --decorate"

# More detailed log
git config --global alias.ll "log --oneline --graph --all --decorate --stat"

# Show last commit
git config --global alias.last "log -1 HEAD --stat"

# List all aliases
git config --global alias.aliases "config --get-regexp ^alias\."

# Undo last commit (keep changes)
git config --global alias.undo "reset HEAD~1 --mixed"

# Amend last commit without editing message
git config --global alias.amend "commit --amend --no-edit"

# Show branches with last commit
git config --global alias.br "branch -v"

# Show remote branches
git config --global alias.brr "branch -r -v"

# Stash with message
git config --global alias.save "stash save"

# List stashes
git config --global alias.stashes "stash list"

# Show current branch
git config --global alias.current "rev-parse --abbrev-ref HEAD"

# Show what's changed in working directory
git config --global alias.changed "diff --name-status"

# Show what's staged
git config --global alias.staged "diff --staged --name-status"

# Clean slate - discard all changes
git config --global alias.nuke "reset --hard HEAD"

# Interactive rebase shortcut
git config --global alias.rb "rebase -i"

# Force push with lease (safer)
git config --global alias.pushf "push --force-with-lease"

# Checkout shortcut
git config --global alias.co "checkout"

# Commit shortcut
git config --global alias.ci "commit"

# Status shortcut
git config --global alias.st "status"

# Who changed what
git config --global alias.who "shortlog -sn --"

# Show contributors
git config --global alias.contributors "shortlog --summary --numbered"

echo ""
echo "✅ Git aliases configured! Try these commands:"
echo ""
echo "  git lg              # Pretty log with graph"
echo "  git ll              # Detailed log"
echo "  git last            # Show last commit"
echo "  git undo            # Undo last commit (keep changes)"
echo "  git amend           # Add to last commit"
echo "  git stashes         # List all stashes"
echo "  git changed         # What files changed"
echo "  git staged          # What's staged"
echo "  git nuke            # Discard all changes (careful!)"
echo "  git rb HEAD~5       # Interactive rebase last 5 commits"
echo "  git pushf           # Force push safely"
echo "  git aliases         # List all aliases"
echo ""
echo "Happy Git-ing! 🎉"

