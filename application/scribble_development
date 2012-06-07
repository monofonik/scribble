#! /bin/sh
rundir=`dirname "$0"`
userdir=`pwd`
cd "${rundir}"
if [[ "x$1" == "x" ]]; then arg="dev" ; elif [[ "${1:0:1}" == "/" || \
       "${1:0:1}" == "~" ]] ; then \
     arg="$1" ; else arg="${userdir}/$1" ; fi
if [[ "${arg}" != "dev" && \
      `basename "${arg}"` == `basename "${arg}" .ypr` && \
      `basename "${arg}"` == `basename "${arg}" .sb` ]]; then \
   arg="${arg}.ypr" ; fi
Scribble.app/Contents/MacOS/Scribble Scribble.image "${arg}" dev "${arg}" 2> /dev/null &
