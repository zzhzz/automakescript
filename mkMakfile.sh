echo "Starting scanning source files:"
autoscan
mv configure.scan configure.ac
echo "Please input your filename which contains the main function:"
read MAINFILENAME
echo "Please input your out put file name:"
read OUTPUTFILENAME
echo "Please input your software version:"
read PROGRAMVERSION
echo "Please input your directory type:"
read DIRTYPE 

SOURCENAME=$(ls *.c)

	
case $DIRTYPE in

FLAT)
	NAME={basename $MAINFILENAME .c}
	
	sed 	"/AC_CONFIG_SRCDIR/s/.c/$NAME/
		/AC_CONFIG_HEADERS/a\AM_INIT_AUTOMAKE($OUTPUTFILENAME,$PROGRAMVERSION)
		/AC_PROG_CC/a\AC_PROG_ATACCC
		/AC_OUTPUT/c\AC_OUTPUT(Makefile)" configure.ac > tempfile 

	mv tempfile configure.ac

	echo \
		"AUTOMAKE_OPTIONS=foreign
noinst_PROGRAMS=$OUTPUTFILENAME
${OUTPUTFILENAME}_SOURCES=${SOURCENAME}
${OUTPUTFILENAME}_CPPFLAGS=${CPPFLAGS}
${OUTPUTFILENAME}_LDFLAGS=${LDFLAGS}" > Makefile.am 
	;;

SHALLOW)
	DIRLIST="$(ls -l | gawk '$1 ~/^d/{print $9}')"
	MAKELIST="Makefile"
	
	echo "Please input your INCLUDE Directory name"
	read INCLUDEDIR 

	for DIRNAME in $DIRLIST 
	do
		MAKELIST="$MAKELIST ./${DIRNAME}/Makefile"			
	done
	
	sed 	"
		/AC_CONFIG_HEADERS/a\AM_INIT_AUTOMAKE($OUTPUTFILENAME,$PROGRAMVERSION)
		/AC_OUTPUT/c\AC_OUTPUT($MAKELIST)" configure.ac > tempfile

	mv tempfile configure.ac
	
	echo \
	"AUTOMAKE_OPTIONS=foreign
SUBDIRS=$DIRLIST
CURRENTPATH=$(pwd)
INCLUDES=$INCLUDEDIR

export INCLUDES

noinst_PROGRAMS=$OUTPUTFILENAME
${OUTPUTFILENAME}_SOURCES=${SOURCENAME}
${OUTPUTFILENAME}_CPPFLAGS=${CPPFLAGS}
${OUTPUTFILENAME}_LDADD=${LDADD}
${OUTPUTFILENAME}_LDFLAGS=${LDFLAGS}
" > Makefile.am
	;;	
DEEP)
	DIRLIST="$(ls -l | gawk '$1 ~/^d/{print $9}')"
		
esac
