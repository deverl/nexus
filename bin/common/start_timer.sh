#!/usr/bin/env bash

typeset -i i=1

trap ctrl_c INT

function ctrl_c() {
    echo -n -e $(tput hpa 0)$(tput el)$(tput cnorm)
    # echo ""
    echo "Final time: $i"
    echo ""
    exit 1
}

echo -n -e $(tput civis)

echo ""
echo ""
echo -n -e $(tput cuu1)

while [ 1 -eq 1 ]
do
    sleep 1

    echo -n " ${i}$(tput cr)"

    let i=$i+1
done

