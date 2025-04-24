<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet  xmlns:h="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0" exclude-result-prefixes="xsi">
    <!-- Full path to the TMX file -->
    <xsl:param name="tmx" select="concat(substring-before(base-uri(),'.html'), '.tmx')"/> 
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes" encoding="UTF-8" doctype-public="-//W3C//DTD XHTML 1.1//EN" doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"/>
    <xsl:variable name="lang"><xsl:value-of select="/h:html/@xml:lang"/></xsl:variable>
    <xsl:variable name="segments">
        <xsl:if test="doc-available($tmx)">
            <xsl:for-each select="document($tmx)/tmx/body/tu/tuv[@xml:lang=$lang]/seg[1]">
                <segment>
                    <xsl:attribute name="rank"><xsl:value-of select="position()"/></xsl:attribute>
                    <xsl:value-of select="text()"/>
                </segment>
            </xsl:for-each>
        </xsl:if>
    </xsl:variable>
    <xsl:template match="/">
        <xsl:if test="not(doc-available($tmx))">
            <xsl:message>Info: The HTML file text could not be segmented, because no TMX file has been found at: <xsl:value-of select="$tmx"/></xsl:message>
        </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="h:html">
        <xsl:element name="html" namespace="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="lang"><xsl:value-of select="@lang"/></xsl:attribute>
            <xsl:attribute name="xml:lang"><xsl:value-of select="@xml:lang"/></xsl:attribute>
            <xsl:apply-templates />
        </xsl:element>
    </xsl:template>
    <xsl:template match="h:head">
        <xsl:element name="head" namespace="http://www.w3.org/1999/xhtml">
            <xsl:apply-templates />
            <xsl:copy-of select="$segments"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="h:title">
        <xsl:copy-of select="." copy-namespaces="no"/>
    </xsl:template>
    <xsl:template match="h:*|@*"><xsl:copy copy-namespaces="no"><xsl:apply-templates select="@*|node()"/></xsl:copy></xsl:template>
    <xsl:template match="text()"><xsl:if test="normalize-space()">HA<xsl:value-of select="."/></xsl:if></xsl:template>
</xsl:stylesheet>