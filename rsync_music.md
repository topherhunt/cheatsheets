# Steps for rsyncing my music directory

Thanks to https://excessivelyadequate.com/posts/swinsian.html

- Source MBP: open System Prefs -> Sharing -> Remote Login. Enable it and check the IP for ssh'ing into that machine.
- Destination MBP: Quit Swinsian

```sh

# Test that I can connect to the source MBP
ssh topher@192.168.178.71

# Sync all music files (first time will take around an hour)
rsync -avz --progress "topher@192.168.178.71:~/Music/Topher\ music\ library" ~/Music/

# Sync the library DB itself
rm ~/Library/Application\ Support/Swinsian/Library.sqlite
scp "topher@192.168.178.71:~/Library/Application\ Support/Swinsian/Library.sqlite" ~/Library/Application\ Support/Swinsian

```

- Open Library.sqlite in SQLite Browser
- Run this query: `UPDATE track SET path = replace(path, '/topher/', '/topherhunt/');`
- **Write my changes** then quit the sqlite browser

- Start Swinsian and check that the library looks OK
