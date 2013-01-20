#!/bin/bash
# a: fixed displaying of Commandline settings
## Colors for error/info messages (Red,Green,Yellow and bolded)
#
TXTRED='\e[0;31m' 		# Red
TXTGRN='\e[0;32m' 		# Green
TXTYLW='\e[0;33m' 		# Yellow
BLDRED='\e[1;31m' 		# Red-Bold
BLDGRN='\e[1;32m' 		# Green-Bold
BLDYLW='\e[1;33m' 		# Yellow-Bold
TXTCLR='\e[0m'    		# Text Reset

## Sets variables for kernel build
export ARCH=arm
export DEFCONFIG=garwynn
export BASEDIR=`readlink -f ..`
export KERNELDIR=`readlink -f .`
export INITRAMFS_SOURCE=$BASEDIR/E4GT_Multiboot_initramfs
export INITRAMFS_TMP="/tmp/initramfs-e4gt"
export JOBS=`grep 'processor' /proc/cpuinfo | wc -l`
export VARIANT=AGAT_FL24_kernel
export RELEASE_VER=GAR_FL24-v1.0.0
export CROSS_COMPILE=~/E4GT/arm-eabi-4.4.3/bin/arm-eabi-

## Command line options that allow overriding defaults, if desired.

if [ "${1}" != "" ];
then
  clear
  ## Arg 1: Variant
  export VARIANT=${1}
  export KERNELDIR=$BASEDIR/$VARIANT
  echo
  echo -e "	${TXTYLW}Using variant: ${VARIANT}${TXTCLR}"
  echo

  ## Arg 2: initramfs source
  if [ "${2}" != "" ];
  then
    export INITRAMFS_SOURCE=$BASEDIR/${2}
    echo
    echo -e "	${TXTYLW}Using initramfs: ${INITRAMFS_SOURCE}${TXTCLR}"
    echo
  fi

  ## Arg 3: kernel_defconfig
  if [ "${3}" != "" ];
  then
    export DEFCONFIG=${3}
    echo
    echo -e "	${TXTYLW}Using DEFCONFIG: ${DEFCONFIG}${TXTCLR}"
    echo
  fi

  ## Arg 4: toolchain path
  if [ "${4}" != "" ];
  then
    export CROSS_COMPILE=${4}
    echo
    echo -e "	${TXTYLW}Using toolchain: ${CROSS_COMPILE}${TXTCLR}"
    echo
  fi
fi

## Print Settings
clear
echo
echo
echo
echo -e "	${BLDYLW}* -------------------------- *${TXTCLR}"
echo -e "	${BLDRED}* Using predefinied Settings *${TXTCLR}"
echo -e "	${BLDRED}* please review and confirm! *${TXTCLR}"
echo -e "	${BLDYLW}* -------------------------- *${TXTCLR}"
echo
echo -e "	${TXTGRN}ARCH:		${BLDRED}$ARCH${TXTCLR}"
echo -e "	${TXTGRN}BaseDir:	${BLDRED}$BASEDIR${TXTCLR}"
echo -e "	${TXTGRN}DEFCONFIG:	${BLDRED}$DEFCONFIG${TXTCLR}"
echo -e "	${TXTGRN}INITRAMFS:	${BLDRED}$INITRAMFS_SOURCE${TXTCLR}"
echo -e "	${TXTGRN}KernelDir:	${BLDRED}$KERNELDIR${TXTCLR}"
echo -e "	${TXTGRN}TOOLCHAIN:	${BLDRED}$CROSS_COMPILE${TXTCLR}"
echo -e "	${TXTGRN}VARIANT:	${BLDRED}$VARIANT${TXTCLR}"
echo -e "	${TXTGRN}Version:	${BLDRED}$RELEASE_VER${TXTCLR}"
echo -e "	${TXTYLW}--------------------------${TXTCLR}"
echo
echo
echo -e "	${BLDYLW}* --------------------------- *${TXTCLR}"
echo -e "	${BLDRED}* Agat Kernel Build Menu v1.0 *${TXTCLR}"
echo -e "	${BLDYLW}* --------------------------- *${TXTCLR}"
echo
echo -e "	${BLDYLW}Please choose from one of the following options:${TXTCLR}"
echo -e "	${BLDYLW}* *start* a Kernel Build, type: start(RETURN)${TXTCLR}"
echo -e "	${BLDYLW}* *abort* a Kernel Build, type: abort(RETURN)${TXTCLR}"
echo -e "	${BLDYLW}* --------------------------- *${TXTCLR}"
echo -e "	${BLDYLW}* --------------------------- *${TXTCLR}"
echo

## Get users Choice after reviewing Settings
ANSWER=abort
echo -e "${BLDRED}Type in your choice:${TXTCLR}"
read ANSWER

if [ "${ANSWER}" != "start" ];
then
  echo
  echo
  echo -e "		${BLDRED}**************************${TXTCLR}"
  echo -e "		${BLDRED}******* ABORT !!! ********${TXTCLR}"
  echo -e "		${BLDRED}Script execution aborted!!${TXTCLR}"
  echo -e "		${BLDRED}**************************${TXTCLR}"
  echo
  echo
  exit 0
fi

# Cleanup from any previous builds and copies clean initramfs and CWM-zip
echo -e "	${TXTYLW}Deleting Files of previous Builds ...${TXTCLR}"
rm -fv $KERNELDIR/zImage
rm -vf $INITRAMFS_TMP.cpio
rm -rvf $INITRAMFS_TMP
rm -fv $KERNELDIR/compile-*.log

