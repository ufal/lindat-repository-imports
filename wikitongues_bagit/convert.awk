#!/usr/bin/awk -f

BEGIN{
        FS=": ";
        print "<dublin_core schema=\"dc\">";
}
END{
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
                        exit
                }
        }
        value=gensub("\nThis video is licensed under a Creative Commons Attribution-NonCommercial 4.0 International license. To download a copy, please contact hello@wikitongues.org.", "", "1", d)
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
        dcvalue("identifier", "other", $NF)
        split($NF, a, "_")
        # assume first_last_date
        dcvalue("contributor", "author", a[2] ", " a[1])
        next;
}

$0 ~ /639-3/ && $0 !~ /Caption/ {
        split_value_dcvalue("language", "iso", $NF)
        next;
}

/^Rights/ {
        if($NF="CC BY-NC 4.0"){
                dcvalue("rights", "uri", "http://creativecommons.org/licenses/by-nc/4.0/")
                dcvalue("rights", "label", "PUB")
                nqdc("rights", "Creative Commons - Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)")
        }else{
                print "No mapping for license " $NF > "/dev/stderr"
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
        for(i=2;i<=NF;i++){
                if(val){
                        val=val "::" $i;
                }else{
                        val=$i;
                }

        }
        nqdc("subject", val);
        val="";
        next;
}

/^Languages.*preferred/ {
        nqdc("subject", $NF);
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

function split_value_nqdc(element, value, value_prefix){
        split_value_dcvalue(element, "none", value, value_prefix)
}

# n, a, i are local variables 
function split_value_dcvalue(element, qualifier, value, value_prefix,    n, a, i){
        n=split(value, a, ",")
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
        value=gensub("^[[:space:]]*", "", "1", value)
        value=gensub("[[:space:]]*$", "", "1", value)

        if(element!="description"){
                value=gensub("\"", "", "g", value)
        }

        print "<dcvalue element=\"" element "\" qualifier=\"" qualifier "\">" value_prefix value  "</dcvalue>"
}
