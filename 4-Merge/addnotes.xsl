<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:functx="http://www.functx.com" xmlns:h="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0" exclude-result-prefixes="xsi">
    <xsl:include href="functions.xsl"/>
    <!-- Full path to the TMX file -->
    <xsl:param name="tmx" select="concat(substring-before(base-uri(),'.html'), '.tmx')"/> 
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes" encoding="UTF-8" doctype-public="-//W3C//DTD XHTML 1.1//EN" doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"/>
    <xsl:variable name="lang"><xsl:value-of select="/h:html/@xml:lang"/></xsl:variable>
    <xsl:variable name="segments">
        <xsl:if test="doc-available($tmx)">
            <xsl:for-each select="document($tmx)/tmx/body/tu/tuv[@xml:lang=$lang]/seg[1]">
                <!-- From the TMX, get texts longer than 5 characters -->
                <xsl:if test="string-length(text()[1]) &gt; 5">
                    <segment>
                        <!-- The rank attribute is the tu element position in the tmx body -->
                        <xsl:attribute name="rank"><xsl:value-of select="position()"/></xsl:attribute>
                        <xsl:value-of select="text()"/>
                    </segment>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:variable>
    <xsl:template match="/">
        <xsl:if test="not(doc-available($tmx))">
            <xsl:message>Info: The HTML file text could not be segmented, because no TMX file has been found at: <xsl:value-of select="$tmx"/></xsl:message>
        </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>
    <!-- For elements containing translated text -->
    <xsl:template match="h:h1|h:h2|h:h3|h:h4|h:p">
        <xsl:element name="{name()}" namespace="http://www.w3.org/1999/xhtml">
            <xsl:copy-of select="@*"/>
            <xsl:variable name="plaintext" select="string(.)"/>
            <!--xsl:value-of select="$plaintext"/-->
            <xsl:variable name="matchingsegments">
                <xsl:for-each select="$segments/segment">
                    <xsl:sort select="functx:index-of-string-first($plaintext,text())"/>
                    <xsl:if test="contains($plaintext,.)">
                        <matchingsegment>
                            <xsl:attribute name="rank"><xsl:value-of select="@rank"/></xsl:attribute>
                            <!-- The index attribute gives the starting character position of the matching segment within the plain text -->
                            <xsl:attribute name="index"><xsl:value-of select="functx:index-of-string-first($plaintext,text())"/></xsl:attribute>
                            <xsl:copy-of select="text()" copy-namespaces="no"/>
                        </matchingsegment>
                    </xsl:if>
                </xsl:for-each>
            </xsl:variable>
            <xsl:copy-of select="$matchingsegments"/>
            <!--xsl:apply-templates select="text()"/-->
        </xsl:element>
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
            <xsl:copy-of select="$segments" />
        </xsl:element>
    </xsl:template>
    <!-- For elements without child elements -->
    <xsl:template match="h:br|h:meta|h:title">
        <xsl:copy-of select="." copy-namespaces="no"/>
    </xsl:template>
    <!-- For other elements with child elements -->
    <xsl:template match="h:body|h:div"><xsl:copy copy-namespaces="no"><xsl:apply-templates select="@*|*"/></xsl:copy></xsl:template>
    <!-- Copy attributes -->
    <xsl:template match="@*"><xsl:copy select="."/></xsl:template>
    <!--xsl:template match="text()">
        <xsl:variable name="txt" select="."/>
        <xsl:if test="normalize-space()">HA<xsl:value-of select="."/></xsl:if>
    </xsl:template-->
</xsl:stylesheet>