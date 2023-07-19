# Enable instructor-facing extensions

# server
/opt/conda/bin/jupyter serverextension enable --sys-prefix nbgrader.server_extensions.formgrader
#jupyter serverextension enable --sys-prefix nbgrader.server_extensions.course_list

# lab
/opt/conda/bin/jupyter labextension enable --no-build nbgrader/formgrader
#/opt/conda/bin/jupyter labextension enable --no-build nbgrader/course-list
/opt/conda/bin/jupyter labextension enable --no-build nbgrader/create-assignment
/opt/conda/bin/jupyter lab build

# nbclassic
/opt/conda/bin/jupyter nbextension enable --sys-prefix formgrader/main --section=tree
/opt/conda/bin/jupyter nbextension enable --sys-prefix create_assignment/main
#/opt/conda/bin/jupyter nbextension enable --sys-prefix course_list/main --section=tree
