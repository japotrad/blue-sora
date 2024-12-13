<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xhtml="http://www.w3.org/1999/xhtml" exclude-result-prefixes="xhtml" version="1.0">
    <xsl:output method="xml" indent="yes" encoding="UTF-8" doctype-system="furigana.dtd"/>
    <xsl:template match="/">
        <furigana>
            <xsl:apply-templates/>
        </furigana>
    </xsl:template>
    <xsl:template match="xhtml:p">
        <xsl:variable name="location"><xsl:value-of select="@id"/></xsl:variable>
        <xsl:apply-templates select="xhtml:ruby">
            <xsl:with-param name="location" select="$location"/>
        </xsl:apply-templates>
    </xsl:template>
    <xsl:template match="xhtml:ruby">
        <xsl:param name="location" />
        <xsl:element name="furi">
            <xsl:attribute name="location"><xsl:value-of select="$location"/></xsl:attribute>
            <xsl:attribute name="kanji"><xsl:value-of select="xhtml:rb"/></xsl:attribute>
            <xsl:attribute name="kana"><xsl:value-of select="xhtml:rt"/></xsl:attribute>
        </xsl:element>
    </xsl:template>
    <xsl:template match="xhtml:title" />
    <xsl:template match="text()"/>
</xsl:stylesheet>