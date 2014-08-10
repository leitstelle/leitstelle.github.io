#!/usr/bin/env bash
################################################################################
function pause(){
   read -p "$*"
}
################################################################################


TESTVARIABLE="Some string in a variable."
TESTCOMMAND='hostname'

# ADD
# Add something to a file, if not existing, file will be createt
# Replace $VARIABLES by its content.
# Can be escaped: \$VARIABLE
cat >> ${HOME}/atest-1.txt <<__EOF__
1234567890ß   °!"§/()=?
qwertzuiopü+   QWERTZUIOPÜ
asdfghjklöä#   ASDFGHJKLÖÄ
<yxcvbnm,.-   >YXCVBNM
/*-+   7894561230,

${TESTVARIABLE}
$TESTCOMMAND
`$TESTCOMMAND`
__EOF__
cat >> ${HOME}/atest-1.txt <<__EOF__
1234567890ß   °!"§/()=?
qwertzuiopü+   QWERTZUIOPÜ
asdfghjklöä#   ASDFGHJKLÖÄ
<yxcvbnm,.-   >YXCVBNM
/*-+   7894561230,

${TESTVARIABLE}
$TESTCOMMAND
`$TESTCOMMAND`
__EOF__


#####################################
# WRITE
# Replace something to a file, if not existing, file will be createt
# Replace $VARIABLES by its content.
# Can be escaped: \$VARIABLE
cat > ${HOME}/atest-2.txt <<__EOF__
^1234567890ß´   °!"§$%&/()=?`   ′¹²³¼½¬{[]}\¸
qwertzuiopü+   QWERTZUIOPÜ*   @ł€¶ŧ←↓→øþ¨~
asdfghjklöä#   ASDFGHJKLÖÄ'   æſðđŋħ ̣ ĸł˝^’
<yxcvbnm,.-   >YXCVBNM;:_   |»«¢„“”µ·…–
/*-+   7894561230,

${TESTVARIABLE}
$TESTCOMMAND
`$TESTCOMMAND`
__EOF__
cat > ${HOME}/atest-2.txt <<__EOF__
^1234567890ß´   °!"§$%&/()=?`   ′¹²³¼½¬{[]}\¸
qwertzuiopü+   QWERTZUIOPÜ*   @ł€¶ŧ←↓→øþ¨~
asdfghjklöä#   ASDFGHJKLÖÄ'   æſðđŋħ ̣ ĸł˝^’
<yxcvbnm,.-   >YXCVBNM;:_   |»«¢„“”µ·…–
/*-+   7894561230,

${TESTVARIABLE}
$TESTCOMMAND
`$TESTCOMMAND`
__EOF__


################################################################################

# ADD
# Add something to a file, if not existing, file will be createt
# No respect to $VARIABLES.
# They will be written like they are: Usefull to write scripts by a script.
cat << '__EOF__' >> ${HOME}/atest-3.txt
^1234567890ß´   °!"§$%&/()=?`   ′¹²³¼½¬{[]}\¸
qwertzuiopü+   QWERTZUIOPÜ*   @ł€¶ŧ←↓→øþ¨~
asdfghjklöä#   ASDFGHJKLÖÄ'   æſðđŋħ ̣ ĸł˝^’
<yxcvbnm,.-   >YXCVBNM;:_   |»«¢„“”µ·…–
/*-+   7894561230,
'
${TESTVARIABLE}
$TESTCOMMAND
`$TESTCOMMAND`
__EOF__
cat << '__EOF__' >> ${HOME}/atest-3.txt
^1234567890ß´   °!"§$%&/()=?`   ′¹²³¼½¬{[]}\¸
qwertzuiopü+   QWERTZUIOPÜ*   @ł€¶ŧ←↓→øþ¨~
asdfghjklöä#   ASDFGHJKLÖÄ'   æſðđŋħ ̣ ĸł˝^’
<yxcvbnm,.-   >YXCVBNM;:_   |»«¢„“”µ·…–
/*-+   7894561230,
'
${TESTVARIABLE}
$TESTCOMMAND
`$TESTCOMMAND`
__EOF__


###################################
# WRITE
# Replace something to a file, if not existing, file will be createt
# No respect to $VARIABLES.
# They will be written like they are: Usefull to write scripts by a script.
cat << '__EOF__' > ${HOME}/atest-4.txt
^1234567890ß´   °!"§$%&/()=?`   ′¹²³¼½¬{[]}\¸
qwertzuiopü+   QWERTZUIOPÜ*   @ł€¶ŧ←↓→øþ¨~
asdfghjklöä#   ASDFGHJKLÖÄ'   æſðđŋħ ̣ ĸł˝^’
<yxcvbnm,.-   >YXCVBNM;:_   |»«¢„“”µ·…–
/*-+   7894561230,
'
${TESTVARIABLE}
$TESTCOMMAND
`$TESTCOMMAND`
__EOF__
cat << '__EOF__' > ${HOME}/atest-4.txt
^1234567890ß´   °!"§$%&/()=?`   ′¹²³¼½¬{[]}\¸
qwertzuiopü+   QWERTZUIOPÜ*   @ł€¶ŧ←↓→øþ¨~
asdfghjklöä#   ASDFGHJKLÖÄ'   æſðđŋħ ̣ ĸł˝^’
<yxcvbnm,.-   >YXCVBNM;:_   |»«¢„“”µ·…–
/*-+   7894561230,
'
${TESTVARIABLE}
$TESTCOMMAND
`$TESTCOMMAND`
__EOF__

################################################################################
