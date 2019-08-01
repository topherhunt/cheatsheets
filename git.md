# Git


## Basic commands

These commands should be all you need to track your code changes using Git:

  * `git init .` - create a new Git repository in this folder

  * `git status` - list any changes since the last commit

  * `git add --all` - add ("stage") all file changes for committing. (You can also add files one-by-one if you want finer-grained control.)

  * `git commit -m "Some commit message"` - commit all staged changes, with a descriptive summary

  * `git log` - List all your changes in descending order

  * `git remote add origin https://your-github-repository-url` - add your Github (or Gitlab or Bitbucket) repository so you can push your changes there

  * `git push origin master` - push your latest commits from the `master` branch, to the remote repository named `origin` (which lives on Github or similar).

  * `git checkout SOME_COMMIT_ID` - restore the code to an older commit (you can find the commit id in `git log`). Be sure to `git checkout master` to return to the "tip" of the `master` branch, before you make any code changes or commits!


## Basic workflow using SourceTree

There's no reason you need to memorize intricate terminal commands if your Git workflow is simple. I think the following steps should enable a simple single-branch workflow so you can at least review and commit your changes and sync them to a remote repository.

  * Install SourceTree: https://www.sourcetreeapp.com/

  * To start a Git repository for a folder on your computer, drag the folder onto Sourcetree's list of "local" repositories. Then double-click the newly created repository to view changes and make commits.

  * When viewing a repository's "File status" panel (the default view), all file changes will be listed in the left-hand panel (including new files detected).

  * To make a commit, select all files (or just those files you want to include in this commit), write in a commit message in the box below, then click Commit.

  * After you've made a few commits, click on the History panel to list all commits. Click (once) on a commit to see the details and a diff of all changes.

  * To revert your code to an earlier commit, double-click on that commit. This will return all files to the state they were in when you made that commit, so you can review the code and run the server as it ran at that point, etc.

    - Be careful to return to the top commit (ie. the tip of the `master` branch) before you make any code changes!

  * To push your commits to a remote repository (e.g. on Github), first go to the provider's website and create a repository there. Then in Sourcetree, go to Settings -> Remotes -> Add, then paste in the repository URL that the website should be showing you. Now you can click the Push button to push your latest commits to the remote repository. After pushing, you should be able to refresh the Github page and see your files there.

  * You probably don't need to worry about the more advanced concepts for a while. Branches are useful you want to work on a big long-running change without messing with your "master" code, then merge in all of the changes at the end. Tags are useful when you're a big open-source project and you need to label each version you release. Don't use stashes, submodules, or subtrees.


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
