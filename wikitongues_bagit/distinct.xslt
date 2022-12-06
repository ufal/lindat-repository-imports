<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:set="http://exslt.org/sets" version="1.0">
  <xsl:output method="xml" encoding="UTF-8"/>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="dublin_core">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:for-each select="set:distinct(dcvalue/@element)">
        <xsl:variable name="curr_element" select="."/>
        <xsl:for-each select="set:distinct(//dcvalue[@element=$curr_element]/@qualifier)">
          <xsl:variable name="curr_qualifier" select="."/>
          <xsl:apply-templates select="set:distinct(//dcvalue[@element=$curr_element and @qualifier=$curr_qualifier])"/>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
