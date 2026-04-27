#!/usr/bin/env bash
#
# This script will delete all but a certain number (numToKeep) of files
# matching a certain pattern (thePattern).
#
# The files are sorted according to age (oldest first), then all but the
# most recent numToKeep files are deleted.
#


# Get the full path to the script directory.
# The user may choose to execute the script in this directory by specifying
# the -s command line option.

typeset -r fullScriptPath=$(realpath $0)
typeset -r fullScriptDir=$(dirname "${fullScriptPath}")

theDir=$(realpath $(pwd))

# The default number of matching files to keep.

typeset -i DEFAULT_NUM_TO_KEEP=4
typeset -i numToKeep=${DEFAULT_NUM_TO_KEEP}

# This is the pattern we are searching for.

typeset -r DEFAULT_PATTERN='*.sql'
thePattern=${DEFAULT_PATTERN}

typeset -i verbose=0
typeset -i dryRun=0


# Process any command line arguments.

while [ $# -gt 0 ]
do
    if [ $1 == "-d" ]
    then
        shift
        if [ $# -gt 0 ]
        then
            if [ -d $1 ]
            then
                theDir=$1
            else
                echo "ERROR: $1 is not a directory!"
                exit 1
            fi
        else
            echo "ERROR: No value given for the -d option!"
            exit 1
        fi
    elif [ $1 == "-n" ]
    then
        shift
        if [ $# -gt 0 ]
        then
            if [[ $1 =~ ^-?[0-9]+$ ]]
            then
                numToKeep=$1
            else
                echo "ERROR: $1 (given for -n) is not a numeric value"
                exit 1
            fi
        else
            echo "ERROR: No value given for the -n option!"
            exit 1
        fi
    elif [ $1 == "-p" ]
    then
        shift
        if [ $# -gt 0 ]
        then
            thePattern=$1
        else
            echo "ERROR: No value given for the -p option!"
            exit 1
        fi
    elif [ $1 == "-s" -o $1 == "--use-scriptdir" ]
    then
        theDir="${fullScriptDir}"
    elif [ $1 == "-v" ]
    then
        verbose=1
    elif [ $1 == "-x" -o $1 == "--dry-run" ]
    then
        verbose=1
        dryRun=1
    elif [ $1 == "-h" -o $1 == "--help" ]
    then
        echo ""
        echo "usage: cleanup.sh [opts]"
        echo ""
        echo "  opts: -d <dir>        Execute the script in <dir>."
        echo "        -n <num>        Keep <num> of the newest matching files."
        echo "        -p '<pat>'      Use <pat> as the file matching pattern."
        echo "        -s              Execute the script in the script directory."
        echo "        -v              Turn on verbose output."
        echo "        -x              Do a dry run only."
        echo "        -h, --help      Print this screen and exit."
        echo ""
        echo " Notes: 1. The default number to keep is ${DEFAULT_NUM_TO_KEEP}"
        echo "        2. The script directory is: \"${fullScriptDir}\"."
        echo "        3. The default matching pattern is: '${DEFAULT_PATTERN}'."
        echo "        4. Be sure to use single quotes around <pat>."
        echo "        5. A dry run just prints out what would be done without"
        echo "           actually doing anything."
        echo ""
        exit 1
    else
        echo "Unrecognized command line option: $1"
        exit 1
    fi

    shift
done

if [ ${verbose} -gt 0 ]
then
    echo "theDir = ${theDir}"
    echo "numToKeep = ${numToKeep}"
    echo "thePattern = ${thePattern}"
fi


# Make sure we are operating in the theDir directory.

cd "${theDir}"

if [ ${verbose} -gt 0 ]
then
    echo "Executing in directory: $(pwd)"
fi


# This puts all of the matching files into an array named theFiles.

theFiles=($(ls -t -r ${thePattern}))

# This gets the number of entries in the array and puts it into totalFiles.

totalFiles=${#theFiles[@]}

# Just print out the total number of matching files.

if [ ${verbose} -gt 0 ]
then
    echo "totalFiles = ${totalFiles}"
fi

# Check to see if we have more than numToKeep files.

if [ ${totalFiles} -gt ${numToKeep} ]
then
    # We do have more than numToKeep files.

    # Calculate the number of files to delete and put it into numToDelete.
    let numToDelete=${totalFiles}-${numToKeep}
    let i=0
    if [ ${verbose} -gt 0 ]
    then
        # Print out the number of files we are going to delete.
        echo "numToDelete = ${numToDelete}"
    fi
    # Loop through the first numToDelete file names from the theFiles
    # array and remove them.
    while [ $i -lt ${numToDelete} ]
    do
        # Gets the i'th value of the theFiles array.
        fname=${theFiles[${i}]}
        if [ ${verbose} -gt 0 ]
        then
            echo "Removing ${fname}"
        fi
        if [ ${dryRun} -eq 0 ]
        then
            rm -f ${fname}
        fi
        let i=${i}+1
    done
else
    # We DO NOT have more than numToKeep files.
    if [ ${verbose} -gt 0 ]
    then
        echo "No files need to be deleted."
    fi
fi

