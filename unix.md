# General

Prevent Mac from sleeping:

    pmset noidle


# Video / image / audio processing

Download a list of songs from Youtube for post-processing:
- Create a file `urls.txt` with one video URL on each line
- irb: `File.open("urls.txt").read.each_line { |l| `youtube-dl -f140 #{l}`; sleep 10 }`
- In another tab: `watch -n5 "ls | grep .m4a | wc -l"`

Convert .png to .jpg, compress size of all .jpgs, and remove the originals:
(1200 is a better standard than 1024.)

    sips -Z 1200 *.jpg *.JPG; for f in *.png; do sips --matchTo '/System/Library/ColorSync/Profiles/sRGB Profile.icc' -Z 1200 -s format jpeg "$f" --out "${f/.png/.jpg}"; rm "$f"; done

Resize all images in-place (ignoring subfolders):

    sips -Z 1200 *.jpg *.JPG

Convert each mp4 file to mp3:

    # will also work with .m4a etc.
    mkdir mp3; for f in *.mp4; do ffmpeg -i "$f" "mp3/$f.mp3"; done

Boost or reduce volume of a video file:

    ffmpeg -i infile -vcodec copy -af "volume=10dB" outfile # or `-5dB` to reduce

Join each mp3 in a folder into one long mp3 (each must have same codec):

    for f in *.mp3; do echo "file '$f'" >> filesToConcatenate.txt; done
    ffmpeg -f concat -safe 0 -i filesToConcatenate.txt -c copy concatenated.mp3


# Finding

Find files by name: (* means "0 or more chars")

    find . -name '*erlang*'

Find all appearances of a text segment in certain files:

    grep "<br" *.xml

Recursively search for text in this dir:

    grep -rnw . -e 'test-manage-custom-fields'


# Queries & text parsing

Show disk space used in this dir and 1 level of subfolders

    du -d1 -h .

List most recently modified files / folders

    ls -lat | head

Get output from a column, ignoring varying whitespace:

    free -m | head -n2 | tail -n1 | awk '{print $4}'

Count LOC in a Rails project. You can add clauses to catch other filetypes. For reference, according to the above metrics, BusBk is 40K lines of code and the GrayOwl Rails site is 64K.

    find . \( -iname '*.rb' -o -iname '*.css' -o -iname '*.js' -o -iname '*.erb' -o -iname -o -iname '*.haml' -o -iname '*.scss' -o -iname '*.coffee' -o -iname '*.pl' \) -exec wc -l {} + | sort -n


# Background processes

- `w` - list all current sessions to this machine, and what they're running
- `last` - list all *recent* sessions on this machine
- `ps aux` - list all running processes
- `nohup [bash command]` # ensure the command doesn't die when your SSH connection ends

# Looping

Infitine loop:

    while : ; do echo "Hi there!"; sleep 1; done

Run a command for each line in a file:

    cat lines.txt | while read line; do echo "This line is: $line"; done

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
