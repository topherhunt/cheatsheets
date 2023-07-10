# General

Command-line CSV spreadsheet viewer: [VisiData](https://github.com/saulpw/visidata).


## Homebrew

- `brew list` - list all installed packages
- `brew info PACKAGE` - show info on a package: installed versions, etc.
- `brew switch PACKAGE VERSION` - activate a specific installed version of a package
- `brew ls --versions PACKAGE`
- `brew --prefix openssl` - get the path to that package's folder
- https://cmsdk.com/python/homebrew-install-specific-version-of-formula.html
- `brew cleanup -s` - clean up unused packages


## Video / image / audio processing

See also https://github.com/yuanqing/vdx - a friendlier ffmpeg wrapper.

Download a list of songs from Youtube for post-processing:

  - Create a file `urls.txt` with one video URL on each line

  - Open `irb` and run:
    ```rb
    File.open("urls.txt").read.each_line { |l| print "Downloading #{l}"; `youtube-dl -f140 #{l}`; sleep 10 }
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

    ffmpeg -i "file.mp4" -vcodec copy -af "volume=10dB" "new.mp4" # or `-5dB` to reduce

Downscale resolution of a video file:

    ffmpeg -i "file.mp4" -vf scale=800:600 -c:a libfdk_aac "new.mp4"
    ffmpeg -i input.mp4 -vf scale=360x640 -c:a libfdk_aac output.mp4

Join each mp3 in a folder into one long mp3 (each must have same codec):

    for f in *.mp3; do echo "file '$f'" >> filesToConcatenate.txt; done
    ffmpeg -f concat -safe 0 -i filesToConcatenate.txt -c copy concatenated.mp3

Convert a .webm video (eg. captured stream) to an .mp4 video, scaled, and set framerate:

    # .webm can be fragile; the following options improve conversion speed & quality:
    # -r: sets the output video framerate (60fps is only a bit larger on disk than 30fps)
    # -vf: sets the output video resolution
    # -vbr: specify varible audio bitrate (5 = highest quality)
    # -c: specify the audio codec libfdk_aac (much higher quality than the default codec)
    # (May need to recompile ffmpeg: http://trac.ffmpeg.org/wiki/CompilationGuide/macOS)
    # To TEST conversion with a small clip, add output flags -ss 00:02:00.0 -t 00:00:20.0
    ffmpeg -i "file.webm" -r 60 -vf scale=800:600 -c:a libfdk_aac -vbr 5 mp4/file.mp4

How to clip a .mp4 file without decoding & re-encoding:

    # -c copy: skip decoding & re-encoding (same encoding will be used)
    # -ss 00:02:00.0 -t 00:00:20.0: start at 2 mins 0 secs, and cut after 20 secs.
    ffmpeg -i "file.mp4" -c copy -ss 00:02:40.0 -t 00:02:25.0 file-clipped.mp4

Use https://github.com/deezer/spleeter or https://splitter.ai/ to separate a song into stems.


## Searching & listing files

List most recently modified files / folders

    ls -lat | head

Find files by name: (* means "0 or more chars")

    find . -name '*erlang*'

    # Find all tax-related documents, case-insensitive
    find ~ -iname "*tax*" -type f | egrep -i -v "\.(rb|erb|ex|exs|cache|py|pyc|js|jpg|png|yml|c|h|o|y|html|scss)$" | egrep -v "(\/Sites)"

Find all appearances of a text segment in certain files:

    grep "<br" *.xml

Recursively search for text in this dir:

    grep -rnw . -e 'test-manage-custom-fields'

https://github.com/jhspetersson/fselect - interesting tool, lets you query various attrs of files on disk using a sql-like syntax.


## Resources

Show disk space used in this dir and 1 level of subfolders:

    du -h -d1 .

Same thing, but sort by human-readable usage size:

    du -h -d1 . | sort -hr


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

Copy PART of a text file into a new file (useful when analyzing large logfiles):

```sh
# Copy just line numbers 1001 through 2000 into latest.log
sed -n '1001,2000' dev.log > latest.log
```


## Background processes

- `w` - list all current sessions to this machine, and what they're running
- `last` - list all *recent* sessions on this machine
- `ps aux` - list all running processes
- `nohup [bash command]` # ensure the command doesn't die when your SSH connection ends


## Looping

Infinite loop:

    while : ; do echo "Hi there!"; sleep 1; done

Run a command for each line in a file:

    cat lines.txt | while read line; do echo "This line is: $line"; done


## Downloads

- `wget -c <url>` - download a resource, resuming from partial progress if interrupted
