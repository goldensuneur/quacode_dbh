#!/bin/bash

function ProgressBar {
# Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
# Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:
# 1.2.1.1 Progress : [########################################] 100%
printf "\rRunning ${2} instances : [${_fill// /#}${_empty// /-}] ${_progress}%%"

}

let max=100


echo "propagator;branchers;runtime;solutions;propagations;nodes;failures;restarts;no-goods;peak depth" > results_gen.txt

for (( i = 0; i < $max; i++ )); do
    ProgressBar ${i} ${max}
    ../baker | cut -d ':' -f 2 | grep -i "[0-9]" | sed -e 's/^ *\([0-9.]\+\).*/\1;/' | tr -d '\n' >> results_gen.txt && echo "" >> results_gen.txt
done
echo -ne "\nDone !\n"
./compute_results.py results_gen.txt
