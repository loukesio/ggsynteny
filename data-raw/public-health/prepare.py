"""Rebuild the public-health examples from pinned public records.

Run from any directory: python3 data-raw/public-health/prepare.py
Requires Python 3.10+, Biopython, curl and NCBI BLAST+ (tested with 2.16.0+).
Raw downloads and intermediate alignments are cached outside the package data.
Existing source checksums are verified before any output tables are rewritten.
"""

import csv
import hashlib
import itertools
import json
from pathlib import Path
import subprocess
import sys

import Bio
from Bio import SeqIO
from Bio.SeqRecord import SeqRecord

ROOT = Path(__file__).resolve().parents[2]
CACHE = ROOT / "dev/public-health/cache"
OUT = ROOT / "inst/extdata/public-health"
SOURCE = Path(__file__).parent / "sources"
COMMIT = "3887f91ed718b7df935c11d1a84e9276f4f6b01c"
BART = [
    ("NC_008783.1", "B. bacilliformis", "KC583"),
    ("NC_012846.1", "B. grahamii", "as4aup"),
    ("NC_005956.1", "B. henselae", "Houston-1"),
    ("NC_005955.1", "B. quintana", "Toulouse"),
]
PLASMIDS = [
    ("CP009862.1", "E. coli ECONIH1", "pKPC-629"),
    ("CP009864.1", "K. pneumoniae KPNIH29", "pKPC-e4e"),
    ("CP008901.1", "E. cloacae ECNIH3", "pKPC-47e"),
]
BLOCK_COLS = "species1 chr1 start1 end1 species2 chr2 start2 end2 orientation block_id identity".split()
FEATURE_COLS = "bin_id seq_id start end strand feat_id name locus_tag product protein_id".split()
LINK_COLS = "feat_id_a feat_id_b identity query_coverage subject_coverage bitscore".split()
BLAST_COLS = "qseqid sseqid pident length qstart qend sstart send evalue bitscore qlen slen".split()


def write_tsv(path, rows, columns):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, columns, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(args):
    subprocess.run([str(a) for a in args], check=True)


def fetch(url, destination):
    if not destination.exists():
        print("Downloading", destination.name, flush=True)
        temporary = destination.with_suffix(destination.suffix + ".part")
        run(["curl", "-fLsS", "--retry", "3", "--max-time", "240", url, "-o", temporary])
        temporary.replace(destination)


def genbank_url(specs):
    return ("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id="
            + ",".join(s[0] for s in specs) + "&rettype=gbwithparts&retmode=text")


def load_records(filename, specs):
    records = list(SeqIO.parse(CACHE / filename, "genbank"))
    assert [r.id for r in records] == [s[0] for s in specs], filename
    assert all(r.annotations.get("topology") == "circular" for r in records)
    return records


def blast(program, query, subject, target):
    args = [program, "-query", query, "-subject", subject,
            "-evalue", "1e-20", "-outfmt", "6 " + " ".join(BLAST_COLS),
            "-out", target]
    if program == "blastn":
        args += ["-task", "blastn", "-dust", "no", "-soft_masking", "false"]
    else:
        args += ["-seg", "yes", "-max_target_seqs", "10000", "-max_hsps", "1"]
    run(args)
    rows = []
    with target.open() as handle:
        for row in csv.DictReader(handle, fieldnames=BLAST_COLS, delimiter="\t"):
            rows.append({k: v if k.endswith("seqid") else float(v) for k, v in row.items()})
    return rows


def macro_bartonella(records):
    rows = []
    with (SOURCE / "barto.backbone").open() as handle:
        for index, row in enumerate(csv.reader(handle, delimiter="\t")):
            if index == 0:
                continue
            values = list(map(int, row))
            for i, j in itertools.combinations(range(4), 2):
                a, b = values[2*i:2*i+2], values[2*j:2*j+2]
                if 0 in a + b:
                    continue
                # Mauve uses signed, one-based inclusive coordinates. Negative
                # signs encode strand; genomic endpoints need absolute values.
                assert a[0] * a[1] > 0 and b[0] * b[1] > 0
                x0, x1 = min(map(abs, a)) - 1, max(map(abs, a))
                y0, y1 = min(map(abs, b)) - 1, max(map(abs, b))
                if min(x1-x0, y1-y0) < 10000:
                    continue
                assert 0 <= x0 < x1 <= len(records[i])
                assert 0 <= y0 < y1 <= len(records[j])
                rows.append(dict(zip(BLOCK_COLS, [
                    BART[i][1], records[i].id, x0/1000, x1/1000,
                    BART[j][1], records[j].id, y0/1000, y1/1000,
                    "plus" if a[0]*b[0] > 0 else "minus",
                    f"mauve_{index:04d}", "NA"])))
    return rows


