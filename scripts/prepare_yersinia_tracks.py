"""Annotation-track tables for the Yersinia ring: GC, GC skew and mobile elements.

Run from the root of this branch: python3 scripts/prepare_yersinia_tracks.py
Needs Python 3.10+ and Biopython. The GenBank records are cached in the
ignored cache/ directory, so a second run is offline.

Coordinates are kilobases, matching data/yersinia/blocks.tsv, so the tables
can be added to the same figure with syn_track_*() and syn_axis().
"""
import csv, json, pathlib, re, urllib.request
from Bio import SeqIO

ROOT = pathlib.Path(__file__).resolve().parents[1]
CACHE, OUT = ROOT / "cache", ROOT / "data/yersinia"
WINDOW = 10_000                      # bases per GC / skew window
GENOMES = [("NC_006155.1", "Y. pseudotuberculosis"), ("NC_003143.1", "Y. pestis CO92")]
# Mobile-element families are read from the record's own product text; nothing
# is inferred from position or similarity.
FAMILIES = [("Transposase", re.compile(r"transposase|insertion sequence|IS\d", re.I)),
            ("Integrase", re.compile(r"integrase", re.I)),
            ("Recombinase or resolvase", re.compile(r"recombinase|resolvase", re.I))]

def genbank(acc):
    path = CACHE / f"{acc}.gb"
    if not path.exists():
        url = ("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"
               f"?db=nuccore&id={acc}&rettype=gbwithparts&retmode=text")
        path.write_bytes(urllib.request.urlopen(url).read())
    return SeqIO.read(path, "genbank")

def windows(seq):
    for start in range(0, len(seq), WINDOW):
        chunk = seq[start:start + WINDOW].upper()
        g, c = chunk.count("G"), chunk.count("C")
        called = g + c + chunk.count("A") + chunk.count("T")
        yield dict(start=start / 1000, end=min(start + WINDOW, len(seq)) / 1000,
                   gc=round(100 * (g + c) / called, 3) if called else "NA",
                   skew=round((g - c) / (g + c), 5) if (g + c) else "NA")

def family(feature):
    text = " ".join(feature.qualifiers.get("product", []) + feature.qualifiers.get("gene", []))
    for label, pattern in FAMILIES:
        if pattern.search(text):
            return label, text
    return None, text

def main():
    CACHE.mkdir(exist_ok=True); OUT.mkdir(parents=True, exist_ok=True)
    win_rows, feat_rows, counts = [], [], {}
    for acc, label in GENOMES:
        record = genbank(acc)
        seq = str(record.seq)
        for w in windows(seq):
            win_rows.append(dict(species=label, chr=acc, **w))
        found = {}
        for f in record.features:
            if f.type != "CDS":
                continue
            fam, text = family(f)
            if fam is None:
                continue
            start, end = int(f.location.start), int(f.location.end)
            if end <= start:
                continue
            feat_rows.append(dict(species=label, chr=acc, start=start / 1000, end=end / 1000,
                                  strand="+" if f.location.strand == 1 else "-",
                                  family=fam, product=text.strip()[:80]))
            found[fam] = found.get(fam, 0) + 1
        counts[label] = dict(length_bp=len(seq), windows=-(-len(seq) // WINDOW), mobile_cds=found)
    with (OUT / "ring-windows.tsv").open("w", newline="") as f:
        w = csv.DictWriter(f, ["species", "chr", "start", "end", "gc", "skew"], delimiter="\t")
        w.writeheader(); w.writerows(win_rows)
    with (OUT / "ring-features.tsv").open("w", newline="") as f:
        w = csv.DictWriter(f, ["species", "chr", "start", "end", "strand", "family", "product"], delimiter="\t")
        w.writeheader(); w.writerows(feat_rows)
    (OUT / "ring-provenance.json").write_text(json.dumps(dict(
        window_bases=WINDOW, coordinate_unit="kb", genomes=counts,
        gc_percent="100 * (G + C) / called bases", gc_skew="(G - C) / (G + C) per window",
        mobile_element_rule="CDS whose product or gene text matches transposase/insertion sequence/IS<digit>, integrase, or recombinase/resolvase",
    ), indent=2) + "\n")
    for label, c in counts.items():
        print(f"{label}: {c['windows']} windows, mobile CDS {c['mobile_cds']}")

if __name__ == "__main__":
    main()
