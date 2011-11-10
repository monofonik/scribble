#! /bin/sh
projdir=`pwd`
project=`basename "$1" .ypr`
project=`basename "${project}" .sb`
projext=`basename "$1"`
projfile="$1"
if [[ "${projfile:0:1}" != "/" && "${projfile:0:1}" != "~" ]] ; then \
    projfile="${projdir}/${projfile}" ; fi
rm -rf ~/Desktop/${project}.app
cp -r BYOB.app ~/Desktop/${project}.app
cd ~/Desktop/${project}.app/Contents/MacOS
mv BYOB realBYOB
cat > BYOB <<EOF
#! /bin/sh
mydir=\`dirname "\$0"\`
cd "\${mydir}"
./realBYOB "\`pwd\`/BYOB.image" ${projext} presentation ${projext} 2> /dev/null
EOF
chmod +x BYOB
cp "${projdir}/BYOB.image" .
cp "${projfile}" .
cd ../Resources
cp -f "${projdir}/GoboApplication.icns" BYOBApp.icns

