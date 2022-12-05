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
OUT_DIR=$(readlink -e ${2:-$(mktemp -d)})

pushd $OUT_DIR 


#### METADATA ####
echo "Omitting $(grep -c undefined $MD_FILE) undefined values " >&2
# decorate urls so they don't match
grep -v undefined "$MD_FILE" | sed -e 's#://#__URL__#g' | sed -r '/:/s/^/\n\n/' | sed -e 's#__URL__#://#g' | $WD/convert.awk > dublin_core.xml

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
function add_content {
    local line=$1
    if [ ! -e "$BAG_DIR/$line" ]; then
        # file does not exist, try unicode normalization on the line and test again
        line2=$(python3 -c "import unicodedata; print(unicodedata.normalize('NFC', '$line'))")
        if [ ! -e "$BAG_DIR/$line2" ]; then
            echo "Error: Neither \"$line\" nor \"$line2\" exists." >&2
            exit 3;
        else
            line=$line2
        fi
    fi
    local bundle=$2
    local description=$3
    echo -e "$(basename "$line")\tbundle:$bundle\tdescription:$description" >> contents
    cp "$BAG_DIR/$line" .
}

function process_manifest {
        local MANIFEST=$1
        local bundle
        sed -e 's/\s\+/ /' $MANIFEST | cut -d' ' -f2- |
        while read -r line; do
            #bitsream description
            local description=$(echo "$line" | sed -e 's/__/ /' -e 's/\..\{3,4\}$//' | cut -d' ' -f2)
            if [ "$description" = "metadata" ]; then
                bundle=METADATA
            elif echo "$description" | grep -q "thumbnail" ; then
                bundle=THUMBNAIL
                # thumbnail must have the same name as "ORIGINAL", suffix will be .mp4.jpg
                # keep the original file name in description
                local thumb_name=$(basename "$line")
                description=$thumb_name

                local thumb_suffix=${thumb_name##*.}
                # XXX lets hope all wikitongues bags have mp4
                local original_name=$(basename $(sed -e 's/\s\+/ /g' $MANIFEST | cut -d' ' -f2 | grep "\.mp4"))
                if [ -z "$original_name" ]; then
                        echo "WARN: can't find mp4 in ${MANIFEST}, thumbnail not added." >&2
                        continue;
                fi
                local new_thumb_name=${original_name}.${thumb_suffix}
                # copy the thumbnail under new name
                cp "$BAG_DIR/$line" "./$new_thumb_name"
                echo -e "$new_thumb_name\tbundle:$bundle\tdescription:$description" >> contents
                # XXX skip "default" add_content
                continue;
            else
                bundle=$2
            fi
            add_content "$line" "$bundle" "$description"
        done;
}
process_manifest $(find $BAG_DIR -type f -name 'manifest-*.txt' | head -n 1) ORIGINAL
process_manifest $(find $BAG_DIR -type f -name 'tagmanifest-*.txt' | head -n 1) METADATA
find $BAG_DIR -type f -name 'tagmanifest-*.txt' | while read -r line; do
        # remove BAG_DIR from start; it's added in add_content
        add_content "${line##$BAG_DIR}" "METADATA" "$(basename $line .txt)"
done
popd
