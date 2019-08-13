#!/bin/bash

TMP_FILE='rbx_bkp_tmp.csv'

LOG_FILE='/var/log/rbx_bkp.log'

NFS_DIR='/mnt/RBX_BKP'
BKP_DIR='/var/www/routerbox/file/doc'

FILES=`ls -l --time-style="long-iso" /var/www/routerbox/file/doc | grep bkp | awk '$1=$1' | cut -d" " -f6,8 | sed "s/ /\|/g"`

nfsmnt(){
  nfsvar=$(mount -t nfs 172.31.254.26:/nfs/rbx $NFS_DIR -O user=rbx,pass=e45b6e3959 | wc -l)
  if [ $nfsvar -eq 0 ]
  then
      echo "0"
      echo "OK! NFS IS NOW MOUNTED!" >> $LOG_FILE
  fi
}

checknfs(){
  chkmnt=$(df -h | grep $NFS_DIR | wc -l)
  if [ $chkmnt -eq 1 ]
  then
      echo "0"
      echo "OK! NFS IS MOUNTED" >> $LOG_FILE
  else
      echo "1"
      echo "FAIL! NFS IF NOTE MOUNTED... Hang on, I'll try to mount it now." >> $LOG_FILE
      nfsmnt
  fi  
}

convertDate(){
  echo $(date -d $1 +%s)
}

getDateDiff(){
  dt1=$1
  dt2=$2
  echo $(($(( $dt1 - $dt2 )) / 86400)) #Difference given in days
}

bkprun(){
  echo "Running RouterBOX backup routine" >> $LOG_FILE
  /usr/bin/utils/router.box/backup
  echo "RouterBOX backup is done" >> $LOG_FILE
}

bkpdisc(){

  echo "Starting to move files to the right places" >> $LOG_FILE

  for FILE in $FILES
  do
    bkpname=$(cut -d"|" -f2 <<< $FILE)
    bkpdate=$(cut -d"|" -f1 <<< $FILE)

    timestr=$(convertDate $bkpdate)

    datenow=$(date +%s)

    diffDate=$(getDateDiff $datenow $timestr)

    echo $diffDate

    echo $datenow $timestr $bkpdate $bkpname 

    if [ $diffDate -le 7 ]
    then
      cp $BKP_DIR/$bkpname $NFS_DIR
      echo "$bkpname has been transfered" >> $LOG_FILE
    fi        
  done
}

nfsst=$(checknfs)
if [ $nfsst == "0" ]
then
  #bkprun
  bkpdisc
  echo "Everything works fine!"
else
  echo "Something has fail, please check..."
fi