# Modified from https://bioc.r-universe.dev/msa/doc/manual.html#msa -> Examples

## read sequences
filepath <- system.file("examples", "exampleAA.fasta", package = "msa")
mySeqs <- Biostrings::readAAStringSet(filepath)

## call unified interface msa() for default method (ClustalW) and
## default parameters
msa::msa(mySeqs)

## call ClustalOmega through unified interface
msa::msa(mySeqs, method = "ClustalOmega")

## call MUSCLE through unified interface with some custom parameters
msa::msa(
  mySeqs,
  method = "Muscle",
  gapOpening = 12,
  gapExtension = 3,
  maxiters = 16,
  cluster = "upgmamax",
  SUEFF = 0.4,
  brenner = FALSE,
  order = "input",
  verbose = FALSE
)
