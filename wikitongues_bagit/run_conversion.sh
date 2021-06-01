#!/usr/bin/env bash
#set -o xtrace
#set -o verbose
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
trap 's=$?; echo >&2 "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
shopt -s extglob
export SHELLOPTS

WD=$(dirname $(readlink -e $0))
BAG_DIR=$(readlink -e $1)
MD_FILE=$(find "$BAG_DIR"/ -type f -name '*metadata.txt' | head -n 1)
BAG_INFO=$(find "$BAG_DIR"/ -type f -name 'bag-info.txt' | head -n 1)
OUT_DIR=$(mktemp -d)

pushd $OUT_DIR 


#### METADATA ####
echo "Omitting $(grep -c undefined $MD_FILE) undefined values " >&2
grep -v undefined "$MD_FILE" | sed -r '/:/s/^/\n\n/' | $WD/convert.awk > dublin_core.xml

# extract contact person
email=$(grep Email: $BAG_INFO | cut -d' ' -f2-)
#XXX assumes it's in first last order
name=$(grep Name: $BAG_INFO | cut -d' ' -f2- | sed -e 's/\[.*\]\s\+//' -e 's/ /@@/')
org=$(grep Organization: $BAG_INFO | cut -d' ' -f2-)

cat >metadata_local.xml <<EOF
<dublin_core schema="local">
 <dcvalue element="contact" qualifier="person">${name}@@${email}@@${org}</dcvalue>
</dublin_core>
EOF

cat >metadata_metashare.xml <<EOF
<dublin_core schema="metashare">
 <dcvalue element="ResourceInfo#ContentInfo" qualifier="mediaType">video</dcvalue>
 <dcvalue element="ResourceInfo#ContentInfo" qualifier="detailedType">other</dcvalue>
</dublin_core>
EOF

#### CONTENT ####
cat $BAG_DIR/manifest-sha256.txt | sed -e 's/\s\+/ /g' | cut -d' ' -f2 |
        while read line; do
            #local description
            description=$(echo $line | sed -e 's/__/ /' -e 's/\..\{3,4\}$//' | cut -d' ' -f2)
            echo -e "$(basename $line)\tbundle:ORIGINAL\tdescription:$description" >> contents
	    cp $BAG_DIR/$line .
        done;
popd
