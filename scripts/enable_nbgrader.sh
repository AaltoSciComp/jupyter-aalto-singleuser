# Enable student-facing extensions

# server
/opt/conda/bin/jupyter server extension enable --sys-prefix nbgrader.server_extensions.assignment_list
/opt/conda/bin/jupyter server extension enable --sys-prefix nbgrader.server_extensions.validate_assignment

# lab
/opt/conda/bin/jupyter labextension enable nbgrader/assignment-list
#/opt/conda/bin/jupyter labextension enable nbgrader/course-list
/opt/conda/bin/jupyter labextension enable nbgrader/validate-assignment

# nbclassic
/opt/conda/bin/jupyter nbextension enable --sys-prefix course_list/main --section=tree
