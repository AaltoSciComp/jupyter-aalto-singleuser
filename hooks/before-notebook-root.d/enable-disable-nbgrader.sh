# Default if nothing set should be suitable for indpendent use.

# These are the instructor-facing extensions
if [ -n "$AALTO_NB_DISABLE_FORMGRADER" ] ; then
    disable_formgrader.sh
fi
if [ -n "$AALTO_NB_ENABLE_FORMGRADER" ] ; then
    enable_formgrader.sh
fi

# This is the student-facing extensions (despite the name "nbgrader")
if [ -n "$AALTO_NBGRADER_DISABLE" ] ; then
    disable_nbgrader.sh
fi
if [ -n "$AALTO_NBGRADER_ENABLE" ] ; then
    enable_nbgrader.sh
fi
