#!/usr/bin/awk -f

BEGIN{
        RS="\n\n\n";
        FS=": ";
        print "<dublin_core schema=\"dc\">";
}
END{
        # mandatory fixed value
        nqdc("type", "languageDescription");
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
        dcvalue("contributor", "author", $NF)
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

#TODO sanitazi value to be xml safe
function dcvalue(element, qualifier, value){
        print "<dcvalue element=\"" element "\" qualifier=\"" qualifier "\">" value  "</dcvalue>"
}