def macro_plasmids(records):
    rows, audit = [], []
    for i, j in itertools.combinations(range(3), 2):
        target = CACHE / f"plasmid_{i}_{j}.blastn.tsv"
        hits = blast("blastn", CACHE / (records[i].id + ".fna"),
                     CACHE / (records[j].id + ".fna"), target)
        accepted = []
        for n, h in enumerate(sorted(hits, key=lambda h: (-h["bitscore"], h["qstart"], h["sstart"]))):
            x0, x1 = int(min(h["qstart"], h["qend"]))-1, int(max(h["qstart"], h["qend"]))
            y0, y1 = int(min(h["sstart"], h["send"]))-1, int(max(h["sstart"], h["send"]))
            reason = "retained"
            if h["pident"] < 95 or min(x1-x0, y1-y0, h["length"]) < 1000:
                reason = "below length or identity threshold"
            # Allow short HSP-end overlaps; a strict zero-overlap rule loses
            # long genuine matches because of a few shared terminal bases.
            elif any((min(x1, b)-max(x0, a) > 50 or min(y1, d)-max(y0, c) > 50)
                     for a, b, c, d in accepted):
                reason = "overlaps higher-scoring match by more than 50 bp"
            audit.append(dict(pair=f"{records[i].id}/{records[j].id}", **h, decision=reason))
            if reason != "retained":
                continue
            accepted.append((x0, x1, y0, y1))
            assert 0 <= x0 < x1 <= len(records[i]) and 0 <= y0 < y1 <= len(records[j])
            rows.append(dict(zip(BLOCK_COLS, [
                PLASMIDS[i][1], records[i].id, x0/1000, x1/1000,
                PLASMIDS[j][1], records[j].id, y0/1000, y1/1000,
                "plus" if (h["qend"]-h["qstart"])*(h["send"]-h["sstart"]) > 0 else "minus",
                f"blastn_{i}_{j}_{n:03d}", h["pident"]])))
    write_tsv(OUT / "plasmids/alignment_audit.tsv", audit, ["pair"] + BLAST_COLS + ["decision"])
    return rows


SHORT_PRODUCTS = {
    "hypothetical protein": "HP",
    "transcriptional regulator": "reg.",
    "integrase": "integrase",
    "dihydrofolate reductase": "DHFR",
    "mobilization protein": "Mob",
    "transposase": "Tnp",
    "restriction endonuclease": "REase",
    "modification methylase EcoRII": "MTase",
    "transposase, IS1 family protein": "IS1",
    "TetR family transcriptional regulator": "TetR",
    "nitroreductase": "Ntr",
    "serine dehydratase beta chain": "dehyd.",
    "L-serine ammonia-lyase": "Sda",
    "MerR family transcriptional regulator": "MerR",
}


def micro_features(records, specs, kind):
    features, proteins, windows = [], [], []
    for record, spec in zip(records, specs):
        cds = sorted([f for f in record.features if f.type == "CDS"],
                     key=lambda f: int(f.location.start))
        if kind == "bartonella":
            indices = [i for i, f in enumerate(cds) if f.qualifiers.get("gene") == ["rpoB"]]
            assert len(indices) == 1
            selected = cds[indices[0]-4:indices[0]+5]
            assert len(selected) == 9
        else:
            selected = [f for f in cds if int(f.location.start) >= 2000 and int(f.location.end) <= 10700]
        windows.append(dict(bin_id=spec[1], seq_id=record.id,
                            start=min(int(f.location.start) for f in selected),
                            end=max(int(f.location.end) for f in selected)))
        for f in selected:
            assert len(f.location.parts) == 1, "Split origin-spanning CDS before plotting"
            q = f.qualifiers
            tag = q["locus_tag"][0]
            ident = record.id + "__" + tag
            product = q.get("product", ["unannotated"])[0]
            name = q.get("gene", [SHORT_PRODUCTS.get(product, tag)])[0]
            features.append(dict(zip(FEATURE_COLS, [
                spec[1], record.id, int(f.location.start), int(f.location.end),
                "+" if f.location.strand == 1 else "-", ident, name, tag, product,
                q.get("protein_id", ["NA"])[0]])))
            # Missing translations remain in the gene table but acquire no link.
            if "translation" in q:
                from Bio.Seq import Seq
                proteins.append(SeqRecord(Seq(q["translation"][0]), id=ident, description=""))
    SeqIO.write(proteins, CACHE / f"{kind}.faa", "fasta")
    write_tsv(OUT / kind / "windows.tsv", windows, ["bin_id", "seq_id", "start", "end"])
    return features


