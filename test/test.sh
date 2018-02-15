#!/bin/bash -e

if ! [[ -f ./embl_last/embl_last.ndx ]]
then
tar -xvzf test.tar.gz
fi

if [[ -f ./embl_last/embl_last.ndx ]]
then
../bin/MetBaN.sh ./data/1_S1_L001_R1_001.fastq ./data/1_S1_L001_R2_001.fastq -i "33836 33849 33853" -g ./data/Bolidomonas_outgroup.fas -r ecoPCR_database -d embl_last/ -o results_test -b 2
else
echo "test failed, try extracting tar-file manually"
exit 1
fi

if [[ -f ./results_test/pdfs/RAxML_bipartitions.33849.raxml.pdf ]]
then
echo "test succesfull, you are good to go :)"
exit 0
else
echo "test failed, try reinstalling MetBaN"
exit 1
fi
