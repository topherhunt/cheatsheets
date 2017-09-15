## Log

- `git log --pretty=tformat:"%C(yellow)%h%Creset | %s %C(red)%d%Creset %C(green)(%ar)%Creset %C(yellow)[%an]%Creset " --graph --date=short`
  # Roman's git log output format with the graph on left side

## Remotes

- `git remote -v`
- `git remote add remote_name https://git.heroku.com/citm-staging.git`
- `git remote rename old_name new_name`
- `git remote set-url origin http://new.url.com/`
- `git push [remote] [local_branch]:[remote_branch]`
  # push to a specific remote and specific branch

## Config

- `git config --global core.editor` # get the current config value
- `git config --global core.editor "atom --wait"` # set the value

## Queries

- `for file in ./*; do echo "$file:    $(git log -1 --format=%cd $file)"; done`
  # list last commit date for each file in a directory
- `git ls-files | egrep "(app/|config/|db/|spec/[^_])" | xargs cat | wc -l`
  # get line count for a project
  # You can modify the regex to specify which folders should be included.
