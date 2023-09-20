# Stop on first error
set -e;
​
# Used for Bigquery partitioning (to distinguish from bash variable reference)
DOLLAR="\$"
​
# -I ISO DATE
# -d FROM STRING
start=$(gdate -I -d 2021-05-01) || exit -1
end=$(gdate -I -d 2021-05-31)   || exit -1
​
d=${start}
cd "temp"
​
# string(d) <= string(end)
while [[ ! "$d" > "$end" ]]; do
    YYYYMMDD=$(gdate -d ${d} +"%Y%m%d")
    YYYY=$(gdate -d ${d} +"%Y")
    MM=$(gdate -d ${d} +"%m")
    DD=$(gdate -d ${d} +"%d")
​
    # print current date
    echo ${d}
​
    cmd_tender="gsutil -m cp -r gs://bridg_file_transfer_temp/${d}/ .
    "
    echo $cmd_tender
    eval ${cmd_tender}
    tar -cvzf $d.tar.gz $d/*.csv
    yes | gpg --always-trust --encrypt -r "BridgImpl (homedepotkey) <bridg.implementation@bridg.com>" $d.tar.gz 
    rm -rf $d
    rm -rf $d.tar.gz
    # d++
    d=$(gdate -I -d "$d + 1 day")
done
