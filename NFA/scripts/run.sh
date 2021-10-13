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

WD=$(dirname $(readlink -e $0))/..
TMP=${TMP:-$(mktemp -d)}
MD_ONLY=${MD_ONLY:-FALSE}

CP=${CP:-/mnt/c/Users/ko_ok/.m2/repository/net/sf/saxon/Saxon-HE/9.9.1-6/Saxon-HE-9.9.1-6.jar}

DATADIR=${DATADIR:-$WD/NFA}
PREFIX=${PREFIX:-123456789}
CONTACT_PERSON=${CONTACT_PERSON:-Tomáš@@Fuk@@fuk@example.com@@Example ltd.}


function getAvailableShots {
    local MOV_DIR=$1
    local j
    for j in $MOV_DIR/*.mov; do
        # Mnichov: ZF_0340_3900403_sot3_hd-master.mov -> 3
        # Galerie: 3901034_26_hd-master.mov -> 26
        echo $j | sed -E -e 's/.*(sot|_)([0-9]+)_.*/\2/'
    done | paste -d\; -s
}

function sanitycheck {
    local real=$(xmllint --xpath 'count(/root/item/dublin_core[@schema="dc"])' $1)
    local expected=$(ls $2/*.mov | wc -l)
    if [ "$real" -ne "$expected" ]; then
        echo "ERR: expected $expected shots (based on $2) but found $real (in $1)" >&2
        echo "Maybe the *.mov indexes are 0 based but 'CISLO-SOTU' in metadata starts from 1." >&2
        exit 1
    fi
}

function addFiles {
    local MOV_DIR=$1
    local SHOT_NO=$2
    local ID=$3

    local f
    local suffix
    local description
    # should be only one file per suffix
    for suffix in mov mp4; do
        # Mnichov: ZF_0340_3900403_sot3_hd-master.mov
        # Galerie: 3901034_26_hd-master.mov
        find $MOV_DIR/ -type f \( -name "*sot${SHOT_NO}*.$suffix" -o -name "*_${SHOT_NO}_*.$suffix" \) | while read -r f; do
            if [ "FALSE" = "$MD_ONLY" ]; then
                cp $f $ID/
            else
                local n=$(basename $f)
                touch $ID/$n
            fi
            if [ "$suffix" = "mov" ]; then
                description="best quality"
            else
                description="lower quality"
            fi
            echo -e "$(basename $f)\tbundle:ORIGINAL\tdescription:$description" >> $ID/contents
        done
    done
}

function output2import {
    local OUTDIR=$1
    local MOV_DIR=$2
    pushd $OUTDIR
    local SHOT_COUNT=$(xmllint --xpath 'count(/root/item/dublin_core[@schema="dc"])' output.xml)
    # ZF not converted to item for now
    local i
    for i in $(seq 1 $SHOT_COUNT); do
        local IDENTIFIER=$(xmllint --xpath "/root/item[$i]/dublin_core[@schema='dc']/dcvalue[@element='identifier' and @qualifier='uri']/text()" output.xml)
        local ID=$(basename $IDENTIFIER)
        local HDL=$(basename $(dirname $IDENTIFIER))/$ID
        local SHOT_NO=${ID##*-*(0)}
        mkdir -p $ID
        xmllint --xpath "/root/item[$i]/dublin_core[@schema='dc']" output.xml | xmllint --encode UTF-8 --format - > $ID/dublin_core.xml
        local schema
        for schema in `xmllint --xpath '/root/item/dublin_core[@schema!="dc"]/@schema' output.xml | sed -e 's#schema=#\n#g' -e's#"##g' | tr -d ' ' | grep . |  sort -u`; do
            xmllint --xpath "/root/item[$i]/dublin_core[@schema='$schema']" output.xml| xmllint --encode UTF-8 --format - > $ID/metadata_$schema.xml
        done
        addFiles $MOV_DIR $SHOT_NO $ID
        echo "$HDL" > $ID/handle
        # todo license.txt?
    done
    rm output.xml
    popd
    mv -v $OUTDIR/* $OUTDIR/../
    rmdir $OUTDIR
}

function nfa2dspace {
    local i
    for i in $(ls $DATADIR/**/*.xml); do
        local NAME=$(basename ${i%%.xml})
        local OUTDIR=$TMP/$NAME
        local ZF_DIR=$(dirname $i)
        local AVAILABLE_SHOTS=$(getAvailableShots $ZF_DIR)
        if test -n "$(find $TMP -maxdepth 1 -type d -name ${NAME}* -print -quit)"; then
                echo "Skipping $NAME"
                continue
        fi
        mkdir -p $OUTDIR
        java -cp $CP net.sf.saxon.Transform -xsl:transformations/transform.xslt -s:$i -o:$OUTDIR/output.xml PREFIX=$PREFIX PROCESS_ONLY=$AVAILABLE_SHOTS CONTACT_PERSON="$CONTACT_PERSON"
        sanitycheck $OUTDIR/output.xml $ZF_DIR
        output2import "$OUTDIR" $ZF_DIR
    done
}

pushd $WD

nfa2dspace

popd

mv -v "$TMP" import

