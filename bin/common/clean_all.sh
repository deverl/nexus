 #!/bin/bash

source ~/nexus/bin/common/ansi

for D in *
do
    if [ -d $D ]
    then
        cd $D
        echo ""
        print_bright_green $D
        if [ -f makefile ]
        then
            print_cyan "--- make clean"
            make clean
        else
            print_bright_yellow "No makefile"
        fi
        cd ..
    fi
done

echo ""
