<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xhtml="http://www.w3.org/1999/xhtml" version="1.0">
    <xsl:strip-space elements="*"/>
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes" encoding="UTF-8" doctype-public="-//W3C//DTD XHTML 1.1//EN" doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"/>
    <xsl:template match="xhtml:link"/>
    <xsl:template match="xhtml:head">
        <xsl:element name="head" namespace="http://www.w3.org/1999/xhtml">
            <xsl:apply-templates />
        </xsl:element>
    </xsl:template>
	<xsl:template match="xhtml:html">
        <xsl:element name="html" namespace="http://www.w3.org/1999/xhtml">
		    <xsl:attribute name="lang">ja</xsl:attribute>
			<xsl:attribute name="xml:lang">ja</xsl:attribute>
            <xsl:apply-templates />
        </xsl:element>
    </xsl:template>
    <xsl:template match="xhtml:label"/><!-- Remove Aozora Bunko note -->
    <xsl:template match="xhtml:ruby"><!-- Remove furigana -->
        <xsl:value-of select="xhtml:rb"/>
    </xsl:template>
    <xsl:template match="xhtml:script"/>
    <xsl:template match="@* | text() | comment() | processing-instruction()">
        <xsl:copy/>
    </xsl:template>
    
    <xsl:template match="*">
        <xsl:element name="{name()}" namespace="{namespace-uri()}">
            <xsl:apply-templates select="@* | node()"/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>