# Git


## Log

Roman's git log output format with the graph on left side:
`git log --pretty=tformat:"%C(yellow)%h%Creset | %s %C(red)%d%Creset %C(green)(%ar)%Creset %C(yellow)[%an]%Creset " --graph --date=short`


## Remotes

- `git remote -v`
- `git remote add remote_name https://git.heroku.com/citm-staging.git`
- `git remote rename old_name new_name`
- `git remote set-url origin http://new.url.com/`
- Push to a specific remote and specific branch:
  `git push [remote] [local_branch]:[remote_branch]`


## Config

- `git config --global core.editor` # get the current config value
- `git config --global core.editor "atom --wait"` # set the value


## Queries

List last commit date for each file in a directory:
`for file in ./*; do echo "$file:    $(git log -1 --format=%cd $file)"; done`

Get line count for a project, only including certain folders:
`git ls-files | egrep "(app/|config/|db/|test/|spec/[^_])" | grep -v " " | xargs cat | wc -l`

List the last 10 branches I worked on:
`git for-each-ref --count=10 --sort=-committerdate refs/heads/ --format="%(refname:short)"`

List the top committers with # of commits:
`git shortlog -sn --all --no-merges --since='12 weeks'`


## Diff

- `gd`
- `gd HEAD`
- `gd -w` - ignore whitespace changes (only show substantial changes)
- `gd --cached` - only show staged changes


## Staging

- `git reset HEAD -- <file>` - unstage a specific file (or folder)
