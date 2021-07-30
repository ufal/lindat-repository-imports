<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     xmlns:xs="http://www.w3.org/2001/XMLSchema" 
     exclude-result-prefixes="xs" version="3.0">
     <xsl:output method="xml" indent="yes" encoding="UTF-8" />

     <xsl:param name="PREFIX" select="'$PREFIX'"/>
     <xsl:param name="PROCESS_ONLY" select="'-1'"/>
     <xsl:param name="CONTACT_PERSON" />

     <!-- if PROCESS_ONLY unspecified (-1) process all -->
     <xsl:variable name="PROCESS_ONLY_IDS">
          <xsl:choose>
               <xsl:when test="$PROCESS_ONLY='-1'"><xsl:value-of select="string-join(/FILM/SOT-ZF/CISLO-SOTU/text(),';')"/></xsl:when>
               <xsl:otherwise><xsl:value-of select="$PROCESS_ONLY"></xsl:value-of></xsl:otherwise>
          </xsl:choose>
     </xsl:variable>

     <xsl:variable name="ZF_PID" select="concat($PREFIX, '/', /FILM/FILMID)"/>
     <xsl:variable name="ZF_ID" select="/FILM/FILMID"/>

     <xsl:variable name="ROOT" select="/"/>

     <xsl:template match="/">
          <root>
               <ids>
                    <id><xsl:value-of select="$ZF_PID"/></id>
                    <xsl:for-each select="/FILM/SOT-ZF/CISLO-SOTU">
                         <id><xsl:value-of select="concat($ZF_PID, '-' ,.)"/></id>
                    </xsl:for-each>
               </ids>
               <xsl:for-each select="tokenize($PROCESS_ONLY_IDS, ';')">
                    <!-- for-each operates on a sequence of string value (i.e. inside the for-each body the context item is a string value)
                         that's why we need $ROOT
                         Don't know why we need variable value-of; but not working without it
                     -->
                    <xsl:variable name="cislo"><xsl:value-of select="."></xsl:value-of></xsl:variable>
                    <xsl:apply-templates select="$ROOT/FILM/SOT-ZF[CISLO-SOTU/text()=$cislo]"/>
               </xsl:for-each>
          </root>
     </xsl:template>
     

     <xsl:template match="/FILM/SOT-ZF">
          <xsl:variable name="PADDED_NO" select="format-integer(CISLO-SOTU, '00')"/>   
          <xsl:variable name="SHOT_PID" select="concat($ZF_PID, '-', $PADDED_NO)"/>
          <xsl:variable name="SHOT_ID" select="concat($ZF_ID, '-', $PADDED_NO)"/>
          <xsl:variable name="issued">
                         <xsl:choose>
                              <xsl:when test="ROK-VYROBY-SOTU/text()">
                                   <xsl:value-of select="ROK-VYROBY-SOTU"/>
                              </xsl:when>
                              <xsl:otherwise>
                                   <xsl:value-of select="DAT-VYROBY-SOTU"/>
                              </xsl:otherwise>
                         </xsl:choose>
          </xsl:variable>
          <item>
               <dublin_core schema="dc">
                    <!-- dc.title TODO: NAZEV-SKUT-SOTU NAZEV-ORIG-SOTU NAZEV-SOTU-ANGL -->
                    <xsl:call-template name="dcvalue">
                         <xsl:with-param name="element" select="'title'"/>
                         <xsl:with-param name="value" select="NAZEV-SOTU-ANGL"/>
                    </xsl:call-template>
                    <!-- dc.identifier.uri handle should go also to `handle` file -->
                    <xsl:call-template name="dcvalue">
                         <xsl:with-param name="element" select="'identifier'"/>
                         <xsl:with-param name="qualifier" select="'uri'"/>
                         <xsl:with-param name="value" select="concat('http://hdl.handle.net/', $SHOT_PID)"/>
                    </xsl:call-template>
                    <xsl:call-template name="dcvalue">
                         <xsl:with-param name="element" select="'identifier'"/>
                         <xsl:with-param name="qualifier" select="'other'"/>
                         <xsl:with-param name="value" select="$SHOT_ID"/>
                    </xsl:call-template>
                    <xsl:call-template name="dcvalue">
                         <xsl:with-param name="element" select="'description'"/>
                         <xsl:with-param name="value" select="OBSAH-SOTU-ANGL"/>
                    </xsl:call-template>
                    <xsl:for-each select="KLIC-SLOVO-SOTU">
                         <xsl:call-template name="dcvalue">
                              <xsl:with-param name="element" select="'subject'"/>
                              <xsl:with-param name="value" select="."/>
                         </xsl:call-template>
                    </xsl:for-each>
                    <!-- Fixed subject value, ensures there's at least one subject -->
                    <xsl:call-template name="dcvalue">
                              <xsl:with-param name="element" select="'subject'"/>
                              <xsl:with-param name="value" select="'Mnichovská dohoda'"/>
                    </xsl:call-template>
                    <xsl:call-template name="dcvalue">
                              <xsl:with-param name="element" select="'contributor'"/>
                              <xsl:with-param name="qualifier" select="'author'"/>
                              <xsl:with-param name="value">
                                   <xsl:choose>
                                        <xsl:when test="VYROBCE-SOTU/text()">
                                             <xsl:value-of select="VYROBCE-SOTU"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                             <xsl:value-of select="'(:unav) Unknown author'"/>
                                        </xsl:otherwise>
                                   </xsl:choose>
                              </xsl:with-param>
                    </xsl:call-template>
                    <!-- <xsl:copy-of select="." />-->
                    <xsl:call-template name="exteriery">
                         <xsl:with-param name="cislo_sotu" select="CISLO-SOTU"/>
                    </xsl:call-template>
                    <xsl:call-template name="osobnosti">
                         <xsl:with-param name="cislo_sotu" select="CISLO-SOTU"/>
                    </xsl:call-template>
                    <!-- dc.type clip; media, type video (in metashare) -->
                    <xsl:call-template name="dcvalue">
                              <xsl:with-param name="element" select="'type'"/>
                              <xsl:with-param name="value" select="'clip'"/>
                    </xsl:call-template>
                    <xsl:call-template name="dcvalue">
                              <xsl:with-param name="element" select="'publisher'"/>
                              <xsl:with-param name="value" select="'Národní filmový archiv'"/>
                    </xsl:call-template>

                    <!-- date.issued shortened to just year, ie. from yyyy-mm-dd to just yyyy -->
                    <xsl:call-template name="dcvalue">
                              <xsl:with-param name="element" select="'date'"/>
                              <xsl:with-param name="qualifier" select="'issued'"/>
                              <xsl:with-param name="value">
                                      <xsl:choose>
                                              <xsl:when test="contains($issued, '-')">
                                                      <xsl:value-of select="substring-before($issued, '-')"/>
                                              </xsl:when>
                                              <xsl:otherwise>
                                                      <xsl:value-of select="$issued"/>
                                              </xsl:otherwise>
                                      </xsl:choose>
                              </xsl:with-param>
                    </xsl:call-template>
                    <!-- /date.issued -->

                    <xsl:call-template name="dcvalue">
                              <xsl:with-param name="element" select="'rights'"/>
                              <xsl:with-param name="qualifier" select="'uri'"/>
                              <xsl:with-param name="value" select="'http://creativecommons.org/licenses/by-nc-nd/4.0/'"/>
                    </xsl:call-template>

                    <xsl:apply-templates select="VERZE-SOTU"/>
                    <xsl:apply-templates select="PUVOD-SOTU"/>
               </dublin_core>
               <dublin_core schema="metashare">
                    <xsl:call-template name="dcvalue">
                              <xsl:with-param name="element" select="'ResourceInfo#ContentInfo'"/>
                              <xsl:with-param name="qualifier" select="'mediaType'"/>
                              <xsl:with-param name="value" select="'video'"/>
                    </xsl:call-template>
               </dublin_core>
               <dublin_core schema="local">
                    <xsl:call-template name="dcvalue">
                              <xsl:with-param name="element" select="'contact'"/>
                              <xsl:with-param name="qualifier" select="'person'"/>
                              <xsl:with-param name="value" select="$CONTACT_PERSON"/>
                    </xsl:call-template>

                    <xsl:variable name="refboxFMT">
                            <xsl:variable name="author">
                                    <xsl:choose>
                                            <xsl:when test="VYROBCE-SOTU/text()">
                                                    <xsl:value-of select="'{authors}, '"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                    <xsl:value-of select="''"/>
                                            </xsl:otherwise>
                                    </xsl:choose>
                            </xsl:variable>
                            <xsl:variable name="year">
                                    <xsl:choose>
                                            <xsl:when test="not(contains($issued,'0000'))">
                                                    <xsl:value-of select="'{year}, '"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                    <xsl:value-of select="''"/>
                                            </xsl:otherwise>
                                    </xsl:choose>
                            </xsl:variable>
                            <xsl:value-of select="concat('{title}, ', $author, $year, '{publisher}, ', '{repository}, ', '{pid}.')"/>
                    </xsl:variable>
                    <xsl:call-template name="dcvalue">
                              <xsl:with-param name="element" select="'refbox'"/>
                              <xsl:with-param name="qualifier" select="'format'"/>
                              <xsl:with-param name="value" select="$refboxFMT"/>
                    </xsl:call-template>
               </dublin_core>
          </item>
     </xsl:template>

     <xsl:template name="exteriery">
         <xsl:param name="cislo_sotu"/> 
         <xsl:for-each select="/FILM/EXTERIER/EXT-CIS-SOTU[text()=$cislo_sotu]/..">
               <xsl:call-template name="dcvalue">
                    <xsl:with-param name="element" select="'subject'"/>
                    <xsl:with-param name="value" select="concat('Places::', replace(replace(replace(EXT-TEXT, ':', '::'), ',', '::'), '/ext.::', '/ext.,'))"/>
               </xsl:call-template>
         </xsl:for-each>
     </xsl:template>

     <xsl:template name="osobnosti">
         <xsl:param name="cislo_sotu"/> 
         <xsl:for-each-group select="/FILM/OSOBNOST/CISLOSOTU[text()=$cislo_sotu]/.." group-by="PRIJMENIJMENO">
                    <xsl:call-template name="dcvalue">
                         <xsl:with-param name="element" select="'subject'"/>
                         <!-- TODO: "Prijmeni, Jmeno" at jsme konzistenti s autorama, ale ono je to asi jedno, hazim to na hromadu keywords-->
                         <xsl:with-param name="value" select="concat('People::', PRIJMENIJMENO)"/>
                    </xsl:call-template>
         </xsl:for-each-group>
     </xsl:template>

     <xsl:template name="dcvalue">
          <xsl:param name="element"/>
          <xsl:param name="qualifier" select="'none'"/>
          <xsl:param name="value"/>

          <xsl:if test="$value!=''">
               <xsl:element name="dcvalue">
                    <xsl:attribute name="element"><xsl:value-of select="$element"/></xsl:attribute>
                    <xsl:attribute name="qualifier"><xsl:value-of select="$qualifier"/></xsl:attribute>
               <xsl:value-of select="$value"/>
               </xsl:element>
          </xsl:if>
     </xsl:template>

     <xsl:template match="VERZE-SOTU">
             <xsl:variable name="cislo_verze" select="format-integer(., '000')"/>
             <xsl:call-template name="verze2language">
                     <xsl:with-param name="cislo_verze" select="$cislo_verze"/>
             </xsl:call-template>
     </xsl:template>

     <xsl:template name="verze2language">
         <xsl:param name="cislo_verze"/> 
         <xsl:variable name="iso_code">
                 <!-- TODO maybe sound / no sound as subject? -->
             <xsl:choose>
                     <xsl:when test="$cislo_verze='001'">
                             <xsl:value-of select="'ces'"/>
                     </xsl:when>
                     <xsl:when test="$cislo_verze='010'">
                             <xsl:value-of select="'slk'"/>
                     </xsl:when>
                     <xsl:when test="$cislo_verze='220'">
                             <xsl:value-of select="'deu'"/>
                     </xsl:when>
                     <xsl:when test="$cislo_verze='410'">
                             <!-- nemy -->
                             <xsl:value-of select="'zxx'"/>
                     </xsl:when>
                     <xsl:when test="$cislo_verze='430'">
                             <!-- zvuk bez dialogu -->
                             <xsl:value-of select="'zxx'"/>
                     </xsl:when>
                     <xsl:when test="$cislo_verze='440'">
                             <!-- prazdna zvukova stopa -->
                             <xsl:value-of select="'zxx'"/>
                     </xsl:when>
                     <xsl:otherwise>
                             <xsl:value-of select="'null'"/>
                             <xsl:message>WARN: Failed to convert cislo_verze '<xsl:value-of select="$cislo_verze"/>' in '<xsl:value-of select="$ZF_ID"/>' </xsl:message>
                     </xsl:otherwise>
             </xsl:choose>
         </xsl:variable>
         <!-- <xsl:message>DEBUG: converted cislo_verze '<xsl:value-of select="$cislo_verze"/>' to '<xsl:value-of select="$iso_code"/>' </xsl:message> -->
         <xsl:if test="$iso_code!='null'">
                 <xsl:call-template name="dcvalue">
                         <xsl:with-param name="element" select="'language'"/>
                         <xsl:with-param name="qualifier" select="'iso'"/>
                         <xsl:with-param name="value" select="$iso_code"/>
                 </xsl:call-template>
         </xsl:if>
     </xsl:template>

     <xsl:template match="PUVOD-SOTU">
        <xsl:variable name="val">
                <xsl:choose>
                        <xsl:when test="contains(., 'Aktualita')">
                                <xsl:value-of select="replace(., 'Aktualita ', 'Aktualita::')"/>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:value-of select="."/>
                        </xsl:otherwise>
                </xsl:choose>
        </xsl:variable>
        <xsl:call-template name="dcvalue">
                 <xsl:with-param name="element" select="'subject'"/>
                 <xsl:with-param name="value" select="$val"/>
        </xsl:call-template>
     </xsl:template>
</xsl:stylesheet>
