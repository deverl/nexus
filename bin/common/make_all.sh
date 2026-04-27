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
            HAS_INSTALL=$(grep "^install" makefile)
            if [ "$HAS_INSTALL" != "" ]
            then
                print_cyan "--- make clean install"
                make clean install
            else
                print_cyan "--- make clean all"
                make clean all
            fi
            make clean
        else
            print_bright_yellow "No makefile"
        fi
        cd ..
    fi
done

echo ""
