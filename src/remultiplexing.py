import sys,os
import numpy as np
import argparse

numBases=5

parser = argparse.ArgumentParser(description='Script to help remultiplex sequencing files for MetBaN analysis')
parser.add_argument('Forward Primer', metavar='Fprimer', type=str,
                    help='The Forward Primer')
parser.add_argument('Reverse Primer', metavar='RPrimer', type=str,
                    help='The Reverse Primer')
parser.add_argument('FFiles', metavar='FList', type=str, nargs='+',
                    help='The Forward Read Files')
parser.add_argument('RFiles', metavar='RList', type=str, nargs='+',
                    help='The Reverse Read Files')


args = parser.parse_args()


def intToTag(i):
	ba=np.base_repr(i,4,padding=numBases-1)
        ba=np.array(list(ba[-numBases:]))
        tag=np.select([ba=='0',ba=='1',ba=='2',ba=='3'],['A','C','G','T']).tostring()
	return tag

def writeToAll(IFiles,OFile):
	for i in range(0,len(IFiles)):
        	f=open(IFiles[i],'r')
        	l=f.readline()
        	while l:
                	if l.startswith('@'):
				OFile.write(l)
                        	OFile.write(intToTag(i+1)+f.readline())
                        	OFile.write(f.readline())
                        	OFile.write("K"*numBases+f.readline())
                	l=f.readline()
        	f.close()


def writeFilter(IFiles,FPrimer,RPrimer):
	Fngs=open('ngsfilter.txt','w')
	Fngs.write('#exp\tsample\ttags\tforwardprimer\treverseprimer\n')
	for i in range(0,len(IFiles)):
		Fngs.write('sample\t'+os.path.basename(IFiles[i])+'\t'+intToTag(i+1)+':'+intToTag(i+1)+'\t'+FPrimer+'\t'+RPrimer+'\n')
	Fngs.close()



if __name__ == "__main__":
	FPrimer=sys.argv[1]
	RPrimer=sys.argv[2]
	
	Files=sys.argv[3:]
	
	IFilesR1=Files[:len(Files)/2]
	IFilesR2=Files[len(Files)/2:]

	R1=open('all.R1.fastq','w')
	R2=open('all.R2.fastq','w')

	writeToAll(IFilesR1,R1)
	writeToAll(IFilesR2,R2)
	writeFilter(IFilesR1,FPrimer,RPrimer)

	R1.close()
	R2.close()
