# Arabidopsis thaliana chloroplast (NC_000932.1)

Measured, published reference annotation of the *Arabidopsis thaliana*
chloroplast genome, RefSeq NC_000932.1, 154,478 bp, circular
(Sato et al. 1999, DNA Research 6:283-290). Retrieved from NCBI Nucleotide
with E-utilities `efetch` (`rettype=gbwithparts`) on 8 October 2026.
NCBI places no restriction on the use of these records. No simulated
observations were added.

All positions are 1-based GenBank coordinates on the published linear
representation of a circular molecule; position 1 is a convention.

| File | Contents |
|---|---|
| `regions.csv` | the four structural regions LSC, IRb, SSC, IRa (`start`, `end`); the inverted repeat is the longest reverse-complement match, 26,264 bp |
| `genes.csv` | CDS, tRNA and rRNA records: `gene`, `type`, `start`, `end`, `strand`, functional `class` |
| `gc_windows.csv` | GC fraction (`gc`) and GC skew in 1-kb windows every 500 bp (`start`, `mid`) |
| `ir_pairs.csv` | the 17 genes of IRb paired with their copy in IRa (`b_start`/`b_end`, `a_start`/`a_end`) |

Used by `data-raw/genome_ring.R` and the annotation-tracks article to draw a
complete genome ring: regions, strand-split genes coloured by function, GC
content and the inverted-repeat links.
