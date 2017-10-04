PATH := bin:util/mafft/scripts:util/tcoffee/compile:util/standard-RAxML:util/anaconda_ete/bin:util/OBITools/bin:$(PATH)

.PHONY: all clean dependencies

all:
	@echo "MetBaN itself doesn't require building. Use"
	@echo "make dependencies # to auto-install required tools in ./util/"
	@echo "make sure that Python-dev packages are installed"

clean:
	-rm -fr util

dependencies:
	hash mafft || $(MAKE) util/mafft
	hash t_coffee || $(MAKE) util/tcoffee
	hash raxmlHPC || $(MAKE) util/raxml
	hash conda ete3 || $(MAKE) util/miniconda
	#hash vcfutils.pl || $(MAKE) util/bcftools
	hash obigrep || $(MAKE) util/obitools

util/mafft:
	mkdir -p util
	cd util && wget http://mafft.cbrc.jp/alignment/software/mafft-7.310-with-extensions-src.tgz 
	cd util && tar xfvz mafft-*-with-extensions-src.tgz && rm mafft-*-with-extensions-src.tgz && mv mafft-*-with-extensions mafft
	cd util/mafft/core && make

util/tcoffee:
	mkdir -p util
	cd util && git clone https://github.com/cbcrg/tcoffee.git
	cd util/tcoffee/compile && make t_coffee

util/raxml:
	mkdir -p util
	cd util && git clone https://github.com/stamatak/standard-RAxML.git
	cd util/standard-RAxML && make -f Makefile.gcc && make -f Makefile.PTHREADS.gcc
	cd util/standard-RAxML && make -f Makefile.AVX2.gcc && make -f Makefile.AVX2.PTHREADS.gcc

util/miniconda:
	mkdir -p util
	cd util && wget http://repo.continuum.io/miniconda/Miniconda-latest-Linux-x86_64.sh -O Miniconda-latest-Linux-x86_64.sh
	cd util && bash Miniconda-latest-Linux-x86_64.sh -b -p anaconda_ete/ && rm Miniconda-latest-Linux-x86_64.sh
	cd util/anaconda_ete/bin && ./conda install -y -c etetoolkit ete3 ete3_external_apps 
	#&& ./conda install -y -c conda-forge xvfbwrapper

util/obitools:
	mkdir -p util
	cd util && wget http://metabarcoding.org/obitools/doc/_downloads/get-obitools.py
	cd util && anaconda_ete/bin/python get-obitools.py && rm get-obitools.py && rm obitools && mkdir -p OBITools && mkdir -p OBITools/bin
	cd util && cp OBITools-*/export/bin/* ./OBITools/bin
	

#util/seqtk:
#	mkdir -p util
#	cd util && git clone https://github.com/lh3/seqtk.git;
#	cd util/seqtk && make

