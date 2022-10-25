# Papertrail (log aggregator)

https://github.com/papertrail/papertrail-cli#quick-start
https://www.papertrail.com/help/command-line-client/


## How to download, combine, search, and parse archived logs

```sh
# 1. Download a whole daterange of per-hour log archives at once:
# https://www.papertrail.com/help/permanent-log-archives/#downloading-multiple-archives
curl -sH 'X-Papertrail-Token: MY_API_TOKEN' https://papertrailapp.com/api/v1/archives.json \
  | grep -o '"filename":"[^"]*"' \
  | egrep -o '[0-9-]+' \
  | awk '$0 >= "2022-02-01" && $0 < "2022-03-31" {
    print "output " $0 ".tsv.gz"
    print "url https://papertrailapp.com/api/v1/archives/" $0 "/download"
  }' \
  | curl --progress-bar -fLH 'X-Papertrail-Token: MY_API_TOKEN' -K-

# 2. Untar each archive file, combine them into one master .tsv, then clean out chaff entries:
sh ~/Sites/personal/utilities/combine_pt_logs.sh
less combined.tsv # the combined version, not yet cleaned
less cleaned.tsv # the cleaned version

# 3. Search for a specific pattern, then cut each line to return only certain fields:
# (in this case, filter to HTTP requests by a specific logged-in user, then discard all
# data except for each row's timestamp, IP, and request method & path)
cat cleaned.tsv | grep ■ | grep "user=14 " | cut -d '	' -f 2,6,10 \
	| sed -E $'s#params=.+##'
```
