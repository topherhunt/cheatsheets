## Image processing

- `sips -Z 1024 *.jpg *.JPG` # resize all images *in-place* (ignoring subfolders)

## Finding

- `find . -name '*erlang*'` # find files by name (* means "0 or more chars")
- `grep "<br" *.xml` # find all appearances of a text segment in certain files
- `grep -rnw . -e 'test-manage-custom-fields'` # recursively search for text in this dir

## Execute command for each file in a folder

`for f in *.m4a; do ffmpeg -i "$f" "$f.mp3"; done`

## Queries & text parsing

- `du -d1 -h .` # show disk space used in this dir and 1 level of subfolders
- `ls -lat | head` # list most recently modified files / folders
- `free -m | head -n2 | tail -n1 | awk '{print $4}'`
  # get output from a column, ignoring varying whitespace
- `find . \( -iname '*.rb' -o -iname '*.css' -o -iname '*.js' -o -iname '*.erb' -o -iname -o -iname '*.haml' -o -iname '*.scss' -o -iname '*.coffee' -o -iname '*.pl' \) -exec wc -l {} + | sort -n`
  # count LOC in a Rails project. You can add clauses to catch other filetypes too.
  # For reference, according to the above metrics, BusBk is 40K lines of code and the GrayOwl Rails site is 64K.

## Background processes & looping

- `nohup [bash command]` # ensure the command doesn't die when your SSH connection ends
- `while : ; do echo "Hi there!"; sleep 1; done` - infinite loop

## Network

- `nc -vz 52.87.50.47 8008` # test whether a remote host is accessible at a port
- `nc -l 0.0.0.0 8008 > netcat_listen.txt` # listen on a port, log all cxs to a text file
- `netstat -tuplen` # list all listening ports and the responsible PIDs
- `echo '{"text": "Test content"}' | curl -d @- http://domain.com:8000/queries.json`
  # send a test request with JSON data to verify that a JSON service is accessible
