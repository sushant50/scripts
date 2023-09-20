# Stop on first error
set -e;

# Used for Bigquery partitioning (to distinguish from bash variable reference)
DOLLAR="\$"

# -I ISO DATE
# -d FROM STRING
start=$(gdate -I -d 2021-06-01) || exit -1
end=$(gdate -I -d 2021-06-30)   || exit -1

d=${start}

# string(d) <= string(end)
while [[ ! "$d" > "$end" ]]; do
    YYYYMMDD=$(gdate -d ${d} +"%Y%m%d")
    YYYY=$(gdate -d ${d} +"%Y")
    MM=$(gdate -d ${d} +"%m")
    DD=$(gdate -d ${d} +"%d")

    # print current date
    echo ${d}

    cmd_tender="bq extract  \
    'hd-mkt-data-platform-dev:sushant.tender_june${DOLLAR}${YYYYMMDD}' \
    'gs://bridg_file_transfer_temp/${d}/tender_${d}-*.csv'
    "

    cmd_transaction_summary="bq extract  \
    'hd-mkt-data-platform-dev:sushant.transaction_summary_june${DOLLAR}${YYYYMMDD}' \
    'gs://bridg_file_transfer_temp/${d}/transaction_summary_${d}-*.csv'
    "

    echo $cmd_tender
    eval ${cmd_tender}
    echo $cmd_transaction_summary
    eval ${cmd_transaction_summary}

    # d++
    d=$(gdate -I -d "$d + 1 day")
done
