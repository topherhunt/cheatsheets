# Prevent Mac from sleeping

- `pmset noidle`

# Video / image / audio processing

Convert .png to .jpg, compress size of all .jpgs, and remove the originals:
```
sips -Z 1200 *.jpg *.JPG; for f in *.png; do sips --matchTo '/System/Library/ColorSync/Profiles/sRGB Profile.icc' -Z 1200 -s format jpeg "$f" --out "${f/.png/.jpg}"; rm "$f"; done
```

- `sips -Z 1024 *.jpg *.JPG` # resize all images *in-place* (ignoring subfolders)
- `for f in *.m4a; do ffmpeg -i "$f" "$f.mp3"; done` # convert each m4a file to mp3
- `ffmpeg -i infile -vcodec copy -af "volume=10dB" outfile` # boost volume of a video file
- `ffmpeg -i infile -vcodec copy -af "volume=-5dB" outfile` # reduce volume of a video file

# Finding

- `find . -name '*erlang*'` # find files by name (* means "0 or more chars")
- `grep "<br" *.xml` # find all appearances of a text segment in certain files
- `grep -rnw . -e 'test-manage-custom-fields'` # recursively search for text in this dir

# Queries & text parsing

- `du -d1 -h .` # show disk space used in this dir and 1 level of subfolders
- `ls -lat | head` # list most recently modified files / folders
- `free -m | head -n2 | tail -n1 | awk '{print $4}'`
  # get output from a column, ignoring varying whitespace
- `find . \( -iname '*.rb' -o -iname '*.css' -o -iname '*.js' -o -iname '*.erb' -o -iname -o -iname '*.haml' -o -iname '*.scss' -o -iname '*.coffee' -o -iname '*.pl' \) -exec wc -l {} + | sort -n`
  # count LOC in a Rails project. You can add clauses to catch other filetypes.
  # For reference, according to the above metrics, BusBk is 40K lines of code and the GrayOwl Rails site is 64K.

# Background processes

- `w` - list all current sessions to this machine, and what they're running
- `last` - list all *recent* sessions on this machine
- `ps aux` - list all running processes
- `nohup [bash command]` # ensure the command doesn't die when your SSH connection ends

# Looping

- `while : ; do echo "Hi there!"; sleep 1; done` - infinite loop

# Downloads

- `wget -c <url>` - download a resource, resuming from partial progress if interrupted

# Network

- `nc -vz 52.87.50.47 8008` # test whether a remote host is accessible at a port
- `nc -l 0.0.0.0 8008 > netcat_listen.txt` # listen on a port, log all cxs to a text file
- List all listening ports and the responsible PIDs:
  - `netstat -tuplen` # (Linux)
  - `lsof -Pn -i4` # (OSX)
- `echo '{"text": "Test content"}' | curl -d @- http://domain.com:8000/queries.json`
  # send a test request with JSON data to verify that a JSON service is accessible

Monitor my public IP every second:
`while : ; do dig TXT +short o-o.myaddr.l.google.com @ns1.google.com ; sleep 1 ; done`
