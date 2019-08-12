#!/bin/bash

echo "FUCKING"

TMP_FILE='rbx_bkp_tmp.csv'

LOG_FILE='/var/log/rbx_bkp.log'

NFS_DIR='/mnt/RBX_BKP/'
BKP_DIR='/var/www/routerbox/file/doc/'

FILES=`ls -l --time-style="long-iso" $BKP_DIR | grep bkp | tr -s " " | cut -d" " -f6-`

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
  echo $checknfs
  if [ $chkmnt -eq 1 ]
  then
      echo "1"
      echo "OK! NFS IS MOUNTED" >> $LOG_FILE
  else
      echo "0"
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
  echo $(( (d1 - d2) / 86400 )) #Difference given in days
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
    bkpname=$(cut -d" " -f3 <<< $FILE)
    bkpdate=$(cut -d" " -f1 <<< $FILE)

    bkpext=$(cut -d"." -f2 <<< $bkpname)

    timestr=$(convertDate $bkpdate)

    datenow=$(date +%s)

    diffDate=$(getDateDiff $datenow $bkpdate)

    if [ $diffDate -le 1 ]
    then
      cp $BKP_DIR/$bkpname $NFS_DIR/routerbox_bkp_$bkpdate.$bkpext
      echo "$bkpname has been transfered" >> $LOG_FILE
    fi        
  done
}



nfsst=$(checknfs)
echo $nfsst
if [ $nfsst == "0" ]
then
  bkprun
  bkpdisc
  echo "Everything works fine!"
else
  echo "Something has fail, please check..."
fi
