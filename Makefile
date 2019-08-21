PATH := bin:util/mafft/bin:util/tcoffee/compile:util/standard-RAxML:util/anaconda_ete/bin:util/OBITools/bin:util/ecoPCR/src:util/Krona/KronaTools/bin:$(PATH)

.PHONY: all clean dependencies obitools

all:
	@echo "MetBaN itself doesn't require building. Use"
	@echo "make dependencies # to auto-install required tools in ./util/"
	@echo "make sure that Python-dev packages are installed"

clean:
	-rm -fr util

dependencies:
	hash mafft || $(MAKE) util/mafft
	hash t_coffee || $(MAKE) util/tcoffee
	hash raxmlHPC-PTHREADS || $(MAKE) util/raxml
	hash ktImportTaxonomy || $(MAKE) util/krona
	hash ecoPCR || $(MAKE) util/ecoPCR
	test -s util/anaconda_ete/bin/conda || $(MAKE) util/miniconda
	test -s util/OBITools/bin/obigrep || $(MAKE) util/obitools
	 #hash vcfutils.pl || $(MAKE) util/bcftools

obitools:
	test -s util/anaconda_ete/bin/conda || $(MAKE) util/miniconda
	test -s  util/OBITools/bin/obigrep || $(MAKE) util/obitools

util/mafft:
	mkdir -p util
	cd util && wget http://mafft.cbrc.jp/alignment/software/mafft-7.310-with-extensions-src.tgz 
	cd util && tar xfvz mafft-*-with-extensions-src.tgz && rm mafft-*-with-extensions-src.tgz && mv mafft-*-with-extensions mafft
	cd util/mafft && mkdir -p bin && sed -i -e 's?PREFIX = \/usr\/local?PREFIX = '`pwd`'?' core/Makefile
	cd util/mafft && sed -i -e 's?PREFIX = \/usr\/local?PREFIX = '`pwd`'?' extensions/Makefile
	cd util/mafft/core && make clean && make && make install

util/tcoffee:
	mkdir -p util
	cd util && git clone https://github.com/cbcrg/tcoffee.git
	cd util/tcoffee/compile && make t_coffee

util/raxml:
	mkdir -p util
	cd util && git clone https://github.com/stamatak/standard-RAxML.git
	cd util/standard-RAxML && make -f Makefile.gcc && make -f Makefile.PTHREADS.gcc
	cd util/standard-RAxML && make -f Makefile.AVX2.gcc && make -f Makefile.AVX2.PTHREADS.gcc
	cd util/standard-RAxML && make -f Makefile.AVX.gcc && make -f Makefile.AVX.PTHREADS.gcc
	cd util/standard-RAxML && make -f Makefile.SSE3.gcc && make -f Makefile.SSE3.PTHREADS.gcc

util/miniconda:
	mkdir -p util
	cd util && wget http://repo.continuum.io/miniconda/Miniconda-latest-Linux-x86_64.sh -O Miniconda-latest-Linux-x86_64.sh
	cd util && bash Miniconda-latest-Linux-x86_64.sh -b -p anaconda_ete/ && rm Miniconda-latest-Linux-x86_64.sh
	cd util/anaconda_ete/bin && ./conda install -y -c etetoolkit ete3 ete3_external_apps && ./conda install -y -c anaconda numpy
	cd util/anaconda_ete/bin && ./pip install ete3
	#&& ./conda install -y -c conda-forge xvfbwrapper

util/obitools:
	mkdir -p util
	cd util && wget http://metabarcoding.org/obitools/doc/_downloads/get-obitools.py
	cd util && anaconda_ete/bin/python get-obitools.py && rm get-obitools.py && rm obitools && mkdir -p OBITools && mkdir -p OBITools/bin
	cd util && cp OBITools-*/export/bin/* ./OBITools/bin
	cd util && sed -i -e 's/str(sequence\[end:end+self\.taglength\].complement())/str(sequence\[len(sequence)-self\.taglength:len(sequence)\]\.complement())/' OBITools/bin/ngsfilter
	cd util && sed -i -e 's/str(sequence\[start - self\.taglength:start\])/str(sequence\[0:self\.taglength\])/' OBITools/bin/ngsfilter

util/ecoPCR:
	mkdir -p util
	cd util && wget https://git.metabarcoding.org/obitools/ecopcr/uploads/6f37991b325c8c171df7e79e6ae8d080/ecopcr-0.8.0.tar.gz && tar -zxvf ecopcr-*.tar.gz
	cd util/ecoPCR/src/ && make
	cd util && rm ecopcr-0.8.0.tar.gz

util/krona:
	mkdir -p util
	cd util && git clone https://github.com/marbl/Krona.git
	cd util/Krona/KronaTools && ./install.pl --prefix "."
#	cd util/Krona/KronaTools && ./updateAccessions.sh
	cd util/Krona/KronaTools && mkdir -p taxonomy && ./updateTaxonomy.sh

#util/seqtk:
#	mkdir -p util
#	cd util && git clone https://github.com/lh3/seqtk.git;
#	cd util/seqtk && make

