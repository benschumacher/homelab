#!/bin/bash
# vim: set shiftwidth=4:
set -x

if [[ "$#" -eq 0 ]]; then
     echo "Usage:"
     echo "  Find duplicates:           docker run --rm -v /path/to/music:/audio -v /path/to/db:/data container soundalike -db /data/fingerprints.db /audio"
     echo "  Compare two specific files: docker run --rm -v /path/to/music:/audio container soundalike -compare /audio/file1.mp3 /audio/file2.mp3"
     echo "  Interactive duplicate cleanup: docker run -it --rm -v /path/to/music:/audio -v /path/to/db:/data container soundalike -db /data/fingerAprints.db -move-interactive /audio/duplicates /audio"
     exit 1
fi

if [[ -x $(command -v -- "$1") ]]; then
    exec "$@"
else
    exec soundalike "$@"
fi