def micro_links(features, kind):
    hits = blast("blastp", CACHE / f"{kind}.faa", CACHE / f"{kind}.faa", CACHE / f"{kind}.blastp.tsv")
    by_id = {f["feat_id"]: f for f in features}
    qualified = []
    for h in hits:
        if by_id[h["qseqid"]]["bin_id"] == by_id[h["sseqid"]]["bin_id"]:
            continue
        qc = (abs(h["qend"]-h["qstart"])+1) / h["qlen"] * 100
        sc = (abs(h["send"]-h["sstart"])+1) / h["slen"] * 100
        if h["pident"] >= 50 and min(qc, sc) >= 70:
            qualified.append(dict(h, query_coverage=qc, subject_coverage=sc))
    groups = {}
    for h in qualified:
        groups.setdefault((h["qseqid"], by_id[h["sseqid"]]["bin_id"]), []).append(h)
    best = {}
    for key, group in groups.items():
        score = max(h["bitscore"] for h in group)
        winners = [h for h in group if h["bitscore"] == score]
        if len(winners) == 1:
            best[key] = winners[0]
    links = []
    order = {name: i for i, name in enumerate(dict.fromkeys(f["bin_id"] for f in features))}
    for (query, target_bin), h in best.items():
        subject = h["sseqid"]
        query_bin = by_id[query]["bin_id"]
        reverse = best.get((subject, query_bin))
        if reverse and reverse["sseqid"] == query and order[query_bin] < order[target_bin]:
            links.append(dict(zip(LINK_COLS, [query, subject, h["pident"],
                round(h["query_coverage"], 3), round(h["subject_coverage"], 3), h["bitscore"]])))
    write_tsv(OUT / kind / "protein_matches.tsv", hits, BLAST_COLS)
    return sorted(links, key=lambda h: (h["feat_id_a"], h["feat_id_b"]))


def main():
    for path in (CACHE, OUT, SOURCE):
        path.mkdir(parents=True, exist_ok=True)
    downloads = [
        (genbank_url(BART), CACHE / "bartonella.gb"),
        (genbank_url(PLASMIDS), CACHE / "plasmids.gb"),
        (f"https://raw.githubusercontent.com/cran/genoPlotR/{COMMIT}/inst/extdata/barto.backbone", SOURCE / "barto.backbone"),
    ]
    sources = []
    for url, path in downloads:
        fetch(url, path)
        sources.append(dict(file=str(path.relative_to(ROOT)), url=url, sha256=sha(path)))
    lockfile = Path(__file__).parent / "sources.json"
    if lockfile.exists():
        assert json.loads(lockfile.read_text()) == sources, "Source checksum changed; review the upstream record before updating sources.json"
    else:
        lockfile.write_text(json.dumps(sources, indent=2) + "\n")
    summary, manifest = {}, []
    for kind, filename, specs in [("bartonella", "bartonella.gb", BART), ("plasmids", "plasmids.gb", PLASMIDS)]:
        records = load_records(filename, specs)
        for record, spec in zip(records, specs):
            SeqIO.write(record, CACHE / (record.id + ".fna"), "fasta")
            manifest.append(dict(dataset=kind, label=spec[1], accession=record.id,
                strain_or_plasmid=spec[2], length_bp=len(record), topology=record.annotations["topology"],
                organism=record.annotations["organism"],
                sequence_sha256=hashlib.sha256(str(record.seq).upper().encode()).hexdigest(),
                source_url="https://www.ncbi.nlm.nih.gov/nuccore/" + record.id))
        blocks = macro_bartonella(records) if kind == "bartonella" else macro_plasmids(records)
        chromosomes = [dict(species=spec[1], chr=r.id, size=len(r)/1000) for r, spec in zip(records, specs)]
        features = micro_features(records, specs, kind)
        links = micro_links(features, kind)
        assert len({f["feat_id"] for f in features}) == len(features)
        assert links and blocks
        for name, rows, cols in [("chromosomes", chromosomes, ["species", "chr", "size"]),
                                 ("blocks", blocks, BLOCK_COLS), ("features", features, FEATURE_COLS),
                                 ("links", links, LINK_COLS)]:
            write_tsv(OUT / kind / (name + ".tsv"), rows, cols)
        summary[kind] = dict(sequences=len(records), blocks=len(blocks),
                             inverted_blocks=sum(b["orientation"] == "minus" for b in blocks),
                             features=len(features), links=len(links))
    write_tsv(OUT / "sequences.tsv", manifest, list(manifest[0]))
    (OUT / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    versions = {"python": sys.version.split()[0], "biopython": Bio.__version__,
                "blastn": subprocess.check_output(["blastn", "-version"], text=True).splitlines()[0],
                "blastp": subprocess.check_output(["blastp", "-version"], text=True).splitlines()[0]}
    (OUT / "software.json").write_text(json.dumps(versions, indent=2) + "\n")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
