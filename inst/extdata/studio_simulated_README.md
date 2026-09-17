# Simulated Studio macro examples

These files are generated examples, not results from biological samples or
from running MCScanX or GENESPACE. Rebuild from the package root with
`Rscript data-raw/studio_simulated.R` (seed 5001).

Both examples contain four synthetic genomes, SimA through SimD, with eight
chromosomes each. All six genome pairs have supplied relationships.

- MCScanX: 240 blocks, 2644 anchor pairs, 5,120 annotated genes.
  180 plus / 60 minus blocks; minus blocks reverse anchor order.
- GENESPACE: 384 synHits-compatible simulated interval matches. Region IDs
  describe intervals, not inferred gene-level orthology. These exercise the
  existing coordinate parser; they do not reproduce the GENESPACE algorithm.
- Both include same-chromosome conservation and interchromosomal matches.
- Coordinates are integer base pairs. The existing importers convert them
  to Mb. MCScanX spans extend to the final annotated gene; GENESPACE spans
  are inferred from the supplied intervals and may omit terminal flanks.
- studio_simulated_chromosomes.tsv records the generation bounds in bp.
- Circular views show all 240 / 384 rows. With the default SimA-B-C-D order,
  linear chromosome views show the 120 / 192 adjacent-genome rows.

The small mcscanx_output.* and genespace_synHits.tsv files remain available
for short parser examples and upload tests.
