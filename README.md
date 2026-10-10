# ggsynteny on real data

This branch, `examples/real-data`, is a showcase: published data in, figures
and scripts out. It changes no package code, adds no tests and touches no
documentation of the package itself. Every figure is drawn with exported
ggsynteny functions from tables that ship here with their provenance, source
locks and checksums. To use the package, install `main`.

```
data/      the published tables, with provenance and checksums
scripts/   fetch, prepare, render and validate them
figures/   every rendered view, PNG and PDF
```

| Application | Data | What it shows |
|---|---|---|
| [The same genomes, annotated](#the-same-genomes-annotated) | the same records, plus GC, GC skew and mobile-element CDS | four annotation rings stacked on a rearrangement figure |
| [Plague and its ancestor](#plague-and-its-ancestor) | three deposited *Yersinia* genomes, new megablast alignments | 404 blocks, 211 of them reversed: a genome rearranged against the one it descends from |
| [Four *Bartonella* genomes](#four-bartonella-genomes) | NCBI RefSeq records; Mauve backbone from genoPlotR (GPL-2, retained) | whole-genome blocks with inversions, and the `rpoB` neighbourhood with protein links |
| [Two malaria vectors](#two-anopheles-malaria-vectors) | Jiang et al. 2014, 380 published synteny blocks | chromosome-arm block order; coordinates are block ranks, not base pairs |
| [A chloroplast genome ring](#a-chloroplast-genome-ring) | *Arabidopsis thaliana* plastid, RefSeq NC_000932.1 | regions, kb ticks, genes by strand and function, GC content and skew, repeat links |

<img src="figures/yersinia-linear.png" alt="Yersinia pseudotuberculosis and two Y. pestis strains, 404 alignment blocks with crossed ribbons marking reversed orientation" width="100%" />

<p float="left">
  <img src="figures/yersinia-circular.png" alt="The same three Yersinia genomes as a chord diagram" width="49%" />
  <img src="figures/bartonella-macro-circular.png" alt="Circular comparison of four Bartonella genomes" width="49%" />
</p>

**View:** [the seven Bartonella and Anopheles views as one PDF](figures/public-health-examples.pdf).
`scripts/render.R` also builds a standalone interactive page when Pandoc is
installed; it is generated, so it is not committed here.

Gene links are computed from protein alignments; matching annotation names
alone never create a link. All figures use `palette = "casa_natal"`.

## Plague and its ancestor

*Yersinia pestis* descends from the enteric pathogen *Yersinia
pseudotuberculosis*, and its genome is famously shuffled relative to that
ancestor. Three deposited complete genomes, aligned pairwise with megablast,
give **404 blocks of at least 10 kb, 211 of them in reversed orientation**.
Every crossed ribbon below is one of those reversals.

![Plague rearranged the genome it inherited](figures/yersinia-linear.png)

| Pair | Blocks | Reversed |
|---|---:|---:|
| *Y. pseudotuberculosis* vs *Y. pestis* CO92 | 161 | 62 |
| *Y. pseudotuberculosis* vs *Y. pestis* KIM10+ | 162 | 92 |
| *Y. pestis* CO92 vs *Y. pestis* KIM10+ | 81 | 57 |

The two plague strains differ from each other almost as much as each differs
from the ancestor, which is what the dense crossing in the lower panel shows.
The same blocks as a chord diagram, where `show_orientation = TRUE` twists
each reversed ribbon:

![The same comparison around a circle](figures/yersinia-circular.png)

[The tables, checksums and method](data/yersinia/README.md) ·
[rebuild](scripts/prepare_yersinia.py) · [redraw](scripts/yersinia_plots.R) ·
PDF versions of [the linear](figures/yersinia-linear.pdf) and
[the circular](figures/yersinia-circular.pdf) views.

These are local alignments between deposited sequences. A reversed block
means the records align in opposite orientation; the counts are not an
inference of how many inversion events happened, in what order, or when.

## The same genomes, annotated

The comparison above says *that* the genome moved. This one adds what the
records themselves say about it. Four rings stack outside each genome with
`syn_axis()` and the `syn_track_*()` wrappers, over the same ribbons:

![The elements that moved, and the genome they moved in](figures/yersinia-ring.png)

Reading outward from each arc: ticks every 500 kb, mobile-element CDS
coloured by family, GC content in 10 kb windows with the genome mean dashed,
and GC skew per window. The skew ring switches sign between the replication
origin and terminus, which is why each genome reads red for half its length
and blue for the other.

The mobile-element ring is the point. Classifying CDS by their own product
text gives:

| Genome | Transposase | Integrase | Recombinase or resolvase |
|---|---:|---:|---:|
| *Y. pseudotuberculosis* | 50 | 16 | 6 |
| *Y. pestis* CO92 | 203 | 14 | 4 |

Four times as many transposase genes in plague as in the ancestor it came
from, on a genome that is slightly *shorter*. The literature attributes the
rearrangements to exactly these elements; the figure puts the two side by
side without asserting the mechanism.

[The tables and method](data/yersinia/README.md#annotation-track-tables) ·
[rebuild](scripts/prepare_yersinia_tracks.py) ·
[redraw](scripts/yersinia_ring.R) · [PDF](figures/yersinia-ring.pdf)

## Four Bartonella genomes

This reuses the Mauve backbone supplied with
[genoPlotR's four-genome example](https://genoplotr.r-forge.r-project.org/vignette.php).
The source file and genome order are pinned to genoPlotR's CRAN mirror commit
`3887f91ed718b7df935c11d1a84e9276f4f6b01c`.
The included species have public-health relevance: *B. henselae*,
*B. quintana* and *B. bacilliformis* cause distinct forms of bartonellosis.
[CDC background](https://www.cdc.gov/bartonella/about/index.html).

| Genome | Versioned record | Length |
|---|---|---:|
| *B. bacilliformis* KC583 | [NC_008783.1](https://www.ncbi.nlm.nih.gov/nuccore/NC_008783.1) | 1,445,021 bp |
| *B. grahamii* as4aup | [NC_012846.1](https://www.ncbi.nlm.nih.gov/nuccore/NC_012846.1) | 2,341,328 bp |
| *B. henselae* Houston-1 | [NC_005956.1](https://www.ncbi.nlm.nih.gov/nuccore/NC_005956.1) | 1,931,047 bp |
| *B. quintana* Toulouse | [NC_005955.1](https://www.ncbi.nlm.nih.gov/nuccore/NC_005955.1) | 1,581,384 bp |

![Bartonella whole-genome comparison](figures/bartonella-macro-linear.png)

The 672 source backbone rows yield **215 pairwise interval links** after
requiring at least 10 kb in each genome of a pair. Of these, **62 have reversed
relative orientation**. A source block can contribute to multiple genome pairs;
215 is not a count of independent evolutionary events. Circular plots show
all six pairs; the linear figure shows 111 links between adjacent genomes.

![Bartonella gene regions](figures/bartonella-micro-linear.png)

The close-up selects `rpoB` and its four neighboring annotated CDS on each
side, in reference-coordinate order: **36 CDS and 46 protein links** across
all pairs, or 24 adjacent-pair links in the linear view. These protein matches
are newly computed from the selected annotated windows. The reverse strand
and reversed local order of the displayed *B. quintana* region are retained;
we have not rotated or reverse-complemented the reference genomes.

## Two Anopheles malaria vectors

The *An. gambiae*–*An. stephensi* comparison reuses **380 published synteny
blocks across five arms per species** from
[Jiang et al. (2014)](https://doi.org/10.1186/s13059-014-0459-2).
It adds a eukaryotic example with different 2L/3L arm correspondences and
extensive changes in block order. *An. stephensi* is an urban malaria vector
whose spread prompted a [WHO vector alert](https://www.who.int/publications/b/67602).

![Anopheles block-order comparison](figures/anopheles-block-order.png)

**These are block ranks, not base-pair coordinates.** Each block has equal
width, and track lengths count blocks. All 380 source links are shown in both
overviews; the X detail shows 66. The 198 opposite-orientation blocks are not
an estimate of evolutionary inversion events. The source's stephensi physical
map covered about 62% of the assembly, and only 32 of 86 mapped scaffolds had
experimentally assigned orientation. These limitations are retained in the
plots and documentation. The figure does not establish effects on transmission
or insecticide resistance.

[Download the native tables, original spreadsheet and provenance](data/anopheles),
read the [full methods](data/anopheles/README.md),
or open the [composite PDF](figures/anopheles-block-order.pdf).

## A chloroplast genome ring

The *Arabidopsis thaliana* plastid, [RefSeq NC_000932.1](https://www.ncbi.nlm.nih.gov/nuccore/NC_000932.1),
154,478 bp, drawn as one circular molecule: the four structural regions with
ticks every 10 kb, genes split by strand and coloured by function, GC content
in 1-kb windows against the genome mean, GC skew, and ribbons joining each of
the 17 inverted-repeat genes to its copy.

![The Arabidopsis chloroplast as a genome ring](figures/genome-ring.png)

This example ships with the package rather than with this branch; its data are
in `inst/extdata/chloroplast/` and the script is
[`scripts/genome_ring.R`](scripts/genome_ring.R). It is listed here because
it is the application that exercises the annotation tracks: `syn_axis()` and
the `syn_track_*()` wrappers on a published genome.

## Plot from the committed tables

Install ggsynteny from `main`, clone this branch beside it, and read the
tables straight from `data/`:

```sh
git clone --branch examples/real-data https://github.com/loukesio/ggsynteny.git ggsynteny-examples
cd ggsynteny-examples
```

```r
# install.packages("remotes"); remotes::install_github("loukesio/ggsynteny")
library(ggsynteny)

read_table <- function(dataset, name)
  read.delim(file.path("data", dataset, paste0(name, ".tsv")), stringsAsFactors = FALSE)

syn <- list(chromosomes = read_table("bartonella", "chromosomes"),
            blocks      = read_table("bartonella", "blocks"))
plot_circular_synteny(syn, palette = "casa_natal", chr_fill = "per_species",
                      ribbon_fill = "species_pair", show_orientation = TRUE)

plot_circular_microsynteny(read_table("bartonella", "features"),
                           read_table("bartonella", "links"),
                           palette = "casa_natal", ribbon_fill = "uniform")
```

For `"anopheles"` read only `chromosomes` and `blocks`; there are no gene-feature
or protein-link tables, and the coordinate unit is block rank. Use
`plot_synteny(syn, unique(syn$chromosomes$species), show_inversions = TRUE)` or
`plot_microsynteny(features, links)` for linear views; the figure scripts
restrict linear gene links to adjacent genomes for clarity. For an interactive
plot, pass `interactive = TRUE` and give the result to `syn_girafe()`.

## Upload to ggsynteny Studio

Open [the public app](https://01a0ae1e-adb1-a4f8-1ced-261952037ebf.share.connect.posit.cloud/)
or run `ggsynteny_app()` locally. Download the four relevant TSV files from
[Bartonella](data/bartonella). For
[Anopheles](data/anopheles), download its two native
chromosome/block tables; the values are block ranks, not base pairs.

| View | Input format | First upload | Second upload |
|---|---|---|---|
| Whole sequences / block orders | Native chromosome tables | `chromosomes.tsv` | `blocks.tsv` |
| Gene windows | Gene / link tables | `features.tsv` | `links.tsv` |

Select Upload, choose the format and files, and select Linear or Circular.
Enable the Interactive switch for tooltips and navigation. For whole-sequence
views, enable the orientation option to retain reversed matches. Keep the link
limit at 1,000 or higher to include every supplied link. Studio's labels and
spacing use its own controls; the committed PDFs use the figure scripts.

## Methods and reproduction

From a checkout of this branch, **render the committed results without network
access or BLAST**:

```sh
Rscript scripts/render.R
```

Rendering requires the package's dependencies, devtools, ggiraph, htmlwidgets,
htmltools, rmarkdown, and Pandoc. The output is seven individual PNG/PDF views, a seven-page combined PDF and
the three-panel Anopheles composite, plus a standalone interactive page when
Pandoc is available. To rebuild the input tables as
well, use Python 3.10+, Biopython and NCBI BLAST+:

```sh
python3 scripts/prepare.py
python3 scripts/prepare_anopheles.py
Rscript scripts/render.R
Rscript scripts/validate.R
```

The Anopheles conversion additionally needs Python's `openpyxl`; it reads the
bundled spreadsheet offline, verifies its checksum and reconstructs every
signed block order. Pass `--download-source` to `prepare_anopheles.py` to
re-fetch the original publisher archive. Its separate source lock and table
hashes are in `anopheles/provenance.json` in the data directory.

The bacterial preparation script pins accession versions, verifies SHA-256 hashes of the
downloaded GenBank records, and records sequence hashes and software versions.
It stops if an upstream record changes, including annotation changes under an
unchanged accession version. Review such changes before updating the source
lock. Raw downloads and intermediate FASTA files stay in the ignored cache.

- **Coordinates:** all intervals are zero-based, half-open. Whole-sequence
  tables use **kb**, including sequence lengths; gene tables use **bp**.
  Anopheles whole-arm tables instead use ordinal block positions: the interval
  for rank r is [r-1, r), and sequence sizes are block counts.
  Mauve's signed one-based coordinates are converted while preserving relative
  orientation. Protein strands come directly from the sequence annotations.
- **Plasmid matches:** BLASTn, task `blastn`, E-value ≤1e-20, dust and soft
  masking disabled; retain identity ≥95% and alignment/coordinate spans ≥1 kb.
  Process by decreasing bit score; discard matches overlapping an accepted
  match by >50 bp on either sequence. The audit table retains every raw match
  and its filtering decision. These are local alignments, not a separate
  synteny-block inference algorithm or an exhaustive map of repetitive DNA.
- **Protein links:** BLASTp with SEG filtering, E-value ≤1e-20, one HSP per
  subject; identity ≥50% and aligned span ≥70% of both protein lengths. Keep
  unique reciprocal best bit-score matches within each pair of selected
  windows, excluding tied best hits. These are regional homology candidates,
  not a genome-wide orthology analysis. All raw protein matches are included.
- **Labels:** existing gene names are retained; otherwise a short product
  label is used. HP = hypothetical protein; Ntr = nitroreductase; Sda = serine
  ammonia-lyase; dehyd. = serine dehydratase beta chain; DHFR = dihydrofolate
  reductase; REase = restriction endonuclease; MTase = EcoRII methylase;
  Mob = mobilization protein; Tnp = transposase; reg. = transcriptional regulator.
  Full products, locus tags, protein accessions and coordinates remain in the
  feature tables. Equal colors identify equal labels, not proven orthology.
- **Circular views:** bacterial whole-sequence sectors represent complete circular
  replicons. Anopheles sectors represent published block orders along linear
  chromosome arms, not complete chromosome lengths. Gene sectors span only the selected features. The latter are local
  windows displayed around a circle; unannotated flanks are not inferred.

The reuse notice and GPL license for the upstream Bartonella alignment and
derived macro tables are in [the data directory](data/README.md).
The preparation and rendering scripts are original example code under the
repository license.
