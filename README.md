## MetBaN
Version 1.01
## Synopsis

Automated pipeline for metabarcoding data using taxonomical/phylogenetical classification of organisms

## Motivation

This project aims to streamline the process of classifying the species in a metabarcoding experiment.  
This pipeline uses a combination of searching for the species via the EMBL database RAxML in order to fit the identefied sequences into a phylogenetic treem in order to occasionally improve and facillitate the classification process when a researcher reviewes the results. 

![workflow](https://github.com/sproft/MetBaN/blob/master/src/Workflow.png)


## Usage

The pipeline consists of three scripts:  
download_EMBL.sh  
ecoPCR_EMBL.sh  
MetBaN.sh (core script)  

download_EMBL.sh:  
This script will download the latest release of the EMBL gene databank in conjunction with the latest release of the taxonomical information coming from NCBI.  
The script will then convert the database into a format that can be used by ObiTools.  
Usage:  
•	drop the script in the folder you wish to download the gene bank into  
•	run using bash (requires around 271G) `./download_EMBL.sh`  
•	modifying the script allows for selecting specific sequences by having a look at the file structure at ftp://ftp.ebi.ac.uk/pub/databases/embl/release/std/ and modifying the option
“-A rel_std_\*.dat.gz” accordingly  
•	The folder “EMBL” can safely be deleted after successful conversion of the EMBL database into a format that can be used by ObiTools  

ecoPCR_EMBL.sh:  
This script prepares a reference database in order to successfully identify the taxon of sequences that were collected from the environment.  
For this we need to specify the Primers that were used for capturing the barcodes.  

Additionally we need to specify the path of the already converted database on which we would like to perform the inSilico PCR.  
And finally we need to specify the list of taxids for which we would like to create annotated reference sequences that are later required for the tree building step.  
Usage:
```  
ecoPCR_EMBL.sh FORWARD_PRIMER REVERSE_PRIMER  
Generate reference database for the identification using ecoPCR  
  -i   list of taxids (mandatory)  
  -d   path to converted database directory (mandatory)  
  -e   number of allowed errors [$ERRORS]  
  -o   output directory [$OUT]  
  -l   lower read length cutoff [$LLENGTH]  
  -L   upper read length cutoff [$ULENGTH]  
  -V   show script version  
  -h   show this help  
```

MetBaN.sh:  
This script is the core of the pipeline.  
The main input are the fastq files of the forward and reverse read of the environmental sequences that are to have their taxids identified by ObiTools.  
As input it requires the path to both the converted database and the created reference sequences created from the specified taxids. These taxids need to be specified again in order to properly create pdfs containing trees that allow checking for the correctness of the identification of the environmental samples.  

For the tree building process we additionally require an outgroup sequence that has a reasonable phylogenetic distance to the group that is to be analyzed.  
The script will return a number of pdfs, which is at most the number of specified taxids (can be less when there exist no sequences belonging to a taxa in the fastq files).
These are not to be taken as phylogenetic relations, but as a tool to check whether sequences that were identified to belong to a certain taxa are also sorted in the same group in the tree.  
These trees can be found in the folder labeled pdfs.

Additional information about the identified sequences can be found in a the provided result file.  
Usage:  
```
obiall.sh FORWARD_READ.fq REVERSE_READ.fq  
Generate identification and phylogenetic tress for environmental reads  
-i   list of taxids (mandatory)  
-g   path to the fasta that contains a single outgroup sequence (mandatory)  
-d   path to converted EMBL database directory (mandatory)  
-r   path to reference database directory (mandatory)  
-a   annotated sequences for the tree building  
-o   output directory [$OUT]  
-m   match cutoff [$MATCH]  
-t   number of threads / parallel processes [$THREADS]  
-l   read length cutoff [$LENGTH]  
-b   number of bootstrap runs in the tree building process [$BOOT]  
-D   delete intermediate files  
-V   show script version  
-h   show this help  
```

Example:  
`./MetBaN.sh 1_S1_L001_R1_001.fastq 1_S1_L001_R2_001.fastq -i "33836 33849 33853" -g ../data/outgroup/Bolidomonas_outgroup.fas -r ecoPCR_database2017-05-15 -d download_EMBL/ -o long_test`

## Installation

Installation requirements:  
Xvfb: Unfortunately has to be installed from an admin in order to create the pdf tree files.  

```bash
git clone https://github.com/sproft/MetBaN
cd MetBaN
make dependencies
```
  
Alternatively all programs can be installed globally see end section 

A small test script can be run here:  
```bash
cd test
./test.sh
``` 

This script checks whether everything works as it's supposed to.  

## License

Licensed under MIT

## Global installation
Obitools:  
Can be installed using the installation script offered on their website.  
http://metabarcoding.org//obitools/doc/_downloads/get-obitools.py  
To install the OBITools, you require these softwares to be installed on your system:  
•	Python 2.7 (installed by default on most Unix systems, available from the Python website)  
•	gcc (installed by default on most Unix systems, available from the GNU sites dedicated to GCC and GMake)  

ecoPCR:  
Can be acquired from the following website:  
https://git.metabarcoding.org/obitools/ecopcr/wikis/home  

mafft:  
Can be acquired from the following website:  
http://mafft.cbrc.jp/alignment/software/  

t_coffee:  
Can be acquired from the following website:  
http://www.tcoffee.org/Projects/tcoffee/  

raxmlHPC-AVX2:  
Can be build using the resources from the following websites:  
https://github.com/stamatak/standard-RAxML  

xvfb:  
Install using your favorite package manager  

python:  
Install using your favorite package manager  

Afterwards install ETE via pip:  
```bash
pip install --upgrade ete3
```

## Citation  
[![DOI](https://zenodo.org/badge/103414256.svg)](https://zenodo.org/badge/latestdoi/103414256)  

