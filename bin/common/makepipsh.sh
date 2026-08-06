#!/usr/bin/env bash

echo "#!/usr/bin/env bash" > pip.sh
echo "" >> pip.sh
echo -n "pip install " >> pip.sh
pip list | awk 'NR>2 {print $1}' | tr '\n' ' ' >> pip.sh
echo "" >> pip.sh
echo "" >> pip.sh


chmod a+x pip.sh

