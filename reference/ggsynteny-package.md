# ggsynteny: Publication-Quality Synteny Plots

Create publication-quality synteny visualizations for comparative
genomics. Supports both macro-synteny (chromosome-level) and
micro-synteny (gene-level) plots with flexible coloring schemes.

## Main Functions

- [`plot_synteny`](https://loukesio.github.io/ggsynteny/reference/plot_synteny.md) -
  Create macro-synteny plots

- [`plot_microsynteny`](https://loukesio.github.io/ggsynteny/reference/plot_microsynteny.md) -
  Create micro-synteny plots

## Colour Palettes

Every `palette` argument accepts, by name, all 32 palettes of the [ltc
package](https://github.com/loukesio/ltc-color-palettes) (vendored, so
ltc need not be installed), e.g.
`plot_synteny(syn, sp_order, palette = "casa_natal")`. List them with
[`syn_palettes`](https://loukesio.github.io/ggsynteny/reference/syn_palettes.md).

## Data Parsers

- [`read_synteny_tsv`](https://loukesio.github.io/ggsynteny/reference/read_synteny_tsv.md) -
  Read TSV format

- [`read_mcscanx`](https://loukesio.github.io/ggsynteny/reference/read_mcscanx.md) -
  Read MCScanX format

- [`read_genespace`](https://loukesio.github.io/ggsynteny/reference/read_genespace.md) -
  Read GENESPACE format

## Example Data

- [`example_synteny_data`](https://loukesio.github.io/ggsynteny/reference/example_synteny_data.md) -
  Macro-synteny example

- [`demo_microsynteny_data`](https://loukesio.github.io/ggsynteny/reference/demo_microsynteny_data.md) -
  Micro-synteny example

## See also

Useful links:

- <https://github.com/loukesio/ggsynteny>

- Report bugs at <https://github.com/loukesio/ggsynteny/issues>

## Author

**Maintainer**: Loukas Theodosiou <theodosiou@evolbio.mpg.de>
([ORCID](https://orcid.org/0000-0001-6418-4652))
