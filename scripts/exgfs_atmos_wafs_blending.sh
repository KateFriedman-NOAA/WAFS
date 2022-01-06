#!/bin/ksh
################################################################################
####  UNIX Script Documentation Block
#                      .                                             .
# Script name:         exgfs_atmos_wafs_blending.sh
# Script description:  This scripts looks for US and UK WAFS Grib2 products,
# wait for specified period of time, and then run $USHgfs/wafs_blending.sh
# if both WAFS data are available.  Otherwise, the job aborts with error massage
#
# Author:        Hui-Ya Chuang       Org: EMC         Date: 2010-12-30
#
#
# Script history log:
# 2010-12-30  Huiya Chuang 
# Oct 2021 - Remove jlogfile

set -x
echo "JOB $job HAS BEGUN"

cd $DATA
export SLEEP_LOOP_MAX=`expr $SLEEP_TIME / $SLEEP_INT`
export SEND_US_WAFS=NO
export SEND_AWC_ALERT=NO

#if [ $cyc -eq 00 -o $cyc -eq 12 ] ; then
echo "start blending US and UK WAFS products for " $cyc " z cycle"
   export ffhr=$SHOUR

   while test $ffhr -le $EHOUR
   do   
# look for US WAFS data
     export ic=1
     while [ $ic -le $SLEEP_LOOP_MAX ]
     do
       if [ -s ${COMINus}/grib2.t${cyc}z.wafs_grb_wifsf${ffhr}.45 ] ; then
          break
       else
	  ic=`expr $ic + 1` 
	  sleep $SLEEP_INT 
       fi 
       if [ $ic -eq $SLEEP_LOOP_MAX ] ; then
          echo "US WAFS GRIB2 file " $COMINus/grib2.t${cyc}z.wafs_grb_wifsf${ffhr}.45 "not found after waiting over $SLEEP_TIME seconds"
	  echo "US WAFS GRIB2 file " $COMINus/grib2.t${cyc}z.wafs_grb_wifsf${ffhr}.45 "not found after waiting ",$SLEEP_TIME, "exitting"
          export err=1; err_chk
       fi 
     done
     
# look for UK WAFS data
     export ic=1
     while [ $ic -le $SLEEP_LOOP_MAX ]
     do
       if [ -s $COMINuk/EGRR_WAFS_unblended_${PDY}_${cyc}z_t${ffhr}.grib2 ] ; then
          $USHgfs/wafs_blending.sh
          break
       else
	  ic=`expr $ic + 1` 
	  sleep $SLEEP_INT 
       fi 
       if [ $ic -eq $SLEEP_LOOP_MAX ] ; then
          echo "UK WAFS GRIB2 file " $COMINuk/EGRR_WAFS_unblended_${PDY}_${cyc}z_t${ffhr}.grib2 " not found after waiting over $SLEEP_TIME seconds"
	  echo "UK WAFS GRIB2 file " $COMINuk/EGRR_WAFS_unblended_${PDY}_${cyc}z_t${ffhr}.grib2 " not found after waiting ",$SLEEP_TIME, 
	  echo "turning back on dbn alert for unblended US WAFS product"
          export SEND_US_WAFS=YES 

##############################################################################################
#
#  checking any US WAFS product was sent due to No UK WAFS GRIB2 file or WAFS blending program
#
          if [ $SEND_US_WAFS = "YES" -a $SEND_AWC_ALERT = "NO" ] ; then
             echo "Warning! No UK WAFS GRIB2 file for WAFS blending. Send alert message to AWC ......"
             make_NTC_file.pl NOXX10 KKCI $PDY$cyc NONE $FIXgfs/wafs_admin_msg $PCOM/wifs_admin_msg
             make_NTC_file.pl NOXX10 KWBC $PDY$cyc NONE $FIXgfs/wafs_admin_msg $PCOM/iscs_admin_msg
             if [ $SENDDBN_NTC = "YES" ] ; then
                $DBNROOT/bin/dbn_alert NTC_LOW WAFS  $job $PCOM/wifs_admin_msg
                $DBNROOT/bin/dbn_alert NTC_LOW WAFS  $job $PCOM/iscs_admin_msg
             fi

             if [ $envir != prod ]; then
                 export maillist='nco.spa@noaa.gov'
             fi
             export maillist=${maillist:-'nco.spa@noaa.gov,ncep.sos@noaa.gov'}
             export subject="WARNING! No UK WAFS GRIB2 file for WAFS blending, $PDY t${cyc}z $job"
             echo "*************************************************************" > mailmsg
             echo "*** WARNING! No UK WAFS GRIB2 file for WAFS blending      ***" >> mailmsg
             echo "*************************************************************" >> mailmsg
             echo >> mailmsg
             echo "Send alert message to AWC ...... " >> mailmsg
             echo >> mailmsg
             cat mailmsg > $COMOUT/${RUN}.t${cyc}z.wafs_blend_usonly.emailbody
             cat $COMOUT/${RUN}.t${cyc}z.wafs_blend_usonly.emailbody | mail.py -s "$subject" $maillist -v

             export SEND_AWC_ALERT=YES
          fi
##############################################################################################
 #
 #   Distribute US WAFS unblend Data to NCEP FTP Server (WOC) and TOC
 #
          echo "altering the unblended US WAFS products - $COMOUT/gfs.t${cyc}z.wafs_grb45f${ffhr}.grib2 "
          echo "and $COMOUT/gfs.t${cyc}z.wafs_grb45f${ffhr}.grib2.idx "
          echo "and $PCOM/grib2.t${cyc}z.wafs_grb_wifsf${ffhr}.45 "

#          if [ $SENDDBN_GB2 = "YES" -a $SEND_US_WAFS = "YES" ] ; then
          if [ $SENDDBN = "YES" -a $SEND_US_WAFS = "YES" ] ; then
             $DBNROOT/bin/dbn_alert MODEL GFS_WAFSA_GB2 $job $COMOUT/gfs.t${cyc}z.wafs_grb45f${ffhr}.grib2
             $DBNROOT/bin/dbn_alert MODEL GFS_WAFSA_GB2_WIDX $job $COMOUT/gfs.t${cyc}z.wafs_grb45f${ffhr}.grib2.idx
          fi
          
          if [ $SENDDBN_NTC = "YES" -a $SEND_US_WAFS = "YES" ] ; then
           # $DBNROOT/bin/dbn_alert MODEL GFS_WAFSA_GB2 $job $PCOM/grib2.t${cyc}z.wafs_grb_wifsf${ffhr}.45
             $DBNROOT/bin/dbn_alert NTC_LOW $NET $job   $PCOM/grib2.t${cyc}z.wafs_grb_wifsf${ffhr}.45
          fi
          export SEND_US_WAFS=NO

          #export err=1; err_chk
       fi 
     done     

#SH     $USHgfs/wafs_blending.sh

     echo "$PDY$cyc$ffhr" > $COMOUT/${RUN}.t${cyc}z.control.wafsblending


     export ffhr=`expr $ffhr + $FHINC`
     

     if test $ffhr -lt 10
     then
        export ffhr=0${ffhr}
     fi

   done
################################################################################

exit 0
#
