#!/usr/bin/env bash

theUsers=$(p4 users | grep -v MKDUM | awk '{ print $1 }')

typeset -i c=0
typeset -i tot=0

# set -x

function println {
    S="$1"
    while [ ${#S} -lt 20 ]
    do
        S=" $S"
    done
    S2="$2"
    while [ ${#S2} -lt 5 ]
    do
        S2=" $S2"
    done
    echo "${S} : ${S2}"
}


for U in $theUsers
do
    F=/tmp/${U}.txt

    p4 opened -u ${U} > ${F} 2>/dev/null

    c=$(wc -l ${F} | awk '{print $1}')

    let tot=${tot}+${c}

    if [ ${c} -gt 0 ]
    then
        println $U $c
    else
        rm -f ${F}
    fi
done

echo "----------------------------"

println "Total" ${tot}

