"""Build the Yersinia synteny tables from deposited complete genomes.

Run from the root of this branch: python3 scripts/prepare_yersinia.py
Needs Python 3.10+ and NCBI BLAST+ (blastn). Downloads and alignments are
cached in the ignored cache/ directory, so a second run is offline.

Method: megablast of each ordered genome pair, E-value <= 1e-20, dust and
soft masking off. Retain hits of at least 10 kb and 90% identity, process by
decreasing bit score, and discard a hit overlapping an accepted one by more
than half its length on either genome. The result is a set of non-redundant
local alignments, not the output of a dedicated synteny-block algorithm.
"""
import csv, hashlib, json, pathlib, subprocess, sys, urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
CACHE, OUT = ROOT / "cache", ROOT / "data/yersinia"
MIN_LEN, MIN_ID, EVALUE = 10000, 90.0, "1e-20"
COLS = "qseqid sseqid pident length qstart qend sstart send evalue bitscore".split()
GENOMES = [  # ancestor first, then the two plague strains
    ("NC_006155.1", "Y. pseudotuberculosis", "IP 32953", 4744671),
    ("NC_003143.1", "Y. pestis CO92", "CO92", 4653728),
    ("NC_004088.1", "Y. pestis KIM10+", "KIM10+", 4600755),
]
PAIRS = [(0, 1), (0, 2), (1, 2)]

def fetch(acc):
    path = CACHE / f"{acc}.fna"
    if not path.exists():
        url = ("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"
               f"?db=nuccore&id={acc}&rettype=fasta&retmode=text")
        path.write_bytes(urllib.request.urlopen(url).read())
    return path

def sequence_sha256(path):
    seq = "".join(l.strip() for l in path.read_text().splitlines() if not l.startswith(">"))
    return hashlib.sha256(seq.upper().encode()).hexdigest(), len(seq)

def align(qacc, sacc, label):
    out = CACHE / f"{label}.tsv"
    if not out.exists():
        subprocess.run(["blastn", "-task", "megablast", "-query", str(CACHE / f"{qacc}.fna"),
                        "-subject", str(CACHE / f"{sacc}.fna"), "-evalue", EVALUE, "-dust", "no",
                        "-soft_masking", "false", "-outfmt", "6 " + " ".join(COLS)],
                       check=True, stdout=out.open("w"))
    return out

def overlaps(a0, a1, b0, b1):
    lo, hi = max(min(a0, a1), min(b0, b1)), min(max(a0, a1), max(b0, b1))
    return max(0, hi - lo) > 0.5 * (max(a0, a1) - min(a0, a1))

def main():
    CACHE.mkdir(exist_ok=True); OUT.mkdir(parents=True, exist_ok=True)
    manifest = []
    for acc, label, strain, expected in GENOMES:
        digest, length = sequence_sha256(fetch(acc))
        if length != expected:
            sys.exit(f"{acc} is {length} bp, expected {expected}; review the record before updating.")
        manifest.append(dict(label=label, accession=acc, strain=strain, length_bp=length,
                             sequence_sha256=digest,
                             source_url=f"https://www.ncbi.nlm.nih.gov/nuccore/{acc}"))
    rows, stats = [], []
    for i, j in PAIRS:
        qacc, qlabel = GENOMES[i][0], GENOMES[i][1]
        sacc, slabel = GENOMES[j][0], GENOMES[j][1]
        hits = []
        for r in csv.reader(align(qacc, sacc, f"{qacc}__{sacc}").open(), delimiter="\t"):
            if int(r[3]) >= MIN_LEN and float(r[2]) >= MIN_ID:
                hits.append(dict(q0=int(r[4]), q1=int(r[5]), s0=int(r[6]), s1=int(r[7]), bits=float(r[9])))
        hits.sort(key=lambda h: -h["bits"])
        kept = []
        for h in hits:
            if any(overlaps(h["q0"], h["q1"], k["q0"], k["q1"]) or
                   overlaps(h["s0"], h["s1"], k["s0"], k["s1"]) for k in kept):
                continue
            kept.append(h)
        stats.append(dict(pair=f"{qlabel} vs {slabel}", blocks=len(kept),
                          inverted=sum(1 for h in kept if h["s0"] > h["s1"])))
        for h in kept:  # zero-based half-open kilobases, as elsewhere on this branch
            rows.append(dict(species1=qlabel, chr1=qacc,
                             start1=(min(h["q0"], h["q1"]) - 1) / 1000, end1=max(h["q0"], h["q1"]) / 1000,
                             species2=slabel, chr2=sacc,
                             start2=(min(h["s0"], h["s1"]) - 1) / 1000, end2=max(h["s0"], h["s1"]) / 1000,
                             orientation="minus" if h["s0"] > h["s1"] else "plus"))
    with (OUT / "chromosomes.tsv").open("w", newline="") as f:
        w = csv.DictWriter(f, ["species", "chr", "size"], delimiter="\t"); w.writeheader()
        for acc, label, _, length in GENOMES:
            w.writerow(dict(species=label, chr=acc, size=length / 1000))
    with (OUT / "blocks.tsv").open("w", newline="") as f:
        w = csv.DictWriter(f, list(rows[0]), delimiter="\t"); w.writeheader(); w.writerows(rows)
    (OUT / "provenance.json").write_text(json.dumps(dict(
        sequences=manifest, pairs=stats, total_blocks=len(rows),
        filters=dict(min_alignment_bp=MIN_LEN, min_identity_percent=MIN_ID, evalue=EVALUE,
                     overlap_rule="discard if >50% of a hit overlaps an accepted hit on either genome"),
        blast_version=subprocess.run(["blastn", "-version"], capture_output=True, text=True).stdout.split("\n")[0],
    ), indent=2) + "\n")
    for s in stats:
        print(f"{s['pair']}: {s['blocks']} blocks, {s['inverted']} inverted")
    print(f"total {len(rows)} blocks")

if __name__ == "__main__":
    main()
