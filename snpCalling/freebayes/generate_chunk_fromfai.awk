##from length fasta file
BEGIN{
 if(!chunk_size){chunk_size=1000000}
 if(!lag){lag=0} #un peu redonandt comme initalisation mais jsute pour visualiser la variable...
}{
 nn=$2/chunk_size
 if(nn>1){
   {print $1":"1"-"(chunk_size-1)}
   deb=chunk_size
   for(i=2;i<nn;i++){
     {print $1":"(deb-lag)"-"(deb+chunk_size-1)}
     deb+=chunk_size
      }
   {print $1":"(deb-lag)"-"$2}
  }else{print $1}
}
