import sys,os
import numpy as np
import argparse

numBases=10

parser = argparse.ArgumentParser(description='Script to help remultiplex sequencing files for MetBaN analysis')
parser.add_argument('fPrimer', metavar='ForwardPrimer', type=str,
                    help='The Forward Primer')
parser.add_argument('rPrimer', metavar='ReversePrimer', type=str,
                    help='The Reverse Primer')
parser.add_argument('fList', metavar='Files', type=str, nargs='+',
                    help='The Read Files')
parser.add_argument('--paired', action="store_true",
                    help='Whether the files are already paired')


args = parser.parse_args()


def intToTag(i):
	ba=np.base_repr(i+1,4,padding=numBases-1)
        ba=np.array(list(ba[-numBases:]))
        tag=np.select([ba=='0',ba=='1',ba=='2',ba=='3'],['A','C','G','T'])
        tag=''.join(str(x) for x in tag)
        return tag

def writeToAll(IFiles,OFile):
	for i in range(0,len(IFiles)):
        	f=open(IFiles[i],'r')
        	l=f.readline()
        	while l:
                	if l.startswith('@'):
				OFile.write(l)
                        	OFile.write(intToTag(i)+f.readline())
                        	OFile.write(f.readline())
                        	OFile.write("K"*numBases+f.readline())
                	l=f.readline()
        	f.close()


def writeFilter(IFiles,FPrimer,RPrimer):
	Fngs=open('ngsfilter.txt','w')
	Fngs.write('#exp\tsample\ttags\tforwardprimer\treverseprimer\n')
	for i in range(0,len(IFiles)):
		Fngs.write('sample\t'+os.path.basename(IFiles[i])+'\t'+intToTag(i)+':'+intToTag(i)+'\t'+FPrimer+'\t'+RPrimer+'\n')
	Fngs.close()



if __name__ == "__main__":
	FPrimer=args.fPrimer
	RPrimer=args.rPrimer
	
	Files=args.fList
	
	if args.paired:
		IFiles=Files
		R=open('all.fastq','w')
		writeToAll(IFiles,R)
		writeFilter(IFiles,FPrimer,RPrimer)

		R.close()
	else:
		IFilesR1=Files[:len(Files)/2]
		IFilesR2=Files[len(Files)/2:]

		R1=open('all.R1.fastq','w')
		R2=open('all.R2.fastq','w')

		writeToAll(IFilesR1,R1)
		writeToAll(IFilesR2,R2)
		writeFilter(IFilesR1,FPrimer,RPrimer)

		R1.close()
		R2.close()
