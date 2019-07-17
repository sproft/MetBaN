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
download_EMBL  
ecoPCR_EMBL  
MetBaN (core script)  

STEP 1:  
download_EMBL:  
This script will download the latest release of the EMBL gene databank in conjunction with the latest release of the taxonomical information coming from NCBI.  
The script will then convert the database into a format that can be used by ObiTools.   
Usage:  
•	drop the script in the folder you wish to download the gene bank into  
•	run using bash (requires around 271G) `./download_EMBL  
•	a list of taxonomic devisions can be specified if the user wishes to only download a part of the database  
•	the folder “EMBL” can be deleted safely after successful conversion of the EMBL database into a format that can be used by ObiTools  

taxonomic divisions that can be specified in any combination include:  
•   HUM : human  
•   FUN : fungi  
•   VRL : viral  
•   MUS : mouse  
•   INV : invertebrate  
•   ENV : environmental  
•   ROD : rodent  
•   PLN : plant  
•   SYN : synthetic  
•   MAM : mammal  
•   PRO : prokaryote  
•   TGN : transgenic  
•   VRT : vertebrate  
•   PHG : phage  
•   UNC : unclassified  

It is however important to note that:  
"Each sequence is only assigned to one taxonomic division (otherwise the sequence would be duplicated in different parts of the database). However, as you can see from the list above, some taxonomic divisions overlap. Therefore, sequences are classified according to the most specific division. For example, a mouse sequence could belong to MUS, ROD, MAM or VRT divisions, but it is classified as MUS as this is the most specific category (lowest taxonomic node).

Once a sequence is placed in the most specific taxonomic division, it is then excluded from all remaining taxonomic divisions so as not to duplicate data. For example, the mouse sequence is found in the MUS divisions, therefore it is excluded from the ROD, MAM and VRT divisions, even though a rat is a mammal and a vertebrate."  
(https://www.ebi.ac.uk/training/online/course/nucleotide-sequence-data-resources-ebi/what-ena/how-data-structured)

On that note i strongly advice to always download the entire database, this will save you from lot of headaches in the long run.  

Example:  
`./download_EMBL HUM MUS`

STEP 2:  
ecoPCR_EMBL:  
This script prepares a reference database in order to successfully identify the taxon of sequences that were collected from the environment.  
For this we need to specify the primers that were used for capturing the barcodes.  
If several primers were used it is possible to specify ambiguous bases in order to cover all of them. 

Additionally we need to specify the path of the already converted database on which we would like to perform the inSilico PCR.  
And finally we need to specify the list of taxids for which we would like to create annotated reference sequences that are later required for the tree building step.  
You can find the taxids for your species of interest here: https://www.ncbi.nlm.nih.gov/taxonomy   
Usage:
```  
ecoPCR_EMBL FORWARD_PRIMER REVERSE_PRIMER  
Generate reference database for the identification using ecoPCR  
  -i   list of taxids (mandatory)  
  -d   path to converted database directory (mandatory)  
  -e   number of allowed errors [3]  
  -o   output directory [ecoPCR_database$DATE]  
  -l   lower read length cutoff [100]  
  -L   upper read length cutoff [500]  
  -V   show script version  
  -h   show this help  
```

Example:
`./ecoPCR_EMBL GCGGTAATTCCAGCTCCAATAG CTCTGACAATGGAATACGAATA -i "33836 33849 33853" -d embl_last/`  
The Nucleotide ambiguity code (IUPAC) is supported, if you want to specify several primers.

STEP 3:  
MetBaN:  
This script is the core of the pipeline.  
The main input are the fastq files of the forward and reverse read of the environmental sequences that are to have their taxids identified by ObiTools.  
As input it requires the path to both the converted database and the created reference sequences created from the specified taxids. These taxids need to be specified again in order to properly create pdfs containing trees that allow checking for the correctness of the identification of the environmental samples.  

For the tree building process we additionally require an outgroup sequence that has a reasonable phylogenetic distance to the group that is to be analyzed.  
The script will return a number of pdfs, which is at most the number of specified taxids (can be less when there exist no sequences belonging to a taxa in the fastq files).
These are not to be taken as phylogenetic relations, but as a tool to check whether sequences that were identified to belong to a certain taxa are also sorted in the same group in the tree.  
These trees can be found in the folder labeled pdfs and in the folder nwk saved in the newick format.  
Additional outputs can be found in the folder tables. These tables contain a list of all query sequences and their closest phylogenic neighbor as calculated by the phylogentic tree.  

The pipeline can either be run with either paired or unpaired reads and/or with demutiplexed or undemultiplex samples. Which input is being used can be set with the options -P and -R respectively.  

Additional information about the identified sequences can be found in a the provided result file.  
Usage:  
```
MetBaN FORWARD_READ.fq REVERSE_READ.fq  
Generate identification and phylogenetic tress for environmental reads  
-i   list of taxids (mandatory)
-g   path to the fasta that contains a single outgroup sequence (mandatory)
-d   path to EMBL database directory (mandatory)
-r   path to reference database directory (mandatory)
-a   annotated sequences for the tree building
-o   output directory [phylogenetic-trees$DATE]
-m   match cutoff [0.9]
-t   number of threads / parallel processes [2]
-l   read length cutoff [150]
-b   number of bootstrap runs in the tree building process [1000]
-P   run pipeline with already paired reads
-R   run pipeline in remultiplexing mode to remultiplex already demultiplexed samples
-D   delete intermediate files
-V   show script version
-h   show this help  
```

Example:  
`./MetBaN 1_S1_L001_R1_001.fastq 1_S1_L001_R2_001.fastq -i "33836 33849 33853" -g ../data/outgroup/Bolidomonas_outgroup.fas -r ecoPCR_database2017-05-15 -d embl_last/ -o long_test`

## Installation

Installation requirements:   
git: Install using your favourite package-manager (this will vary depending on the linux release you are using)  
gcc: Install using your favourite package-manager  
python-dev: Install using your favourite package-manager  
Xvfb: Unfortunately needs to be installed from an admin in order to create the pdf tree files on a system without a display.  


For installation please copy the following lines into your terminal.  
Some warnings might occur, you can check if your installation was succesfull by using the test script below.  


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

