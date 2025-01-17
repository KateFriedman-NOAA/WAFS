#!/bin/bash

######################################################################
#  UTILITY SCRIPT NAME :  exwafs_grib.sh
#         DATE WRITTEN :  10/04/2004
#
#  Abstract:  This utility script produces the  WAFS GRIB
#
#     Input:  1 arguments are passed to this script.
#             1st argument - Forecast Hour - format of 2I
#
#     Logic:   If we are processing fhrs 12-30, we have the
#              added variable of the a or b in the process accordingly.
#              The other fhrs, the a or b  is dropped.
#
#####################################################################
echo "------------------------------------------------"
echo "JWAFS_00/06/12/18 GFS postprocessing"
echo "------------------------------------------------"
echo "History: OCT 2004 - First implementation of this new script."
echo "         Aug 2015 - Modified for Phase II"
echo "         Dec 2015 - Modified for input model data in Grib2"
echo "         Oct 2021 - Remove jlogfile"
echo "         May 2024 - WAFS separation"
echo " "
#####################################################################
set +x
fhr="$1"
num=$#

if test "$num" -ge 1
then
   echo " Appropriate number of arguments were passed"
   set -x
   export DBNALERT_TYPE=${DBNALERT_TYPE:-GRIB}
#   export job=${job:-interactive}
else
   echo ""
   echo "Usage: exwafs_grib.sh  \$fhr "
   echo ""
   exit 16
fi

cd $DATA

set -x

# To fix bugzilla 628 ( removing 'j' ahead of $job )
export jobsuffix=gfs_atmos_wafs_f${fhr}_$cyc

########################################
echo "HAS BEGUN!"
########################################

echo " ------------------------------------------"
echo " BEGIN MAKING GFS WAFS PRODUCTS"
echo " ------------------------------------------"

####################################################
#
#    GFS WAFS PRODUCTS MUST RUN IN CERTAIN ORDER
#    BY REQUIREMENT FROM FAA.
#    PLEASE DO NOT ALTER ORDER OF PROCESSING WAFS
#    PRODUCTS CONSULTING WITH MR. BRENT GORDON.
#
####################################################

set +x
echo " "
echo "#####################################"
echo " Process GRIB WAFS PRODUCTS (mkwafs)"
echo " FORECAST HOURS 00 - 72."
echo "#####################################"
echo " "
set -x

if test $fhr -eq 0
then
    echo "  "
fi

#    If we are processing fhrs 12-30, we have the
#    added variable of the a  or b in the process.
#    The other fhrs, the a or b  is dropped.

if test $fhr -ge 12 -a $fhr -le 24
then
    $USHwafs/mkwfsgbl.sh $fhr a
fi

if test $fhr -eq 30
then
    $USHwafs/mkwfsgbl.sh $fhr a
    for fhr in 12 18 24 30
    do
       $USHwafs/mkwfsgbl.sh $fhr b
    done
    $USHwafs/mkwfsgbl.sh 00 x
    $USHwafs/mkwfsgbl.sh 06 x
fi

if test $fhr -gt 30 -a $fhr -le 48
then
    $USHwafs/mkwfsgbl.sh $fhr x
fi

if test $fhr -eq 60 -o $fhr -eq 72
then
    $USHwafs/mkwfsgbl.sh $fhr x
fi

################################################################################
# GOOD RUN
set +x
echo "**************JOB EXWAFS_GRIB.SH COMPLETED NORMALLY ON THE IBM"
echo "**************JOB EXWAFS_GRIB.SH COMPLETED NORMALLY ON THE IBM"
echo "**************JOB EXWAFS_GRIB.SH COMPLETED NORMALLY ON THE IBM"
set -x
################################################################################

echo "HAS COMPLETED NORMALLY!"

exit 0

############## END OF SCRIPT #######################
