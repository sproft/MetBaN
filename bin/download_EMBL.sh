#!/bin/bash -e

SCR=`basename $0`;
# rel dir
# DIR=`dirname $(readlink $0 || echo $0)`;
# abs dir
# # get absolute dir
pushd . > /dev/null
DIR="${BASH_SOURCE[0]}"
while [ -h "$DIR" ]; do
cd "$(dirname "$DIR")"
DIR="$(readlink "$(basename "$DIR")")"
done
cd "$(dirname "$DIR")"
DIR="$(pwd)/"
popd > /dev/null

UDIR=$DIR/../util/
LDIR=$DIR/../lib/

log(){
echo [$(date +"%T")] $@ >&2
}
logs(){
echo -n [$(date +"%T")] $@ >&2
}
loge(){
echo " "$@ >&2
}

check_bin(){
logs $1 ..
if [[ $1 == */* ]]; then
[ -x $1 ] || { loge failed; log "$1 not found or executable"; exit 1; }
else
hash $1 || { loge failed; log "$1 required in PATH"; exit 1; }
fi;
loge ok
}



# check binaries
PATH=$UDIR/mafft/bin:$UDIR/tcoffee/compile:$UDIR/standard-RAxML:$UDIR/anaconda_ete/bin:$UDIR/OBITools/bin:$PATH;
for bin in obiconvert gunzip; do
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
