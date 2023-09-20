# Stop on first error
set -e;
# Used for Bigquery partitioning (to distinguish from bash variable reference)
DOLLAR="\$"
# -I ISO DATE
# -d FROM STRING
start=$(date -I -d 2021-05-01) || exit -1
end=$(date -I -d 2021-06-30)   || exit -1
d=${start}
mkdir "temp"
cd "temp"
# string(d) <= string(end)
while [[ ! "$d" > "$end" ]]; do
    YYYYMMDD=$(date -d ${d} +"%Y%m%d")
    YYYY=$(date -d ${d} +"%Y")
    MM=$(date -d ${d} +"%m")
    DD=$(date -d ${d} +"%d")
    # print current date
    echo ${d}
    cmd_tender="gsutil -m cp -r gs://bridg_file_transfer_temp/${d}/ .
    "
    echo $cmd_tender
    eval ${cmd_tender}
    tar -cvzf $d.tar.gz $d/*.csv
    yes | gpg --always-trust --encrypt -r "BridgImpl (homedepotkey) <bridg.implementation@bridg.com>" $d.tar.gz 
    rm -rf $d
    rm -rf $d.tar.gz
    # d++
    d=$(date -I -d "$d + 1 day")
done
download_customers="gsutil -m cp -r gs://bridg_file_transfer_temp/customers/ .
    "
echo $download_customers
eval ${download_customers}
tar -cvzf customers.tar.gz customers/*.csv
yes | gpg --always-trust --encrypt -r "BridgImpl (homedepotkey) <bridg.implementation@bridg.com>" customers.tar.gz 
rm -rf customers
rm -rf customers.tar.gz
# location_dimension="gsutil -m cp -r gs://bridg_file_transfer_temp/location_dimension/ .
#     "
# echo $location_dimension
# eval ${location_dimension}
# tar -cvzf location_dimension.tar.gz location_dimension/*.csv
# yes | gpg --always-trust --encrypt -r "BridgImpl (homedepotkey) <bridg.implementation@bridg.com>" location_dimension.tar.gz 
# rm -rf location_dimension
# rm -rf location_dimension.tar.gz
