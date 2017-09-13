#!/bin/bash -e

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
