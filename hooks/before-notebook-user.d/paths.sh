# Add some things to different paths

# IF_EXIST - eval following line if $1 exists
# PATHADD2 - add $2 to the environment variable in $1, only if not
#     already there.
IF_EXIST () { if [ -e "$1" ] ; then eval "${@:2}" ; fi } #eval 2 on if $1 exist
PATHADD2 () { if eval [ x"\"\$$1\"" = x'' ] ; then eval "export $1=$2" ; else eval "echo \"\$$1\"" | grep "\(^\|:\)$2\(:\|$\)" 2>&1 > /dev/null || eval "export $1=\$$1:$2" ; fi }

IF_EXIST /m/jhnas/jupyter/software/bin/    PATHADD2 PATH /m/jhnas/jupyter/software/bin/
IF_EXIST /course/pymod/                    PATHADD2 PYTHONPATH /course/pymod/
IF_EXIST /m/jhnas/jupyter/software/pymod/  PATHADD2 PYTHONPATH /m/jhnas/jupyter/software/pymod/

unset IF_EXIST PATHADD2
