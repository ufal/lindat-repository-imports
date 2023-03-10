#!/usr/bin/awk -f

BEGIN{
        FS=": ";
        print "<dublin_core schema=\"dc\">";
}
END{
        ### language processing is more complex; wait until the whole file is read
        languages()
        ### fixed values ###
        # mandatory
        nqdc("type", "languageDescription");
        nqdc("subject", "Wikitongues");
        print "</dublin_core>";
}

### XXX This must be near top as it uses getline and we want all the following rules to be triggered ###
/^Description/ {
        for(i=2;i<=NF;i++){
                d=d $i
        }
        cnt=1
        # Read until we find a line starting with Subject
        while(cnt){
                if ((getline tmp) > 0) {
                        if(match(tmp, /^Subject/)){
                                cnt=0
                                $0=tmp
                        } else {
                            d=d "\n" tmp
                        }
                } else {
                        print("unexpected EOF or error:", ERRNO) > "/dev/stderr"
                        exit 1
                }
        }
        switch (d) {
            case /Creative Common Attribution-NonCommercial 4.0 International License./:
                lic="CC BY-NC 4.0"
                value=gensub("\nThis video is licensed under a Creative Common Attribution-NonCommercial 4.0 International License. To download a copy, please contact hello@wikitongues.org.", "", "1", d)
                break
            case /Creative Commons Attribution-NonCommercial 4.0 International license./:
                lic="CC BY-NC 4.0"
                value=gensub("\nThis video is licensed under a Creative Commons Attribution-NonCommercial 4.0 International license. To download a copy, please contact hello@wikitongues.org.", "", "1", d)
                break
            case /Creative Commons Attribution-ShareAlike 4.0 International license./:
                lic="CC BY-SA 4.0"
                value=gensub("\nThis video is licensed under a Creative Commons Attribution-ShareAlike 4.0 International license. To download a copy, please contact hello@wikitongues.org.", "", "1", d)
                break
            default:
                value=d
                lic=""
        }
        nqdc("description", value)
}

/undefined/ {
        next;
}

/^Identifier/ {
        #print NR, NF, $NF
        dcvalue("identifier", "other", $NF)
        next;
}

/^Title/ {
        nqdc("title", $NF)
        next;
}

/^Creator/ {
        n=split($NF, creators, ",")
        for(i=1;i<=n;i++){
                dcvalue("identifier", "other", creators[i])
                split(creators[i], a, "_")
                # assume first_last_date
                dcvalue("contributor", "author", trim(a[2]) ", " trim(a[1]))
        }
        next;
}

$0 ~ /639-3/ && $0 !~ /Caption/ {
        # cf. END
        # this is triggered or multiple lines; hence the concat.
        # function languages() doesn't take that into account though...
        if(lang_iso){
            lang_iso = lang_iso "," $NF
        }else{
            lang_iso=$NF
        }
        next;
}

/^Language names/ {
        # cf. END
        lang_names=$NF
        next;
}

/^Rights/ {
        if(lic && $NF!=lic){
            print("ERROR: Rights don't match description: ", $NF, " vs. ", lic) > "/dev/stderr"
            exit 1
        }
        switch ($NF) {
            case "CC BY-NC 4.0":
                dcvalue("rights", "uri", "http://creativecommons.org/licenses/by-nc/4.0/")
                dcvalue("rights", "label", "PUB")
                nqdc("rights", "Creative Commons - Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)")
                break
             case "CC BY-SA 4.0":
                dcvalue("rights", "uri", "http://creativecommons.org/licenses/by-sa/4.0/")
                dcvalue("rights", "label", "PUB")
                nqdc("rights", "Creative Commons - Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)")
                break
             default:
                print "ERROR: No mapping for license " $NF > "/dev/stderr"
                exit 1
        }
        next;
}

/^Publisher/ {
        nqdc("publisher", $NF);
        next;
}

/^Subject:.*Origin/ || /^Subject:.*logy per language/ {
        print "Ignoring field no. " NR ": " $0 > "/dev/stderr"
        next;
}

/^Subject:/ {
        val_prefix=""
        for(i=2;i<NF;i++){
                val_prefix=$i "::"
        }
        val=$NF
        split_value_nqdc("subject", val, val_prefix);
        val="";
        next;
}

/^Languages.*preferred/ {
        split_value_nqdc("subject", $NF);
        next;
}

/Glottocode/ {
        split_value_nqdc("subject", $NF, "Glottocode::");
        next;
}

/^Date Received/ {
        dcvalue("date", "issued", $NF);
        next;
}

# skip first line, it's a heading
NR>1{
        print "No mapping for field no. " NR ": " $0 > "/dev/stderr"
        next;
}

# m, n, codes, names, i, code are local variables
function languages(    m, n, codes, names, i, code){
        m=split(lang_iso, codes, /(,| and )/)
        n=split(lang_names, names, /(,| and )/)
        for(i=1;i<=m;i++){
            code=trim(codes[i])
            switch(code){
                case /^w...$/:
                    if(m!=n){
                        print "ERROR: On language code " code " no human readable name found" > "/dev/stderr"
                        exit 1
                    }
                    # uncoded language
                    dcvalue("language", "iso", "mis")
                    # add the human readable name as dc.language
                    nqdc("language", names[i])
                    # use the wikitongues code as subject
                    nqdc("subject", code)
                    break
                case /^...$/:
                    dcvalue("language", "iso", code)
                    break
                default:
                    print "ERROR: On language code " code > "/dev/stderr"
                    exit 1

            }
        }
}

function trim(what){
        value=gensub("^[[:space:]]*", "", "1", what)
        return gensub("[[:space:]]*$", "", "1", value)
}

function split_value_nqdc(element, value, value_prefix){
        split_value_dcvalue(element, "none", value, value_prefix)
}

# n, a, i are local variables 
function split_value_dcvalue(element, qualifier, value, value_prefix,    n, a, i){
        n=split(value, a, /(,| and )/)
        for(i=1;i<=n;i++){
            dcvalue(element, qualifier, a[i], value_prefix)
        }
}

# value_prefix is optional
function nqdc(element, value, value_prefix){
        dcvalue(element, "none", value, value_prefix)
}

# value_prefix is optional
function dcvalue(element, qualifier, value, value_prefix){
        value=gensub(">", "\\&gt;", "g", value)
        value=gensub("<", "\\&lt;", "g", value)
        value=gensub("&", "\\&amp;", "g", value)
        value=trim(value)

        if(element!="description"){
                value=gensub("\"", "", "g", value)
        }

        print "<dcvalue element=\"" element "\" qualifier=\"" qualifier "\">" value_prefix value  "</dcvalue>"
}
