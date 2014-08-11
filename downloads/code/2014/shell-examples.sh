#!/usr/bin/env bash
################################################################################
function pause(){
   read -p "$*"
}
################################################################################

TESTVARIABLE="Some string in a variable."
TESTCOMMAND='hostname'

# ADD
# Replace $VARIABLES by its content. Can be escaped: \$VARIABLE
cat >> ${HOME}/atest-1.txt <<__EOF__
1234567890ß°!""§/()=?qwertzuiopü+QWERTZUIOPÜasdfghjklöä#ASDFGHJKLÖÄ<yxcvbnm,.->YXCVBNM/*-+7894561230,
1 ${TESTVARIABLE} 2 $TESTCOMMAND 3 `$TESTCOMMAND`
__EOF__
cat >> ${HOME}/atest-1.txt <<__EOF__
1234567890ß°!""§/()=?qwertzuiopü+QWERTZUIOPÜasdfghjklöä#ASDFGHJKLÖÄ<yxcvbnm,.->YXCVBNM/*-+7894561230,
1 ${TESTVARIABLE} 2 $TESTCOMMAND 3 `$TESTCOMMAND`
__EOF__

cat >> ${HOME}/atest-1a.txt <<'__EOF__'
1234567890ß°!""§/()=?qwertzuiopü+QWERTZUIOPÜasdfghjklöä#ASDFGHJKLÖÄ<yxcvbnm,.->YXCVBNM/*-+7894561230,
1 ${TESTVARIABLE} 2 $TESTCOMMAND 3 `$TESTCOMMAND`
__EOF__
cat >> ${HOME}/atest-1b.txt <<"__EOF__"
1234567890ß°!""§/()=?qwertzuiopü+QWERTZUIOPÜasdfghjklöä#ASDFGHJKLÖÄ<yxcvbnm,.->YXCVBNM/*-+7894561230,
1 ${TESTVARIABLE} 2 $TESTCOMMAND 3 `$TESTCOMMAND`
__EOF__
#####################################
# WRITE
# Replace $VARIABLES by its content. # Can be escaped: \$VARIABLE
cat > ${HOME}/atest-2.txt <<__EOF__
1234567890ß°!"§/()=?qwertzuiopü+QWERTZUIOPÜasdfghjklöä#ASDFGHJKLÖÄ<yxcvbnm,.->YXCVBNM/*-+7894561230,
1 ${TESTVARIABLE} 2 $TESTCOMMAND 3 `$TESTCOMMAND`
__EOF__
cat > ${HOME}/atest-2.txt <<__EOF__
1234567890ß°!"§/()=?qwertzuiopü+QWERTZUIOPÜasdfghjklöä#ASDFGHJKLÖÄ<yxcvbnm,.->YXCVBNM/*-+7894561230,
1 ${TESTVARIABLE} 2 $TESTCOMMAND 3 `$TESTCOMMAND`
__EOF__


################################################################################

# ADD
# No respect to $VARIABLES. They will be written like they are: Usefull to write scripts by a script.
cat << '__EOF__' >> ${HOME}/atest-3.txt
1234567890ß°!""§/()=?qwertzuiopü+QWERTZUIOPÜasdfghjklöä#ASDFGHJKLÖÄ<yxcvbnm,.->YXCVBNM/*-+7894561230,
1 ${TESTVARIABLE} 2 $TESTCOMMAND 3 `$TESTCOMMAND`
__EOF__
cat << '__EOF__' >> ${HOME}/atest-3.txt
1234567890ß°!""§/()=?qwertzuiopü+QWERTZUIOPÜasdfghjklöä#ASDFGHJKLÖÄ<yxcvbnm,.->YXCVBNM/*-+7894561230,
1 ${TESTVARIABLE} 2 $TESTCOMMAND 3 `$TESTCOMMAND`
__EOF__
cat << __EOF__ >> ${HOME}/atest-3a.txt
1234567890ß°!""§/()=?qwertzuiopü+QWERTZUIOPÜasdfghjklöä#ASDFGHJKLÖÄ<yxcvbnm,.->YXCVBNM/*-+7894561230,
1 ${TESTVARIABLE} 2 $TESTCOMMAND 3 `$TESTCOMMAND`
__EOF__

