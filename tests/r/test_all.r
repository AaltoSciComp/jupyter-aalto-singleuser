# path <- this.path::this.dir()
path <- dirname(sys.frame(1)$ofile)
print(glue::glue("Found test path {path}"))
for (file in list.files(path, pattern="^test_.*\\.r$")) {
  if (file == "test_all.r") next
  print(glue::glue("Running {file}"))
  source(file.path(path, file))
}
