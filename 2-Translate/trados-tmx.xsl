<?xml version="1.0" encoding="UTF-8"?>
<!-- Not supported: Non-empty inline bpt, ept, hi and it tags -->
<xsl:stylesheet xmlns:functx="http://www.functx.com" xmlns:sdl="http://sdl.com/FileTypes/SdlXliff/1.0"
    xmlns:xliff="urn:oasis:names:tc:xliff:document:1.2" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">
    <xsl:include href="functions.xsl"/>
    <xsl:variable name="base-uri-radical" select="substring-before(base-uri(),'_trados')"/> <!-- URI to process truncated before _trados -->
    <xsl:param name="xliff" select="concat($base-uri-radical, '.sdlxliff')"/> <!-- Full path to the SDL XLIFF file -->
    <xsl:output method="xml" encoding="UTF-8" indent="no" omit-xml-declaration="no" doctype-public="-//LISA OSCAR:1998//DTD for Translation Memory eXchange//EN" doctype-system="tmx15.dtd"/>
    <xsl:variable name="srclang" select="/tmx/header/@srclang"/> <!-- Expected value: ja-JP -->
    <xsl:variable name="translatorNotes" select="document($xliff)/xliff:xliff/sdl:doc-info/sdl:cmt-defs"/>
    <xsl:template match="tmx">
        <xsl:element name="tmx">
            <xsl:attribute name="version">1.4</xsl:attribute>
            <xsl:apply-templates />
        </xsl:element>
    </xsl:template>
    <xsl:template match="tu">
        <xsl:element name="tu"> <!-- Joint to the XLIFF fragments using the last modification date: tu@changedate==trans-unit/sdl:seg-defs/sdl:seg-def/sdl:value[@key='modified_on'] -->
            <xsl:variable name="changedate"><xsl:value-of select="concat(substring(@changedate,5,2),'/',substring(@changedate,7,2),'/',substring(@changedate, 1,4),' ',substring(@changedate,10,2),':',substring(@changedate,12,2),':',substring(@changedate,14,2))"/></xsl:variable>
            <xsl:variable name="transunit"><xsl:copy-of select="document($xliff)/xliff:xliff/xliff:file/xliff:body/xliff:group/xliff:trans-unit[sdl:seg-defs/sdl:seg/sdl:value[@key='modified_on']=$changedate]"/></xsl:variable>
            <xsl:variable name="segid"><xsl:value-of select="$transunit/xliff:trans-unit/sdl:seg-defs/sdl:seg[sdl:value[@key='modified_on']=$changedate]/@id"/></xsl:variable>
            <xsl:variable name="notes"><!-- Parts of the target segment that are highlighted in Trados Studio, along with their corresponding comments -->
                <xsl:for-each select="$transunit/xliff:trans-unit/xliff:target/xliff:mrk[@mtype='seg' and @mid=$segid]//xliff:mrk[@mtype='x-sdl-comment']">
                    <xsl:variable name="beforecallout"><xsl:value-of select="$transunit/xliff:trans-unit/xliff:target/xliff:mrk[@mtype='seg' and @mid=$segid]//xliff:mrk[@mtype='x-sdl-comment']/preceding::text()[1]"/></xsl:variable> <!-- Part of the segment preceding the callout -->
                    <xsl:variable name="calloutrank"><xsl:value-of select="max((1, count(tokenize($beforecallout, functx:escape-for-regex(current())))))"/></xsl:variable><!-- Among all occurrences of the callout text within the segment, what is the rank of the actual callout? Should be 1 in most cases. -->
                    <xsl:element name="note">
                        <xsl:attribute name="rank" select="$calloutrank"/><!-- Among all occurrences of the callout text within the segment, what is the rank of the actual callout? Should be 1 in most cases. -->
                        <xsl:element name="callout"><xsl:value-of select="current()"/></xsl:element>
                        <xsl:element name="ph"><!-- The note -->
                            <xsl:attribute name="assoc">p</xsl:attribute>
                            <xsl:attribute name="type">fnote</xsl:attribute>
                            <xsl:element name="sub">
                                <xsl:value-of select="$translatorNotes/sdl:cmt-def[@id=current()/@sdl:cid]/sdl:Comments/sdl:Comment"/>
                            </xsl:element>
                        </xsl:element>
                    </xsl:element>
                </xsl:for-each>
            </xsl:variable>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="prop"/>
            <xsl:apply-templates select="tuv[@xml:lang=$srclang]"/><!-- Copy the source language segment unchanged -->
            <xsl:element name="tuv"><!-- Target language segment -->
                <xsl:attribute name="xml:lang" select="tuv[@xml:lang!=$srclang]/@xml:lang"/>
                <xsl:variable name="targetseg"><xsl:copy-of select="tuv[@xml:lang!=$srclang]/seg"/></xsl:variable>
                <xsl:if test="$notes=''"> <!-- General case: The translator has not added any note => Copy the segment unchanged -->
                    <xsl:copy-of select="$targetseg"/>
                </xsl:if>
                <xsl:if test="$notes!=''"><!-- The translator has added one (or more) note -->
                    <xsl:element name="seg">
                        <xsl:call-template name="addnotes">
                            <xsl:with-param name="notes" select="$notes"/>
                            <xsl:with-param name="seg" select="tuv[@xml:lang!=$srclang][1]/seg[1]"/>
                        </xsl:call-template>
                    </xsl:element>
                </xsl:if>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template name="addnotes"><!-- Recursion is needed if there is more than 1 note in the target segment -->
        <xsl:param name="notes"/>
        <xsl:param name="seg"/>
        <xsl:variable name="enrichedseg"><!-- Target language tuv enriched with marker tags just after the 1st note callout occurrences. -->
            <xsl:call-template name="addnote">
                <xsl:with-param name="nodes" select="$seg"/>
                <xsl:with-param name="tomatch" select="$notes/note[1]/callout/text()"/>
                <xsl:with-param name="rank" select="number($notes/note[1]/@rank)"/>
                <xsl:with-param name="matchedsofar" select="''"/>
                <xsl:with-param name="textsofar" select="''"/>
                <xsl:with-param name="note" select="$notes/note[1]/ph"/>
            </xsl:call-template>
        </xsl:variable>   
        <xsl:if test="count($notes/note)=1"> <!-- Only one highlighted part in Trados Studio -->
            <xsl:copy-of select="$enrichedseg"/>
        </xsl:if>
        <xsl:if test="count($notes/note) &gt; 1"> <!-- Several highlighted parts in Trados Studio -->
            <xsl:variable name="nextnotes"> <!-- Remove the 1st callout -->
                <xsl:for-each select="$notes/note">
                    <xsl:if test="position()>1">
                        <xsl:copy-of select="current()"/>
                    </xsl:if> 
                </xsl:for-each>
            </xsl:variable>
            <xsl:call-template name="addnotes">
                <xsl:with-param name="notes" select="$nextnotes"/>
                <xsl:with-param name="seg" select="$enrichedseg"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    <xsl:template name="addnote"><!-- Add the note the rank occurrence of the string tomatch in mixed content nodes -->
        <!-- Recursion is needed if there is more than one occurrence of the tomatch text -->
        <xsl:param name="nodes"/>
        <xsl:param name="tomatch"/>
        <xsl:param name="rank"/>
        <xsl:param name="matchedsofar"/>
        <xsl:param name="textsofar"/>
        <xsl:param name="note"/>
        <xsl:if test="$nodes//text()=''">
            <xsl:copy-of select="$nodes" />
        </xsl:if>
        <xsl:if test="$nodes//text()!=''">
            <xsl:variable name="nextnodes">
                <xsl:for-each select="$nodes/node()">
                    <xsl:if test="position()>1">
                        <xsl:copy-of select="current()"/>
                    </xsl:if> 
                </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="firstnode" select="$nodes/child::node()[1]"/>
            <xsl:choose>
                <xsl:when test="exists($firstnode/self::*) and not(has-children($firstnode))"> <!-- 1st child node is ... an empty element -->
                    <xsl:copy-of select="$firstnode"/>
                    <xsl:call-template name="addnote">
                        <xsl:with-param name="nodes" select="$nextnodes"/>
                        <xsl:with-param name="tomatch" select="$tomatch"/>
                        <xsl:with-param name="rank" select="$rank"/>
                        <xsl:with-param name="matchedsofar" select="$matchedsofar"/>
                        <xsl:with-param name="textsofar" select="$textsofar"/>
                        <xsl:with-param name="note" select="$note"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="exists($firstnode/self::text())"> <!-- ... a text -->
                    <xsl:variable name="stringunderprocessing" select="$firstnode/self::text()"/>
                    <xsl:variable name="candidate" select="concat($matchedsofar, $stringunderprocessing)"/>
                    <xsl:variable name="rankmatches" select="functx:number-of-matches($textsofar, functx:escape-for-regex($tomatch)) + 1 = $rank"/>
                    <xsl:if test="contains($candidate, $tomatch)"> <!-- Hit found -->
                        <xsl:variable name="pos" select="string-length(substring-before($candidate, $tomatch)) + string-length($tomatch) - string-length($matchedsofar)"/>
                        <xsl:value-of select="substring($stringunderprocessing, 1, $pos)"/>
                        <xsl:if test="$rankmatches">
                            <xsl:copy-of select="$note"/><!-- Write out the note -->
                        </xsl:if>
                        <xsl:value-of select="substring($stringunderprocessing,$pos+1)"/>
                        <xsl:if test="$rankmatches">
                            <xsl:copy-of select="$nextnodes"/>
                        </xsl:if>
                        <xsl:if test="not($rankmatches)">
                            <xsl:call-template name="addnote">
                                <xsl:with-param name="nodes" select="$nextnodes"/>
                                <xsl:with-param name="tomatch" select="$tomatch"/>
                                <xsl:with-param name="rank" select="$rank"/>
                                <xsl:with-param name="matchedsofar" select="''"/>
                                <xsl:with-param name="textsofar" select="concat($textsofar, $stringunderprocessing)"/>
                                <xsl:with-param name="note" select="$note"/>
                            </xsl:call-template>
                        </xsl:if>
                    </xsl:if>
                    <xsl:if test="not(contains($candidate, $tomatch))"> <!-- No hit -->
                        <xsl:if test="contains($tomatch,$candidate)"> <!-- There is still a chance for a future hit with a longer candidate -->
                            <xsl:value-of select="$stringunderprocessing"/>
                            <xsl:call-template name="addnote">
                                <xsl:with-param name="nodes" select="$nextnodes"/>
                                <xsl:with-param name="tomatch" select="$tomatch"/>
                                <xsl:with-param name="rank" select="$rank"/>
                                <xsl:with-param name="matchedsofar" select="$candidate"/>
                                <xsl:with-param name="textsofar" select="concat($textsofar, $stringunderprocessing)"/>
                                <xsl:with-param name="note" select="$note"/>
                            </xsl:call-template>
                        </xsl:if>
                        <xsl:if test="not(contains($tomatch,$candidate))"> <!-- No more chance -->
                            <xsl:value-of select="$stringunderprocessing"/>
                            <xsl:call-template name="addnote">
                                <xsl:with-param name="nodes" select="$nextnodes"/>
                                <xsl:with-param name="tomatch" select="$tomatch"/>
                                <xsl:with-param name="rank" select="$rank"/>
                                <xsl:with-param name="matchedsofar" select="''"/>
                                <xsl:with-param name="textsofar" select="concat($textsofar, $stringunderprocessing)"/>
                                <xsl:with-param name="note" select="$note"/>
                            </xsl:call-template>
                         </xsl:if>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="name($firstnode)='ph'"> <!-- A previously processed note -->
                    <xsl:copy-of select="$firstnode"/>
                    <xsl:call-template name="addnote">
                        <xsl:with-param name="nodes" select="$nextnodes"/>
                        <xsl:with-param name="tomatch" select="$tomatch"/>
                        <xsl:with-param name="rank" select="$rank"/>
                        <xsl:with-param name="matchedsofar" select="$matchedsofar"/>
                        <xsl:with-param name="textsofar" select="$textsofar"/>
                        <xsl:with-param name="note" select="$note"/>
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>