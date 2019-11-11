#!/bin/bash

source rbxbkp_conf.sh

nfsmnt(){
  nfsvar=$(mount -t nfs 172.31.254.26:/nfs/rbx $NFS_DIR -O user=rbx,pass=e45b6e3959 | wc -l)
  if [ $nfsvar -eq 0 ]
  then
      echo "0"
      echo " $(date +"%d/%m/%Y %T") OK! NFS IS NOW MOUNTED!" >> $LOG_FILE
  fi
}

checknfs(){
  chkmnt=$(df -h | grep $NFS_DIR | wc -l)
  if [ $chkmnt -eq 1 ]
  then
      echo "0"
      echo " $(date +"%d/%m/%Y %T") OK! NFS IS MOUNTED" >> $LOG_FILE
  else
      echo "1"
      echo "$(date +"%d/%m/%Y %T") FAIL! NFS IF NOTE MOUNTED... Hang on, I'll try to mount it now." >> $LOG_FILE
      nfsmnt
  fi
}

getfllst(){
  if [ $2 == "nt" ]
  then
      sig="-"
  elif [ $2 == "ot" ]
  then
      sig="+"
  fi

  echo $(find $1 -name "*bkp*" -type f -mtime $sig$3)
}

bkprun(){
  echo "$(date +"%d/%m/%Y %T") Running RouterBOX backup routine" >> $LOG_FILE
  t1=$(date "+%s")
  /usr/bin/utils/router.box/backup executa $bkpusr isupergaus;
  t2=$(date "+%s")
  t=$(echo $(($(( $t2 - $t1 )) / 60)))
  echo "$(date +"%d/%m/%Y %T") RouterBOX backup is done in $t secs" >> $LOG_FILE
}

bkpdisc(){
  echo "$(date +"%d/%m/%Y %T") Starting to move files to the right places" >> $LOG_FILE

  for FILE in $(getfllst $BKP_DIR "nt" 7)
  do
    flname=$(cut -d"/" -f7 <<< $FILE)
    
    if [ ! -f "$NFS_DIR/$flname" ]
    then
      cp $BKP_DIR/$flname $NFS_DIR
      echo "$(date +"%d/%m/%Y %T") $flname has been transfered" >> $LOG_FILE
    fi
  done
}

housekeeper(){
  echo "It's time to clean your mess" >> $LOG_FILE

  for BKFILE in $(getfllst $NFS_DIR "ot" 7)
  do
    bkpname=$(cut -d"/" -f4 <<< $BKFILE)

    rm -rf $NFS_DIR/$bkpname
    echo "$(date +"%d/%m/%Y %T") $bkpname has been deleted" >> $LOG_FILE
  done
}

nfsst=$(checknfs)
if [ $nfsst == "0" ]
then
  #bkprun
  bkpdisc
  housekeeper
  echo "$(date +"%d/%m/%Y %T") Everything works fine!"
else
  echo "$(date +"%d/%m/%Y %T") Something has fail, please check..."
fi