###################################
# WRITE
# No respect to $VARIABLES. They will be written like they are: Usefull to write scripts by a script.
cat << '__EOF__' > ${HOME}/atest-4.txt
1234567890ß°!""§/()=?qwertzuiopü+QWERTZUIOPÜasdfghjklöä#ASDFGHJKLÖÄ<yxcvbnm,.->YXCVBNM/*-+7894561230,
1 ${TESTVARIABLE} 2 $TESTCOMMAND 3 `$TESTCOMMAND`
__EOF__

cat << '__EOF__' > ${HOME}/atest-4.txt
1234567890ß°!""§/()=?qwertzuiopü+QWERTZUIOPÜasdfghjklöä#ASDFGHJKLÖÄ<yxcvbnm,.->YXCVBNM/*-+7894561230,
1 ${TESTVARIABLE} 2 $TESTCOMMAND 3 `$TESTCOMMAND`
__EOF__

################################################################################

### Variables ### ##############################################################
## Is Variable not available (zero)
if [ -z "${1}" ]; then
    WORKSPACE=/data/inm1/${USER}/workspace
else
    WORKSPACE=${1}
fi
## Is variable available (nonzero)
if [ -n "${1}" ]; then
    WORKSPACE=${1}
else
    WORKSPACE=/data/inm1/${USER}/workspace
fi

#man test
## Bash test
# Ausdruck		Beispiel		Erklärung
# -d verzeichnis	[ -d /tmp ]		Ist wahr, wenn die Datei existiert und ein Verzeichnis ist.
# -f datei		[ -f txt.txt ]		Ist wahr, wenn die Datei existiert und eine normale Datei ist.
# -w datei		[ -w text.txt ]		Ist wahr, wenn die Datei existiert und den Schreibzugriff erlaubt.
# -x datei		[ -x script.sh ]	Ist wahr, wenn die Datei existiert und die Ausführung erlaubt.
# -n string		[ -n "$name" ]		Ist wahr, wenn die übergebene Zeichenkette nicht leer ist.
# str1 = str2		[ "$1" = "Hallo" ]	Ist wahr, wenn beide Zeichenketten identisch sind.
# z1 -eq z2		[ 1 -eq $summe ]	Ist wahr, wenn beide Zahlen gleich groß sind (in Bedingungen wird zwischen Zahlen und Zeichenketten unterschieden).
# z1 -lt z2		[ 17 -lt $zahl ]	Ist wahr, wenn die erste Zahl kleiner als die zweite Zahl ist (lt = lower then).
# z1 -gt z2		[ 28 -gt $tag ]		Ist wahr, wenn die erste Zahl größer als die zweite Zahl ist.
# z1 -ne z2		[ $zahl -ne 7 ]		Ist wahr, wenn beide Zahlen ungleich sind.
# ! ausdruck		[ ! 1 -eq $zahl ]	Ist wahr, wenn der Ausdruck falsch ist (also eine Negierung).


### Dateien beschreiben ### ####################################################
TESTCOMMAND='hostname'
cat > testfile1 <<__EOF__
1 $HOME 2 '$HOME' 3 "$HOME" 4 `$TESTCOMMAND` Test-Text
__EOF__
cat >> testfile1 <<__EOF__
1 $HOME 2 '$HOME' 3 "$HOME" 4 `$TESTCOMMAND` Test-Text
__EOF__
cat << '__EOF__' > testfile2
1 $HOME 2 '$HOME' 3 "$HOME" 4 `$TESTCOMMAND` Test-Text
__EOF__
cat << '__EOF__' >> testfile2
1 $HOME 2 '$HOME' 3 "$HOME" 4 `$TESTCOMMAND` Test-Text
__EOF__



