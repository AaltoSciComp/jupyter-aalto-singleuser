# Disable student-facing extensions

# server
/opt/conda/bin/jupyter server extension disable --sys-prefix nbgrader.server_extensions.assignment_list
/opt/conda/bin/jupyter server extension disable --sys-prefix nbgrader.server_extensions.course_list
#/opt/conda/bin/jupyter server extension disable --sys-prefix nbgrader.server_extensions.validate_assignment

# lab
/opt/conda/bin/jupyter labextension disable --no-build nbgrader/assignment-list
/opt/conda/bin/jupyter labextension disable --no-build nbgrader/course-list
#/opt/conda/bin/jupyter labextension disable --no-build nbgrader/validate-assignment
/opt/conda/bin/jupyter lab build

# nbclassic
/opt/conda/bin/jupyter nbextension disable --sys-prefix course_list/main --section=tree
