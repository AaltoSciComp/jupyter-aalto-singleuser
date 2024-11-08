if [ -r /course/etc.jupyter.nbgrader_config.py.append ] && [ -w /etc/jupyter/nbgrader_config.py ] ; then
    echo >> /etc/jupyter/nbgrader_config.py
    echo "# Appended from /course/etc.jupyter.nbgrader_config.py.append" >> /etc/jupyter/nbgrader_config.py
    cat /course/etc.jupyter.nbgrader_config.py.append >> /etc/jupyter/nbgrader_config.py
    echo >> /etc/jupyter/nbgrader_config.py
    echo "# end appended data" >> /etc/jupyter/nbgrader_config.py
fi
