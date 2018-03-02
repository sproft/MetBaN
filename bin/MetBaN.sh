#!/bin/bash -e

# Author: Sebastian Proft
# Author: Jose Grau - Jose.Grau@mfn-berlin.de

# TODO: make nicer

VERSION=0.0.1

usage(){
cat <<EOF
Usage:
obiall FORWARD_READ.fq REVERSE_READ.fq
Generate identification and phylogenetic tress for
environmental reads
-i   list of taxids (mandatory)
-g   path to the fasta that contains a single outgroup sequence (mandatory)
-d   path to EMBL database directory (mandatory)
-r   path to reference database directory (mandatory)
-a   annotated sequences for the tree building
-o   output directory [$OUT]
-m   match cutoff [$MATCH]
-t   number of threads / parallel processes [$THREADS]
-l   read length cutoff [$LENGTH]
-b   number of bootstrap runs in the tree building process [$BOOT]
-P   run pipeline with already paired reads
-D   delete intermediate files
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
ARGS=`getopt -n "$SCR" -o "t:a:g:i:o:l:m:d:r:b:PDhV" -- "$@"`
[ $? -ne 0 ] && exit 1; # Bad arguments
eval set -- "$ARGS"

THREADS=2
OUT='phylogenetic-trees'`date +%F`
LENGTH=150
MATCH=0.9
DELETE=0
PAIRED=0
BOOT=100

while true; do
case "$1" in
-i) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); TAXIDS="$2"; shift 2;;
-t) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); THREADS="$2"; shift 2;;
-o) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); OUT="$2"; shift 2;;
-l) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); LENGTH="$2"; shift 2;;
-m) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); MATCH="$2"; shift 2;;
-g) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); OUTGROUP="$2"; shift 2;;
-b) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); BOOT="$2"; shift 2;;
-d) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); DATABASE="$2"; shift 2;;
-r) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); REFERENCE="$2"; shift 2;;
-a) [ ! -n "$2" ] && (echo "$1: value required" 1>&2 && exit 1); ANNOT="$2"; shift 2;;
#-z) GZIP=1; shift 1;;
-D) DELETE=1; shift 1;;
-P) PAIRED=1; shift 1;;
-h) usage && exit 0;;
-V) echo $VERSION && exit 0;;
--) shift; break;;
esac
done;

