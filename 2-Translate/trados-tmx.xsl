<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:sdl="http://sdl.com/FileTypes/SdlXliff/1.0" xmlns:tmx="http://www.lisa.org/tmx14"
    xmlns:xliff="urn:oasis:names:tc:xliff:document:1.2" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="sdl tmx xliff xs"
    version="2.0">
    <xsl:variable name="base-uri-radical" select="substring-before(base-uri(),'_trados')"/> <!-- URI to process truncated before _trados -->
    <xsl:param name="xliff" select="concat($base-uri-radical, '.sdlxliff')"/> <!-- Full path to the SDL XLIFF file -->
    <xsl:output method="xml" encoding="UTF-8" indent="no" omit-xml-declaration="no" doctype-public="-//LISA OSCAR:1998//DTD for Translation Memory eXchange//EN" doctype-system="tmx15.dtd"/>
    <xsl:variable name="translatorNotes" select="document($xliff)/xliff:xliff/sdl:doc-info/sdl:cmt-defs"/>
    <!-- Elephants<ph assoc="p" type="fnote"><sub>N.d.t: Big animal</sub></ph> are big. -->
    <xsl:template match="tmx">
        <xsl:element name="tmx" namespace="http://www.lisa.org/tmx14">
            <xsl:value-of select="$translatorNotes"/>
            <xsl:apply-templates />
        </xsl:element>
    </xsl:template>
    <xsl:template match="tu">
        <xsl:element name="tu" namespace="http://www.lisa.org/tmx14">
            <xsl:variable name="changedate"><xsl:value-of select="@changedate"/></xsl:variable>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="myattr" select="$changedate"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
