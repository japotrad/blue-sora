<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:h="http://www.w3.org/1999/xhtml"
    xmlns:r="https://github.com/japotrad/blue-sora/ris"
    xmlns:f="https://github.com/japotrad/blue-sora/furigana"
    exclude-result-prefixes="xs h r f"
    version="2.0">
    <xsl:param name="furi" select="concat(substring-before(base-uri(),'ja.html'),'furigana.html')"/> <!-- Full path to the furigana file -->
    <xsl:param name="note" select="concat(substring-before(base-uri(),'ja.html'),'note.xml')"/> <!-- Full path to the furigana file -->
    <xsl:param name="lang" select="'en'"/><!-- 2-letter code of the language the document has been translated into -->
    <xsl:param name="trans" select="concat(substring-before(base-uri(),'ja.html'),$lang,'.html')"/> <!-- Full path to the translated HTML file in the above language -->
    <xsl:param name="tmx" select="concat(substring-before(base-uri(),'ja.html'),$lang,'.tmx')"/> <!-- Full path to the translation memory file -->
    <xsl:param name="preface" select="concat(substring-before(base-uri(),'ja.html'),$lang,'-preface.html')"/> <!-- Full path to the preface file in the above language -->
    <xsl:param name="ris" select="concat(substring-before(base-uri(),'ja.html'),$lang,'-ris.xml')"/> <!-- Full path to the RIS XML file -->
    <xsl:variable name="merge_param" select="concat(resolve-uri('.'),'merge-',$lang,'.xml')"/> <!-- Full path to the parameter file containing the localized strings for this XSL stylesheet -->
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>
    
    <xsl:template match="/">
        <book>
           <xsl:attribute name="xml:lang"><xsl:value-of select="$lang"/></xsl:attribute>
           <xsl:call-template name="info"/>
        </book>
    </xsl:template>
    <xsl:template name="info">
        <xsl:variable name="risDoc" select="document($ris)"/>
        <info>
            <title>
                <xsl:copy-of select="$risDoc/r:ris/r:TI/text()"/>
                <foreignphrase role="source" xml:lang="ja"><xsl:value-of select="h:html/h:body/h:h1[@class='title']"/></foreignphrase>
            </title>
        </info>
    </xsl:template>
    
</xsl:stylesheet>