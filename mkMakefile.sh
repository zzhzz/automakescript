#!/bin/bash

MAINFILENAME=
OUTPUTFILENAME=
PROGRAMVERSION=
DIRTYPE=
CPPFLAGS=""
LDFLAGS=""
LDADD=""
INCLUDEDIR=""
PROJECTPATH=""

while getopts :f:o:v:D:L:I:C opt
do 
	case "$opt" in
	f) MAINFILENAME=${OPTARG};;
	o) OUTPUTFILENAME=${OPTARG};;
	v) PROGRAMVERSION=${OPTARG};;
	D) DIRTYPE=${OPTARG};;
	C) CPPFLAGS="$CPPFLAGS $OPTARG";;
	L) LDFLAGS="$LDFLAGS $OPTARG";;
	I) INCLUDEDIR="$INCLUDEDIR $OPTARG";;
	*) echo "unknown option: ${opt} $OPTARG";;
	esac
done
	
if [ -z $MAINFILENAME ] 
then 

	echo "No main function file specified, please use -f option"
	exit 1;

elif [ -z $OUTPUTFILENAME ] 
then 
	
	echo "No output file specified, please use -o option"
	exit 1;

elif [ -z $PROGRAMVERSION ] 
then
	
	echo "No version specified, please use -v option"
	exit 1;

elif [ -z $DIRTYPE ] 
then
	
	echo "No directory type specified, please use -D option"
	exit 1;
fi

SOURCELIST=$(ls | gawk '/\.[ch]/{print $0}')

for NAME in $SOURCELIST
do 
	SRCNAME="$SRCNAME $NAME" 
done

autoscan
echo "scan successfully"

mv configure.scan configure.ac

case $DIRTYPE in

FLAT)
	
	sed 	"/AC_CONFIG_SRCDIR/s/\[.*\]/$MAINFILENAME/
		/AC_CONFIG_HEADERS/a\AM_INIT_AUTOMAKE($OUTPUTFILENAME,$PROGRAMVERSION)
		/AC_OUTPUT/c\AC_OUTPUT(Makefile)" configure.ac > tempfile 
	mv tempfile configure.ac

	echo \
		"AUTOMAKE_OPTIONS=foreign
noinst_PROGRAMS=$OUTPUTFILENAME
${OUTPUTFILENAME}_SOURCES=${SRCNAME}
${OUTPUTFILENAME}_CPPFLAGS=${CPPFLAGS}
${OUTPUTFILENAME}_LDFLAGS=${LDFLAGS}" > Makefile.am 
	;;

SHALLOW)
	DIRLIST="$(ls -l | gawk '$1 ~/^d/{print $9}')"
	MAKELIST="Makefile"
	

	for DIRNAME in $DIRLIST 
	do
		SUBSOURCE=
		SUBSOURCE=$(ls $DIRNAME | grep \.[ch]$)

	if [ -n $SUBSOURCE ]	
	then
		MAKELIST="$MAKELIST ${DIRNAME}/Makefile"			

		OUTLIBNAME=$(basename $DIRNAME)

		echo \
"AUTOMAKE_OPTIONS=foreign
noinst_LIBRARIES=lib${OUTLIBNAME}.a
${OUTLIBNAME}_a_SOURCES=${SUBSOURCE}
${OUTLIBNAME}_a_CPPFLAGS=${CPPFLAGS}
${OUTLIBNAME}_a_LDADD=${LDADD}
${OUTLIBNAME}_a_LDFLAGS=${LDFLAGS}" > ${DIRNAME}/Makefile.am 

	LDADD="$LDADD ${DIRNAME}/lib${DIRNAME}.a"
	
	fi
	
	done
	
	sed 	"
		/AC_CONFIG_HEADERS/a\AM_INIT_AUTOMAKE($OUTPUTFILENAME,$PROGRAMVERSION)
		/AC_PROG_CC/a\AC_PROG_RANLIB
		/AC_OUTPUT/c\AC_OUTPUT($MAKELIST)" configure.ac > tempfile

	mv tempfile configure.ac

	echo \
	"AUTOMAKE_OPTIONS=foreign
SUBDIRS=$DIRLIST
CURRENTPATH=$(pwd)
INCLUDES=$INCLUDEDIR

export INCLUDES

noinst_PROGRAMS=$OUTPUTFILENAME
${OUTPUTFILENAME}_SOURCES=${SRCNAME}
${OUTPUTFILENAME}_CPPFLAGS=${CPPFLAGS}
${OUTPUTFILENAME}_LDADD=${LDADD}
${OUTPUTFILENAME}_LDFLAGS=${LDFLAGS}
" > Makefile.am

	;;	
DEEP)
	DIRLIST="$(ls -l | gawk '$1 ~/^d/{print $9}')"
	SRCDIR=''	
	MAINDIR="$(echo "$MAINFILENAME" | gawk -F '/' '{print $1}' )"
	MAKELIST="Makefile ${MAINDIR}/Makefile"
	echo $MAINDIR
	for DIRNAME in $DIRLIST
	do
		if [ $DIRNAME != $MAINDIR ]
		then 
			SUBSOURCE=''
			SUBSOURCE=$(ls $DIRNAME | grep \.[ch]$)
			
			if [ -n $SUBSOURCE ]
			then 
				MAKELIST="$MAKELIST ${DIRNAME}/Makefile"
				OUTLIBNAME=`basename ${DIRNAME}`

				echo \
				"AUTOMAKE_OPTIONS=foreign
noinst_LIBRARIES=lib${OUTLIBNAME}.a
${OUTLIBNAME}_a_SOURCES=${SUBSOURCE}
${OUTLIBNAME}_a_CPPFLAGS=${CPPFLAGS}	
${OUTLIBNAME}_a_LDFLAGS=${LDFLAGS} " > ${DIRNAME}/Makefile.am
			
			
				LDADD="$LDADD ../${DIRNAME}/lib${OUTLIBNAME}.a"
				SRCDIR="$SRCDIR $DIRNAME"
			fi	
		else 
			SRCDIR="$SRCDIR $DIRNAME"	
		fi				
	done

	NAME=`basename ${MAINFILENAME}`	
	sed "
		/AC_CONFIG_SRCDIR/s/\[.*\]/${MAINDIR}\/$NAME/
		/AC_CONFIG_HEADERS/a\AM_INIT_AUTOMAKE($OUTPUTFILENAME,$PROGRAMVERSION)
		/AC_PROG_CC/a\AC_PROG_RANLIB
		/AC_OUTPUT/c\AC_OUTPUT($MAKELIST)" configure.ac > tempfile 

		mv tempfile configure.ac
		
		FILES=$(ls $MAINDIR | grep \.[ch]$)
	
		echo \
		"AUTOMAKE_OPTIONS=foreign
noinst_PROGRAMS=${OUTPUTFILENAME}
${OUTPUTFILENAME}_SOURCES=${FILES}
${OUTPUTFILENAME}_CPPFLAGS=${CPPFLAGS}
${OUTPUTFILENAME}_LDADD=${LDADD}	
" > ${MAINDIR}/Makefile.am

		echo \
		"AUTOMAKE_OPTIONS=foreign
SUBDIRS=$SRCDIR
" > Makefile.am
	;;
esac

aclocal

autoconf

autoheader

automake --foreign --add-missing


