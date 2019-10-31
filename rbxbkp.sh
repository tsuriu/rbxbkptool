#!/bin/bash

LOG_FILE='/var/log/rbx_bkp.log'

NFS_DIR='/mnt/RBX_BKP'
BKP_DIR='/var/www/routerbox/file/doc'

bkpusr='tulioamancio'

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

convertDate(){
  echo $(date -d $1 +%s)
}

getDateDiff(){
  dt1=$1
  dt2=$2
  
  echo $(( (((dt1-dt2) > 0 ? (dt1-dt2) : (dt2-dt1)) + 43200) / 86400 )) #Difference given in days
  #echo $(( $(( $dt1 - $dt2 )) / 86400 )) #Difference given in days
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
  FILES=`ls -l --time-style="long-iso" /var/www/routerbox/file/doc | grep bkp | awk '$1=$1' | cut -d" " -f6,8 | sed "s/ /\|/g"`
  
  echo "$(date +"%d/%m/%Y %T") Starting to move files to the right places" >> $LOG_FILE

  for FILE in $FILES
  do
    flname=$(cut -d"|" -f2 <<< $FILE)
    fldate=$(cut -d"|" -f1 <<< $FILE)

    timestr=$(convertDate $fldate)

    datenow=$(date +%s)

    diffDate=$(getDateDiff $datenow $timestr)

    finalfile=$(echo "$timestr"_"$flname")

    #echo "$diffDate $finalfile"

    if [ $diffDate -le 7 -a ! -f "$NFS_DIR/$finalfile" ]
    then
      cp $BKP_DIR/$flname $NFS_DIR/$finalfile
      echo "$(date +"%d/%m/%Y %T") $flname has been transfered" >> $LOG_FILE
    fi
  done
}

housekeeper(){
  BKFILES=`ls -l --time-style="long-iso" $NFS_DIR | grep bkp | awk '$1=$1' | cut -d" " -f6,8 | sed "s/ /\|/g"`
  
  echo "It's time to clean your mess" >> $LOG_FILE

  for BKFILE in $BKFILES
  do
    bkpname=$(cut -d"|" -f2 <<< $BKFILE)
    bkpdate=$(cut -d"_" -f1 <<< $bkpname)

    timestr=$(convertDate $bkpdate)

    datenow=$(date +%s)

    diffDate=$(getDateDiff $datenow $timestr)

    echo $diffDate

    if [ $diffDate -gt 7 ]
    then
      echo "$(date +"%d/%m/%Y %T") bye bye... $bkpname. It's $diffDate days old."
      #  rm -rf $NFS_DIR/$bkpname
      echo "$(date +"%d/%m/%Y %T") $bkpname has been deleted" >> $LOG_FILE
    fi
  done
}

nfsst=$(checknfs)
if [ $nfsst == "0" ]
then
  bkprun
  bkpdisc
  housekeeper
  echo "$(date +"%d/%m/%Y %T") Everything works fine!"
else
  echo "$(date +"%d/%m/%Y %T") Something has fail, please check..."
fi
