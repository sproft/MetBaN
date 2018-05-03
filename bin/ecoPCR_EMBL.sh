#!/bin/bash -e

# Author: Sebastian Proft
# Author: Jose Grau - Jose.Grau@mfn-berlin.de

# TODO: make nicer

VERSION=0.0.1

usage(){
cat <<EOF
Usage:
  ecoPCR_EMBL FORWARD_PRIMER REVERSE_PRIMER
Generate reference database for the identification using ecoPCR
  -i   list of taxids (mandatory)
  -d   path to converted EMBL database (mandatory)
  -a   path to optional annotated database for species identification
  -e   number of allowed errors [$ERRORS]
  -o   output directory [$OUT]
  -l   lower read length cutoff [$LLENGTH]
  -L   uper read length cutoff [$ULENGTH]
  -V   show script version
  -h   show this help
EOF
exit 0; }


#get absolute path from relative
get_abs_filename() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

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


# Execute getopt and check opts/args
ARGS=`getopt -n "$SCR" -o "d:a:e:i:o:l:L:hV" -- "$@"`
[ $? -ne 0 ] && exit 1; # Bad arguments
eval set -- "$ARGS"

OUT='ecoPCR_database'`date +%F`
LLENGTH=100
ULENGTH=1000
ERRORS=3

while true; do
    case "$1" in
        -i) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); TAXIDS="$2"; shift 2;;
        -e) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); ERRORS="$2"; shift 2;;
        -o) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); OUT="$2"; shift 2;;
        -l) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); LLENGTH="$2"; shift 2;;
        -L) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); ULENGTH="$2"; shift 2;;
        -d) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); DATABASE="$2"; shift 2;;
        -a) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); ANNOT="$2"; shift 2;;
        #-z) GZIP=1; shift 1;;
        -h) usage && exit 0;;
        -V) echo $VERSION && exit 0;;
        --) shift; break;;
    esac
done;


#check for forward and reverse read
if [[ $# -ne 2 ]] ; then
    echo 'arguments: FORWARD_PRIMER REVERSE_PRIMER'
    exit 1
fi


#check for mandatory options
if ! [[ -v TAXIDS ]]
then
    echo "a list of taxids has to be specified" >&2
    exit 1
fi

if ! [[ -v DATABASE ]]
then
    echo "a converted EMBL database has to be specified" >&2
    exit 1
fi

if ! [[ -d $(get_abs_filename $DATABASE ) ]]
then
    echo "the EMBL database directory does not exist" >&2
    exit 1
fi

if ! [[ -d $(get_abs_filename $ANNOT) ]] && [[ -v ANNOT ]]
then
echo "the annotated database directory does not exist" >&2
exit 1
fi


# check binaries
PATH=$UDIR/mafft/bin:$UDIR/tcoffee/compile:$UDIR/standard-RAxML:$UDIR/anaconda_ete/bin:$UDIR/OBITools/bin:$PATH;
for bin in obigrep obiuniq obiannotate ecoPCR python perl; do
    check_bin $bin;
done;




hostname
date

if [[ -v ANNOT ]]
then
ANNOT=$(get_abs_filename $ANNOT )
fi

DATABASE=$(get_abs_filename $DATABASE )
mkdir -p $OUT
cd $OUT

##############CREATING NGSFILTER############
printf "#               sample          tags    forwardprimer           reverseprimer\n" > ngsfilter.txt
printf "lakesample      div4    n:n       ${1}   ${2}  F       @\n" >> ngsfilter.txt
printf "lakesample      div4    a:a       ${1}   ${2}  F       @\n" >> ngsfilter.txt
printf "lakesample      div4    c:c       ${1}   ${2}  F       @\n" >> ngsfilter.txt
printf "lakesample      div4    g:g       ${1}   ${2}  F       @\n" >> ngsfilter.txt
printf "lakesample      div4    t:t       ${1}   ${2}  F       @" >> ngsfilter.txt
################DO NOT CHANGE##############

echo $TAXIDS > taxids

ecoPCR -d ${DATABASE}/embl_last -e $ERRORS -l $LLENGTH -L $ULENGTH $1 $2 >DIV4.ecoPCR

obigrep -d ${DATABASE}/embl_last --require-rank=genus --require-rank=family --require-rank=species DIV4.ecoPCR >DIV4.ecopcr

obiuniq -d ${DATABASE}/embl_last DIV4.ecopcr >DIV4.ecopcr.uniq

obigrep -d ${DATABASE}/embl_last --require-rank=family DIV4.ecopcr.uniq >DIV4.ecopcr.uniq.clean

obiannotate --uniq-id DIV4.ecopcr.uniq.clean >DIV4.ecopcr.uniq.clean.annot

cat DIV4.ecopcr.uniq.clean.annot | perl -ne 'if ($_ =~ m/species\=(\d+)/smg) {print "amplicon\t$1\n"}' | sort | uniq >DIV4.ecopcr.uniq.clean.annot.species.list

obigrep -v -a "genus_name:###" DIV4.ecopcr.uniq.clean.annot > DIV4.fasta

if [[ -v ANNOT ]]
then
cp DIV4.fasta DIV4.noANNOT.fasta
cat DIV4.noANNOT.fasta $ANNOT > DIV4.fasta
fi 

for i in $TAXIDS
do
obigrep -r $i -d ${DATABASE}/embl_last DIV4.fasta >DIV4.fasta.${i}
done
date

#clean the header
for i in $TAXIDS
do
obiannotate -k scientific_name -k count -k family_name DIV4.fasta.${i} > DIV4.ann.fasta.${i}
done
date

#prepare header for tree
for i in $TAXIDS
do
cat DIV4.ann.fasta.${i} | perl -pe 's/; count=/; REFERENCE; count=/g' > DIV4.final.fasta.${i}
done
date
