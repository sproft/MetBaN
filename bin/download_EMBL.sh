#!/bin/bash -e

UDIR=$DIR/../util/
LDIR=$DIR/../lib/

# check binaries
PATH=$UDIR/mafft/scripts:$UDIR/tcoffee/compile:$UDIR/standard-RAxML:$UDIR/anaconda_ete/bin:$UDIR/OBITools/bin:$PATH;
for bin in obiconvert; do
    check_bin $bin;
done;

mkdir -p embl_last
cd embl_last

#Download EMBL
mkdir -p EMBL
cd EMBL
wget -nH --cut-dirs=5 -A rel_std_\*.dat.gz -m ftp://ftp.ebi.ac.uk/pub/databases/embl/release/std/
gunzip *.dat.gz
cd ..


#Download the taxonomy
mkdir -p TAXO
cd TAXO
wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
tar -zxvf taxdump.tar.gz
cd ..


#Format the data
obiconvert --skip-on-error --embl -t ./TAXO --ecopcrdb-output=embl_last ./EMBL/*.dat
