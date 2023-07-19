# Disable instructor-facing extensions

# server
/opt/conda/bin/jupyter server extension disable --sys-prefix nbgrader.server_extensions.formgrader
/opt/conda/bin/jupyter server extension disable --sys-prefix nbgrader.server_extensions.course_list

# lab
jupyter labextension disable --no-build nbgrader/formgrader
jupyter labextension disable --no-build nbgrader/create-assignment
jupyter labextension disable --no-build nbgrader/course-list
jupyter lab build

# nbclassic
/opt/conda/bin/jupyter nbextension disable     --sys-prefix formgrader/main --section=tree
/opt/conda/bin/jupyter nbextension disable     --sys-prefix create_assignment/main