#
## Start Kernel Build ...
#
clear
cd $KERNELDIR

if [ -f $KERNELDIR/.config ];
then
  echo
  echo -e "	${BLDRED}Found old Kernel config, Cleaning up old build files ...${TXTCLR}"
  echo
  make distclean
fi

echo
echo -e "	${BLDYLW}Creating new default Kernel Config: ${DEFCONFIG}${TXTCLR}"
echo

make "${DEFCONFIG}"_defconfig

. $KERNELDIR/.config

echo -e "	${TXTGRN}Build: Stage 1 building modules ...${TXTCLR}"
nice -n 10 make -j$JOBS modules 2>&1 | tee compile-modules.log

if [ "$?" != "0" ];
then
  ## Build failed? exit script ..
  echo
  echo
  echo -e "${BLDRED}**************************${TXTCLR}"
  echo -e "${BLDRED}******* ERROR !!! ********${TXTCLR}"
  echo -e "${BLDRED}failed to build modules...${TXTCLR}"
  echo -e "${BLDRED}**************************${TXTCLR}"
  echo
  echo
  exit 1
fi

# copy initramfs files to tmp directory
#
echo -e "	${TXTGRN}Copying initramfs Filesystem to: ${INITRAMFS_TMP}${TXTCLR}"
cp -vax $INITRAMFS_SOURCE $INITRAMFS_TMP
sleep 1



# remove repository realated files
#
echo -e "	${TXTGRN}Deleting Repository related Files (.git, .hg etc)${TXTCLR}"
find $INITRAMFS_TMP -name .git -exec rm -rvf {} \;
find $INITRAMFS_TMP -name placeholder.file -exec rm -rvf {} \;
rm -rvf $INITRAMFS_TMP/.hg

# copy modules into initramfs
#
echo -e "	${TXTGRN}Copying Modules to initramfs: ${INITRAMFS_TMP}/lib/modules${TXTCLR}"

if [ ! -d $INITRAMFS_TMP/lib/modules ];
then
  mkdir -pv $INITRAMFS_TMP/lib/modules
fi

find -name '*.ko' -exec cp -av {} $INITRAMFS_TMP/lib/modules/ \;
sleep 1

echo -e "	${TXTGRN}Striping Modules to save space${TXTCLR}"
# ${CROSS_COMPILE}strip --strip-unneeded $INITRAMFS_TMP/lib/modules/*
sleep 1

# create the initramfs cpio archive
#
echo
echo -e "	${TXTYLW}Creating initial Ram Filesystem: ${INITRAMFS_TMP}.cpio ${TXTCLR}"
echo
cd $INITRAMFS_TMP
find | fakeroot cpio -H newc -o > $INITRAMFS_TMP.cpio 2>/dev/null
ls -lh $INITRAMFS_TMP.cpio
cd -
sleep 1

# Start Final Kernel Build
#
echo
echo -e "	${TXTYLW}Starting final Build: zImage${TXTCLR}"
echo
nice -n 10 make -j12 CONFIG_INITRAMFS_SOURCE="$INITRAMFS_TMP.cpio" zImage 2>&1 | tee compile-zImage.log 

if [ "$?" != "0" ];
then
  ## Build failed? exit script ..
  echo
  echo
  echo -e "	${BLDRED}**************************${TXTCLR}"
  echo -e "	${BLDRED}******* ERROR !!! ********${TXTCLR}"
  echo -e "	${BLDRED}failed to build zImage ...${TXTCLR}"
  echo -e "	${BLDRED}**************************${TXTCLR}"
  echo
  echo
  exit 1
fi

if [ ! -f $KERNELDIR/arch/arm/boot/zImage ];
then
  ## Build failed? exit script ..
  echo
  echo
  echo -e "	${BLDRED}*********************************${TXTCLR}"
  echo -e "	${BLDRED}********** ERROR !!! ************${TXTCLR}"
  echo -e "	${BLDRED}zImage not found, build failed!!!${TXTCLR}"
  echo -e "	${BLDRED}*********************************${TXTCLR}"
  echo
  echo
  exit 1
else
  ## Create a ODIN TAR.  
  cp $KERNELDIR/arch/arm/boot/zImage $KERNELDIR/zImage 
  tar cf ${BASEDIR}/${RELEASE_VER}.tar zImage
  rm -v $KERNELDIR/zImage
  clear
  echo
  echo
  echo
  echo -e "	${BLDGRN}**************************${TXTCLR}"
  echo -e "	${BLDGRN}******* FINISH!!! ********${TXTCLR}"
  echo -e "	${BLDGRN}final Build stage done ...${TXTCLR}"
  echo -e "	${BLDGRN}**************************${TXTCLR}"
  echo
  echo -e "		${BLDGRN}Kernel Ready ...${TXTCLR}"
  echo
  echo -e "	${BLDRED}FileName..: ${TXTGRN}${BASEDIR}/${RELEASE_VER}.tar${TXTCLR}"
  echo -e "	${BLDRED}MD5SUM....: ${TXTGRN}$(md5sum ${BASEDIR}/${RELEASE_VER}.tar | awk '{print $1}')${TXTCLR}"
  echo -e "	${BLDRED}Size......: ${TXTGRN}$(ls -la ${BASEDIR}/${RELEASE_VER}.tar | awk '{print $5}')${TXTCLR}"
  echo
  echo
  echo
  exit 0
fi
