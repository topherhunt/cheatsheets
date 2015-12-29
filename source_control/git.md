# Git

## Remotes

- List current remotes: `git remote -v`
- Add a remote: `git remote add remote_name https://git.heroku.com/citm-staging.git`
- Rename a remote: `git remote rename old_name new_name`
- Change a remote's URL: `git remote set-url origin http://new.url.com/`
- Push a different branch name: `git push staging overhaul:master`
  (`git push [remote_label] [local_branch]:[remote_branch]`)

## Config

- Set the global editor: `git config --global core.editor "atom --wait"`