#check for forward and reverse read
if [ $PAIRED -eq 0 ] ; then
   if [[ $# -ne 2 ]] ; then
      echo "arguments: FORWARD_READS REVERSE_READS"
      exit 1
   elif [[ ! -s $(get_abs_filename $1 ) ]] || [[ ! -s $(get_abs_filename $2 ) ]] ; then
      echo "one of your read-files is empty"
      exit 1
   fi
else
   if [[ $# -ne 1 ]] ; then
      echo "arguments: PAIRED_READS"
      exit 1
   elif [[ ! -s $(get_abs_filename $1 ) ]] ; then
      echo "your paired readfile is empty"
      exit 1
   fi
fi

#check for mandatory options
if ! [[ -v TAXIDS ]]
then
echo "a list of taxids has to be specified" >&2
exit 1
fi

if ! [[ -v OUTGROUP ]]
then
echo "an outgroup has to be specified" >&2
exit 1 
fi

if ! [[ -f $(get_abs_filename $OUTGROUP ) ]]
then
echo "the outgroup file does not exist" >&2
exit 1
fi

if ! [[ -v REFERENCE ]]
then
echo "a reference file has to be specified" >&2
exit 1
fi

if ! [[ -d $(get_abs_filename $REFERENCE ) ]]
then
echo "the reference directory does not exist" >&2
exit 1
fi

if ! [[ -v DATABASE ]]
then
echo "a database directory has to be specified" >&2
exit 1
fi

if ! [[ -d $(get_abs_filename $DATABASE ) ]]
then
echo "the database directory does not exist" >&2
exit 1
fi

if ! [[ -d $(get_abs_filename $ANNOT) ]] && [[ -v ANNOT ]]
then
echo "the annotated database directory does not exist" >&2
exit 1
fi

if [[ -d $(get_abs_filename $OUT) ]]
then
echo "the output directory already exists, please specify a new one or delete the old one" >&2
exit 1
fi


for i in $TAXIDS
do
if ! [[ -f $(get_abs_filename $REFERENCE)/DIV4.final.fasta.${i} ]]
then
echo "there exists no reference file for the taxid: ${i}, please refer to the ecoPCR script" >&2
exit 1
fi
done


# check binaries
PATH=$UDIR/mafft/bin:$UDIR/tcoffee/compile:$UDIR/standard-RAxML:$UDIR/anaconda_ete/bin:$UDIR/OBITools/bin:$PATH;
for bin in illuminapairedend obigrep obihead ngsfilter obiuniq obiannotate obistat obiclean ecotag mafft t_coffee raxmlHPC-AVX2 python; do
    check_bin $bin;
done;

#[ $GZIP -gt 0 ] && check_bin gzip;

# output
#mkdir $OUT

hostname
date

DATABASE=$(get_abs_filename $DATABASE )
REFERENCE=$(get_abs_filename $REFERENCE )
OUTGROUP=$(get_abs_filename $OUTGROUP )
OUT=$(get_abs_filename $OUT )

if [[ -v ANNOT ]]
then
ANNOT=$(get_abs_filename $ANNOT )
fi

rm -f -r $OUT/FILES
mkdir -p $OUT/FILES
mkdir -p $OUT/FILES/LOGS
#LOG=$(get_abs_filename $OUT/FILES/LOGS )
LOG=$OUT/FILES/LOGS


##############PREPARING THE FILES


if [ $PAIRED -eq 0 ];then
  fileF="$1"
  fileR="$2"

  echo pairing...
  #pair the forward and backward read
  #illuminapairedend --without-progress-bar --score-min=40 -r $(get_abs_filename $fileR ) $(get_abs_filename $fileF ) > $OUT/FILES/paired.fastq
  #date

  rm -rf $OUT/FILES/paired_temp
  mkdir -p $OUT/FILES/paired_temp
  cat $(get_abs_filename $fileF ) | split - -l 8000 $OUT/FILES/paired_temp/R1
  cat $(get_abs_filename $fileR ) | split - -l 8000 $OUT/FILES/paired_temp/R2
  cd $OUT/FILES/paired_temp
  paste <(ls ./R1*) <(ls ./R2*) > files
  while read -r F R
  do 
  illuminapairedend --without-progress-bar --score-min=40 $F -r $R 1> $F.paired 2> $F.log & 
  done < files
  wait
  cd ../
  cat paired_temp/*paired > paired.fastq 
  rm -rf paired_temp
  date

  echo filtering...
  #filter out the ones that dont have an alignment
  obigrep --without-progress-bar -p 'mode!="joined"' paired.fastq > paired.ali.fastq 2>$LOG/grep.log
  date

  #demultiplexing
  echo demultiplexing...
  ngsfilter --without-progress-bar -t ${REFERENCE}/ngsfilter.txt -u unidentified.paired.fastq paired.ali.fastq > paired.ali.assigned.fastq 2>$LOG/ngsfilter.log
  date

else
  fileP="$1"
  cd $OUT/FILES
  
  #demultiplexing
  echo demultiplexing...
  ngsfilter --without-progress-bar -t ${REFERENCE}/ngsfilter.txt -u unidentified.paired.fastq $fileP > paired.ali.assigned.fastq 2>$LOG/ngsfilter.log
  date
fi

#echo checking...
#check progress
#obihead --without-progress-bar --without-progress-bar -n 1 paired.ali.fastq
#date

echo merging...
#merge identical sequences
obiuniq --without-progress-bar -m sample -i paired.ali.assigned.fastq > paired.ali.assigned.uniq.fasta 2>$LOG/uniq.log
date

echo cleaning...
#clean the header
obiannotate --without-progress-bar -k count -k merged_sample paired.ali.assigned.uniq.fasta > paired.ali.assigned.uniq.ann.fasta 2>$LOG/annotate.log
date

echo checking...
#check the number of reads
obistat --without-progress-bar -c count paired.ali.assigned.uniq.ann.fasta | sort -nk1 | head -20 > stat.paired.out 2>$LOG/stat.log
date

echo filtering...
#filter useless reads
obigrep --without-progress-bar -l $LENGTH -p 'count>=2' paired.ali.assigned.uniq.ann.fasta > paired.ali.assigned.uniq.ann.fil.fasta 2>$LOG/grep2.log
date

echo "finding head reads..."
#find the head reads
obiclean --without-progress-bar -s merged_sample -r 0.05 -H paired.ali.assigned.uniq.ann.fil.fasta > paired.ali.assigned.uniq.ann.fil.clean.fasta 2>$LOG/clean.log
date

#############CLASSIFYING

mkdir -p RESULTS

echo identifying...
#identify sequences
ecotag --without-progress-bar -m $MATCH -d ${DATABASE}/embl_last -R ${REFERENCE}/DIV4.fasta paired.ali.assigned.uniq.ann.fil.clean.fasta > RESULTS/paired.ali.assigned.uniq.ann.fil.clean.tag.fasta 2>$LOG/ecotag.log
date

cd RESULTS

echo cleaning...
#clean the header
obiannotate --without-progress-bar --delete-tag=scientific_name_by_db --delete-tag=obiclean_samplecount --delete-tag=obiclean_count --delete-tag=obiclean_singletoncount --delete-tag=obiclean_internalcount --delete-tag=obiclean_head --delete-tag=taxid_by_db --delete-tag=obiclean_headcount --delete-tag=id_status --delete-tag=rank_by_db --delete-tag=order_name --delete-tag=order paired.ali.assigned.uniq.ann.fil.clean.tag.fasta > paired.ali.assigned.uniq.ann.fil.clean.tag.ann.fasta 2>$LOG/annotate2.log
date

echo sorting...
#sort the results by decreasing order of count
obisort --without-progress-bar -k count -r paired.ali.assigned.uniq.ann.fil.clean.tag.ann.fasta > paired.ali.assigned.uniq.ann.fil.clean.tag.ann.sort.fasta 2>$LOG/sort.log
date

echo exceling...
#final excel result
obitab --without-progress-bar -o paired.ali.assigned.uniq.ann.fil.clean.tag.ann.sort.fasta > paired.ali.assigned.uniq.ann.fil.clean.tag.ann.sort.tab 2>$LOG/tab.log
date

#############SPLIT BASED ON FAMILIES
echo splitting...

for i in $TAXIDS
do
obigrep --without-progress-bar -r $i -d ${DATABASE}/embl_last paired.ali.assigned.uniq.ann.fil.clean.tag.ann.sort.fasta > env.${i}.fasta 2>$LOG/$i.split.log &
done 
wait

cp paired.ali.assigned.uniq.ann.fil.clean.tag.ann.sort.fasta ./env.fasta
date

#clean header again after splitting
echo cleaning...
for i in $TAXIDS
do
obiannotate --without-progress-bar -k count -k family_name -k scientific_name env.${i}.fasta > env.${i}.ann.fasta 2>$LOG/$i.annotate.log &
done
wait
date

mkdir -p TREE

#merge with reference data
echo merging...
if [[ -v ANNOT ]]
then
  for i in $TAXIDS
  do
  cat env.${i}.ann.fasta ${REFERENCE}/DIV4.final.fasta.${i} ${ANNOT}/*.${i} > ./TREE/${i}.fasta 2>$LOG/$i.concat.log &
  done
  wait
else
  for i in $TAXIDS
  do
  cat env.${i}.ann.fasta ${REFERENCE}/DIV4.final.fasta.${i} > ./TREE/${i}.fasta 2>$LOG/$i.concat.log &
  done
  wait
fi
date

cd TREE

###########################ADD OUTGROUP

echo adding outgroup...
for i in $TAXIDS
do
if [ -s "../env.${i}.ann.fasta" ]
then
cat $OUTGROUP ${i}.fasta > ${i}.fasta.outgroup 2>$LOG/$i.addoutgroup.log
fi
done
wait
date

###########################BUILDING TREE

#MAFFT Alignment
echo aligning...
for i in $TAXIDS
do
if [ -e "${i}.fasta.outgroup" ]
then
mafft --quiet --thread $THREADS --adjustdirectionaccurately ${i}.fasta.outgroup > ${i}.mafft 2>$LOG/$i.mafft.log &
fi
done
wait
date

#T-Coffee
echo "drinking coffee..."
for i in $TAXIDS
do
if [ -e "${i}.mafft" ]
then
t_coffee -other_pg seq_reformat -in ${i}.mafft -out ${i}.mafft.coffee -action +rm_gap 75 2>$LOG/$i.t_coffee.log &
fi
done
wait
date

#########CREATE TRANS : DO NOT CHANGE ANYTHING!############
echo '################CONVERT SEQ NAMES
import pickle,sys

d = dict()
f=open(sys.argv[1],"r")
i=1
for l in f:
    if l.startswith(">"):
        d["Seq"+str(i)]=l[1:]
        print ">Seq"+str(i)
        i=i+1
    else:
        print l


# Store data (serialize)
with open(sys.argv[1]+".dict.pkl", "wb") as handle:
    pickle.dump(d, handle, protocol=pickle.HIGHEST_PROTOCOL)' > seq2id.py
#############################################################################
chmod +x seq2id.py


#CONVERT TO FASTA
echo converting...
for i in $TAXIDS
do
if [ -e "${i}.mafft.coffee" ]
then
python seq2id.py ${i}.mafft.coffee > ${i}.mafft.coffee.fasta 2>$LOG/$i.convert.log &
fi
done
wait
date

#RAXML BUILD THE TREE
echo raxmling...
for i in $TAXIDS
do
if [ -e "${i}.mafft.coffee.fasta" ]
then
raxmlHPC-PTHREADS -T $THREADS -o Seq1 -f a -x 12354 -p 12354 -c 8 -# $BOOT -m GTRCAT -s ${i}.mafft.coffee.fasta -n ${i}.raxml 2>$LOG/$i.raxml.log &
fi
done
wait
date

mkdir -p pdfs
mkdir -p nwk
mkdir -p tables

###########CREATE TREE2PDF : DO NOT CHANGE###############
echo '# -*- coding: utf-8 -*-
"""
Created on Wed Feb 24 15:59:18 2016

@author: sebas
"""


##########################The following code was taken from https://github.com/linsalrob/EdwardsLab/blob/master/trees/tree_to_cophenetic_matrix.py
import os
import sys
import argparse
from itertools import combinations
from ete3 import Tree


def make_matrix(treefile):
    """
    Create a matrix from a tree file
    :param treefile:
    :return:
    """

    tree = treefile

    leaves = tree.get_leaves()
    paths = {x:set() for x in leaves}

    # get the paths going up the tree
    # we get all the nodes up to the last one and store them in a set
    #sys.stderr.write("Precalculating distances\n")
    for n in leaves:
        if n.is_root():
            continue
        movingnode = n
        while not movingnode.is_root():
            paths[n].add(movingnode)
            movingnode = movingnode.up

    # now we want to get all pairs of nodes using itertools combinations. We need AB AC etc but dont need BA CA

    leaf_distances = {x.name:{} for x in leaves}

    #sys.stderr.write("Iterating over the leaves\n")
    for (leaf1, leaf2) in combinations(leaves, 2):
        # figure out the unique nodes in the path
        uniquenodes = paths[leaf1] ^ paths[leaf2]
        distance = sum(x.dist for x in uniquenodes)
        leaf_distances[leaf1.name][leaf2.name] = leaf_distances[leaf2.name][leaf1.name] = distance

    return leaf_distances
#####################################################################################################################


import pickle,sys
from ete3 import Tree, NodeStyle, TreeStyle, faces, AttrFace, CircleFace, TextFace

# Basic tree style
ts = TreeStyle()
ts.show_leaf_name = True
ts.scale = 20
ts.show_branch_support = True

#set node style
nstyleR = NodeStyle()
nstyleR["bgcolor"] = "red"

#set node style
nstyleY = NodeStyle()
nstyleY["bgcolor"] = "yellow"

#set node style
nstyleG = NodeStyle()
nstyleG["bgcolor"] = "green"

#set node style
nstyleP = NodeStyle()
nstyleP["bgcolor"] = "pink"


t = Tree(sys.argv[1])
d = pickle.load(open( sys.argv[2], "rb"))
all_env_nodes=[]

#iterate through leaves only
for n in t:
    n.add_features(env=False,old_name=n.name)
    n.name=d[n.name]
    if " REFERENCE; count=" in n.name:
        n.name=n.name.split(";")[3].split("scientific_name=")[1]+" "+n.name.split(";")[0]
        n.set_style(nstyleY)
    elif " count=" in n.name:
        n.add_features(env=True)
        n.name_splitted=n.name.split(";")
        n.name=n.name_splitted[2].split("scientific_name=")[1]+" "+n.name_splitted[0].split("-")[1].split("_CONS_SUB_SUB")[0]
        count=n.name_splitted[0].split("count=")[1]
        n.set_style(nstyleG)
        n.add_face(TextFace(count),column=0,position="aligned")
        all_env_nodes.append(n.name)

t.write(format=1, outfile="./nwk/"+sys.argv[1]+".nwk")
t.render("./pdfs/"+sys.argv[1]+".pdf", w=183, units="mm",tree_style=ts)

#find the closest non environmental leave
m=make_matrix(t)
f=open("tables/"+sys.argv[1]+"_neighbour_result.tsv","w")
f.write("Environmental Sequence\tClosest Database Sequence\n")
for n in all_env_nodes:
    pre_min=min(m[n], key=m[n].get)
    while pre_min in all_env_nodes:
        m[n][pre_min]=1000000
        pre_min=min(m[n], key=m[n].get)
    f.write(n+"\t"+pre_min+"\n")
f.close()' > tree2pdf.py
#########################################################
chmod +x tree2pdf.py

echo pdfing...
echo  'if this shows cannot connect to X-server try connecting via "ssh -X"'
for i in $TAXIDS
do
if [ -e "RAxML_bipartitions.${i}.raxml" ]
then
echo ${i}.pdf
( python ./tree2pdf.py RAxML_bipartitions.${i}.raxml ${i}.mafft.coffee.dict.pkl 2>$LOG/$i.pdf.log ) || ( xvfb-run --auto-servernum python ./tree2pdf.py RAxML_bipartitions.${i}.raxml ${i}.mafft.coffee.dict.pkl 2>$LOG/$i.pdf.log ) &
fi
done
wait
date


cp -f $OUT/FILES/RESULTS/*.tab $OUT/clas.res.tab
cp -rf $OUT/FILES/RESULTS/TREE/pdfs $OUT
cp -rf $OUT/FILES/RESULTS/TREE/nwk $OUT
cp -rf $OUT/FILES/RESULTS/TREE/tables $OUT


if [ $DELETE -gt 0 ];then
rm -r $OUT/FILES
fi
echo done
