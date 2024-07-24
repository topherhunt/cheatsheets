# Steps for rsyncing my music directory

Thanks to https://excessivelyadequate.com/posts/swinsian.html

- Quit Swinsian on both machines.
- Quit any VPN on both machines.
- Destination: Open System Prefs -> Sharing -> Remote Login. Enable it and check the IP for ssh'ing into that machine.

## Syncing FROM local TO a remote destination

```sh
# on the SOURCE:
# Do a dry run, review and confirm that the changed files look correct
rsync -avz --progress --delete --dry-run "/Users/topher/Music/Topher music library" topher@192.168.178.128:~/Music/
# Then do the actual run.
rsync -avz --progress --delete "/Users/topher/Music/Topher music library" topher@192.168.178.128:~/Music/

# on the DESTINATION:
mv ~/Library/Application\ Support/Swinsian/Library.sqlite ~/Library/Application\ Support/Swinsian/Library-OLD.sqlite

# on the SOURCE:
scp ~/Library/Application\ Support/Swinsian/Library.sqlite "topher@192.168.178.128:~/Library/Application Support/Swinsian"
```

## Syncing FROM remote TO local

```sh
# Test that I can connect to the source MBP
ssh topher@192.168.178.128

# Sync all music files (first time will take around an hour)
rsync -avz --progress "topher@192.168.178.128:~/Music/Topher\ music\ library" ~/Music/

# Sync the library DB itself
mv ~/Library/Application\ Support/Swinsian/Library.sqlite ~/Library/Application\ Support/Swinsian/Library-OLD.sqlite
scp "topher@192.168.178.128:~/Library/Application\ Support/Swinsian/Library.sqlite" ~/Library/Application\ Support/Swinsian
```

And unless my home user is named `topher`:

- Open Library.sqlite in SQLite Browser
- Run this query: `UPDATE track SET path = replace(path, '/topher/', '/topherhunt/');`
- **Write my changes** then quit the sqlite browser

- Start Swinsian and check that the library looks OK
