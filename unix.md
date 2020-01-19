# General

Prevent Mac from sleeping:

    pmset noidle


## Video / image / audio processing

Download a list of songs from Youtube for post-processing:

  - Create a file `urls.txt` with one video URL on each line

  - irb:
    ```rb
    File.open("urls.txt").read.each_line { |l| puts "Downloading #{l}..."; `youtube-dl -f140 #{l}`; sleep 10 }
    ```

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


## Searching & listing files

List most recently modified files / folders

    ls -lat | head

Find files by name: (* means "0 or more chars")

    find . -name '*erlang*'

Find all appearances of a text segment in certain files:

    grep "<br" *.xml

Recursively search for text in this dir:

    grep -rnw . -e 'test-manage-custom-fields'


## Resources

Show disk space used in this dir and 1 level of subfolders

    du -d1 -h .


## Text parsing

Get output from a column, ignoring varying whitespace:

    free -m | head -n2 | tail -n1 | awk '{print $4}'

Count LOC in all source code files. For reference: BusBK is 40K loc; GrayOwl is 64K; GlassFrog is 99K (as of 2019-04) and was 141K (as of 2017-01);  RTL is 8.5K (as of 2019-06).

    git ls-files | egrep "\.(txt|md|sh|rb|erb|html|haml|ex|exs|eex|js|jsx|json|css|scss|lock|yml)$" | egrep -v "/vendor/|package-lock\.json|schema\.json|yarn\.lock|Gemfile\.lock|cdn_backup|third_party" | sed 's/.*/"&"/' | xargs wc -l

Using sed to replace a substring by regex:

```sh
# Note the leading $ - necessary for \t to be escaped properly
# On Linux, use `sed -r` instead of `sed -E`
cat combined.tsv \
  | sed -E $'s#^[0-9]+\t([0-9\-]+ [0-9\:]+)\t[0-9\-]+ [0-9\:]+\t[0-9]+\t[A-z\-]+\t([0-9\.]+)\t[A-z0-9]+\t[A-z]+\t([A-z0-9\/\.]+)\t#\\3\t\\1\t#g'
```


## Background processes

- `w` - list all current sessions to this machine, and what they're running
- `last` - list all *recent* sessions on this machine
- `ps aux` - list all running processes
- `nohup [bash command]` # ensure the command doesn't die when your SSH connection ends


## Looping

Infitine loop:

    while : ; do echo "Hi there!"; sleep 1; done

Run a command for each line in a file:

    cat lines.txt | while read line; do echo "This line is: $line"; done


## Downloads

- `wget -c <url>` - download a resource, resuming from partial progress if interrupted


## Command-line CSV viewer

I haven't tested these, but some ideas are:

- https://www.stefaanlippens.net/pretty-csv.html
- `tabview`: https://superuser.com/a/1381292/233455 (works great)
- Vim CSV plugin: https://superuser.com/a/913186/233455

