#!/usr/bin/awk -f

BEGIN{
        RS="\n\n\n";
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

/^Description/ {
        nqdc("description", $NF)
        next;
}

/639-3/ {
        dcvalue("language", "iso", $NF)
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
        nqdc("subject", "Glottocode::" $NF);
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


function nqdc(element, value){
        dcvalue(element, "none", value)
}

function dcvalue(element, qualifier, value){
        value=gensub(">", "\\&gt;", "g", value)
        value=gensub("<", "\\&lt;", "g", value)
        value=gensub("&", "\\&amp;", "g", value)

        if(element!="description"){
                value=gensub("\"", "", "g", value)
        }

        print "<dcvalue element=\"" element "\" qualifier=\"" qualifier "\">" value  "</dcvalue>"
}
