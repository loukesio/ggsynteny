#!/usr/bin/env python3
"""Convert Jiang et al. (2014) signed block permutations into plotting tables.

The coordinates below are ordinal block positions, NOT nucleotide coordinates.
The small original spreadsheet is retained so the figure builds offline.
"""
import argparse
import csv
import hashlib
import io
import json
from pathlib import Path
import subprocess
import zipfile

import openpyxl

ROOT = Path(__file__).resolve().parents[2]
HERE = ROOT / "inst/extdata/public-health/anopheles"
SOURCE = HERE / "synteny-blocks-source.xlsx"
URL = ("https://static-content.springer.com/esm/"
       "art%3A10.1186%2Fs13059-014-0459-2/MediaObjects/"
       "13059_2014_459_MOESM2_ESM.zip")
MEMBER = "Additional file 22: Synteny Blocks.xlsx"
SOURCE_SHA256 = "0d4aaf7c1f9dd9c30c238bcd75c83ecbb0d20697d88dd579160403977dfe2adb"
ARCHIVE_SHA256 = "12df10ec854e6a64c40651b7f7c2ccf6567db97cf9ecb5885fa5051a906ae871"
# Arm correspondences and counts independently reported in Fig. 7's caption.
EXPECTED = {"Agam-3L:2L": 42, "Agam-2R:2R": 104,
            "Agam-2L:3L": 64, "Agam-3R:3R": 104, "Agam-X:X": 66}
SPECIES = ("An. gambiae", "An. stephensi")


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def write_tsv(name, rows):
    with (HERE / name).open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]),
                                delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--download-source", action="store_true",
                        help="Verify the original 14.8 MB publisher archive.")
    args = parser.parse_args()
    if args.download_source:
        archive = ROOT / "dev/public-health/cache/13059_2014_459_MOESM2_ESM.zip"
        archive.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["curl", "-fLsS", URL, "-o", str(archive)], check=True)
        content = archive.read_bytes()
        assert sha256(content) == ARCHIVE_SHA256, "Publisher archive changed"
        with zipfile.ZipFile(io.BytesIO(content)) as zipped:
            source = zipped.read(MEMBER)
        assert sha256(source) == SOURCE_SHA256, "Spreadsheet changed"
        SOURCE.write_bytes(source)

    source = SOURCE.read_bytes()
    assert sha256(source) == SOURCE_SHA256, "Unexpected source spreadsheet"
    workbook = openpyxl.load_workbook(io.BytesIO(source), read_only=True,
                                     data_only=True)
    assert workbook.sheetnames == ["two gene as one block"]
    rows = list(workbook.active.values)
    chromosomes, blocks, permutations, arms = [], [], [], []
    for column in range(0, 10, 2):
        header = rows[0][column]
        reference = [r[column] for r in rows[1:] if r[column] is not None]
        target = [r[column + 1] for r in rows[1:] if r[column + 1] is not None]
        n = EXPECTED[header]
        assert reference == list(range(1, n + 1)), header
        assert len(target) == n, header
        assert all(isinstance(x, int) and x != 0 for x in target), header
        assert sorted(abs(x) for x in target) == reference, header
        agam, aste = header.removeprefix("Agam-").split(":")
        chromosomes.extend([
            dict(species=SPECIES[0], chr=agam, size=n),
            dict(species=SPECIES[1], chr=aste, size=n)])
        arms.append(dict(gambiae_arm=agam, stephensi_arm=aste, blocks=n,
                         same_orientation=sum(x > 0 for x in target),
                         opposite_orientation=sum(x < 0 for x in target)))
        positions = {abs(signed): (rank, signed)
                     for rank, signed in enumerate(target, 1)}
        for rank, signed in enumerate(target, 1):
            permutations.append(dict(source_header=header, target_rank=rank,
                                     signed_reference_block=signed))
        for block in reference:
            rank, signed = positions[block]
            blocks.append(dict(
                species1=SPECIES[0], chr1=agam, start1=block - 1, end1=block,
                species2=SPECIES[1], chr2=aste, start2=rank - 1, end2=rank,
                orientation="plus" if signed > 0 else "minus",
                source_block_id=f"{agam}:{block}"))

    assert len(blocks) == 380
    assert len({r["source_block_id"] for r in blocks}) == len(blocks)
    limits = {(r["species"], r["chr"]): r["size"] for r in chromosomes}
    for row in blocks:
        for side in (1, 2):
            limit = limits[row[f"species{side}"], row[f"chr{side}"]]
            assert 0 <= row[f"start{side}"] < row[f"end{side}"] <= limit
            assert row[f"end{side}"] - row[f"start{side}"] == 1
    for arm in arms:
        selected = [r for r in blocks if r["chr1"] == arm["gambiae_arm"]]
        restored = [int(r["end1"]) * (1 if r["orientation"] == "plus" else -1)
                    for r in sorted(selected, key=lambda r: r["start2"])]
        original = [r["signed_reference_block"] for r in permutations
                    if r["source_header"] ==
                    f"Agam-{arm['gambiae_arm']}:{arm['stephensi_arm']}"]
        assert restored == original, "Plotting-table round trip failed"

    write_tsv("chromosomes.tsv", sorted(chromosomes,
              key=lambda r: (r["species"], r["chr"])))
    write_tsv("blocks.tsv", blocks)
    write_tsv("source-permutations.tsv", permutations)
    write_tsv("arm-summary.tsv", arms)
    metadata = dict(
        title="Published Anopheles block-order comparison",
        citation="Jiang et al. (2014), Genome Biology 15:459",
        doi="10.1186/s13059-014-0459-2",
        article_url="https://pmc.ncbi.nlm.nih.gov/articles/PMC4195908/",
        source_url=URL, retrieved="2026-09-17", archive_member=MEMBER,
        archive_sha256=ARCHIVE_SHA256, source_sha256=SOURCE_SHA256,
        license="Article CC BY 4.0; data CC0 unless otherwise stated",
        coordinate_unit="ordinal block rank; zero-based half-open unit intervals",
        track_extent="number of published blocks; not chromosome length",
        species=list(SPECIES), chromosome_arms_per_species=5, blocks=len(blocks),
        same_orientation=sum(r["orientation"] == "plus" for r in blocks),
        opposite_orientation=sum(r["orientation"] == "minus" for r in blocks),
        source_ortholog_count_reported_in_article=6448,
        source_stephensi_mapped_fraction_reported_in_article=0.62,
        limitations=[
            "The source spreadsheet contains signed block orders, not bp coordinates.",
            "The source physical map covers approximately 62% of the stephensi assembly.",
            "Only 32 of 86 mapped stephensi scaffolds were oriented experimentally; "
            "others used default orientation in the published analysis.",
            "Opposite-orientation block counts are not evolutionary inversion counts.",
            "This visualization does not measure vector competence or insecticide resistance."],
        validation=["Publisher source checksum matches",
                    "Counts match the published Figure 7 caption",
                    "Every signed permutation is complete and one-to-one",
                    "All plotting intervals are bounded and one block wide",
                    "All plotting tables reconstruct the original signed orders"])
    metadata["output_sha256"] = {name: sha256((HERE / name).read_bytes()) for name in
                                ["chromosomes.tsv", "blocks.tsv",
                                 "source-permutations.tsv", "arm-summary.tsv"]}
    (HERE / "provenance.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(f"Validated {len(blocks)} published blocks; "
          f"{metadata['opposite_orientation']} have opposite orientation.")


if __name__ == "__main__":
    main()
