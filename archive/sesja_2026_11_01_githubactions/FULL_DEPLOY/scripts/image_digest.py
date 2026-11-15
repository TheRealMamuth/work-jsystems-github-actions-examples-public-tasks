"""Extract only the public digest, without the possibly masked registry username."""
import argparse
import json
import re
import sys


def image_digest(inspected, image):
    if not isinstance(inspected, list) or len(inspected) != 1 or not isinstance(inspected[0], dict):
        raise ValueError("Expected Docker inspection of exactly one image")
    references = inspected[0].get("RepoDigests") or []
    if not isinstance(references, list) or not all(isinstance(ref, str) for ref in references):
        raise ValueError("Invalid Docker RepoDigests")
    repository = image.removeprefix("docker.io/")
    digests = set()
    for reference in references:
        name, separator, digest = reference.rpartition("@")
        if separator and name.removeprefix("docker.io/") == repository:
            if not re.fullmatch(r"sha256:[0-9a-f]{64}", digest):
                raise ValueError("Published image has an invalid SHA256 digest")
            digests.add(digest)
    if len(digests) != 1:
        raise ValueError("Expected exactly one digest for the pushed image repository")
    return digests.pop()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("image", help="Image repository, without tag or digest")
    args = parser.parse_args()
    try:
        print(image_digest(json.load(sys.stdin), args.image))
    except ValueError as error:
        parser.exit(1, f"Image digest error: {error}\n")
