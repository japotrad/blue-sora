<?xml version="1.0" encoding="UTF-8"?>
<!-- Not supported: Non-empty inline bpt, ept, hi and it tags -->
<xsl:stylesheet xmlns:functx="http://www.functx.com" xmlns:h="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0" exclude-result-prefixes="xsi">
    <xsl:include href="functions.xsl"/>
    <!-- Full path to the TMX file -->
    <xsl:param name="tmx" select="concat(substring-before(base-uri(),'.html'), '.tmx')"/> 
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes" encoding="UTF-8" doctype-public="-//W3C//DTD XHTML 1.1//EN" doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"/>
    <xsl:variable name="segments">
        <xsl:if test="doc-available($tmx)">
            <xsl:for-each select="document($tmx)/tmx/body/tu">
                <xsl:variable name="targetsegment" select="tuv[@xml:lang!='ja' and @xml:lang!='ja-JP']/seg[1]"/>
                <!-- From the TMX, get texts longer than 5 characters -->
                <xsl:if test="string-length($targetsegment/text()[1]) &gt; 5">
                    <segment>
                        <!-- The rank attribute is the tu element position in the tmx body -->
                        <xsl:attribute name="rank"><xsl:value-of select="position()"/></xsl:attribute>
                        <xsl:copy-of select="$targetsegment" copy-namespaces="no"/>
                        <txt><xsl:value-of select="$targetsegment/text()"/></txt>
                        <xsl:if test="./note or $targetsegment/ph">
                            <notes>
                                <xsl:for-each select="$targetsegment/ph">
                                    <!-- Note placed in the middle of the segment text -->
                                    <note>
                                        <!--  The index attribute gives the character position of the callout within the TMX segment -->
                                        <xsl:attribute name="index">
                                            <xsl:value-of select="string-length(string-join((preceding-sibling::text()),''))+1"/>
                                        </xsl:attribute>
                                        <xsl:value-of select="sub[1]/text()"/>
                                    </note>
                                </xsl:for-each>
                                <xsl:if test="./note">
                                    <!-- Global note on the text unit: the callout should be placed at the end of the segment -->
                                    <note>
                                        <xsl:attribute name="index"><xsl:value-of select="string-length($targetsegment/text())+1"/></xsl:attribute>
                                        <xsl:value-of select="./note/text()"/>
                                    </note>
                                </xsl:if>
                            </notes>
                        </xsl:if>
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
            <xsl:variable name="matchingsegments">
                <xsl:for-each select="$segments/segment">
                    <xsl:sort select="functx:index-of-string-first($plaintext,txt/text())"/>
                    <xsl:if test="contains($plaintext,txt/text())">
                        <matchingsegment>
                            <xsl:attribute name="rank"><xsl:value-of select="@rank"/></xsl:attribute>
                            <!-- The index attribute gives the starting character position of the matching segment within the plain text -->
                            <xsl:attribute name="index"><xsl:value-of select="functx:index-of-string-first($plaintext,txt/text())"/></xsl:attribute>
                            <xsl:copy-of select="seg" copy-namespaces="no"/>
                            <xsl:copy-of select="txt" copy-namespaces="no"/>
                            <xsl:if test="notes"><xsl:copy-of select="notes" copy-namespaces="no"/></xsl:if>
                        </matchingsegment>
                    </xsl:if>
                </xsl:for-each>
            </xsl:variable>
            <!--xsl:copy-of select="$matchingsegments"/-->
            <xsl:call-template name="addFirstNodeToMixedContent">
                <xsl:with-param name="mixedcontent"><xsl:copy-of select="./node()"/></xsl:with-param>
                <xsl:with-param name="matchingsegments"><xsl:copy-of select="$matchingsegments"/></xsl:with-param>
            </xsl:call-template>
        </xsl:element>
    </xsl:template>
    <xsl:template name="addFirstNodeToMixedContent">
        <xsl:param name="mixedcontent"/>
        <xsl:param name="matchingsegments"/>
        <xsl:variable name="firstmatchingsegment" select="$matchingsegments/matchingsegment[1]"/>
        <xsl:variable name="nodetoadd" select="$firstmatchingsegment/seg[1]/child::node()[1]"/>
        <xsl:variable name="numberofnodesinfirstmatchingsegment" select="count($firstmatchingsegment/seg[1]/child::node())"/>
        <xsl:choose>
            <xsl:when test="$nodetoadd/self::ph">
                <!-- If the node is a note, output the note inline then remove the note from $matchingsegments -->
                <xsl:element name="sup" namespace="http://www.w3.org/1999/xhtml">
                    <xsl:attribute name="onclick">alert('<xsl:value-of select="string($nodetoadd/sub[1])"/>')</xsl:attribute>
                    <xsl:text>*</xsl:text>
                </xsl:element>
                <xsl:variable name="updatedmatchingsegments">
                    <xsl:if test="$numberofnodesinfirstmatchingsegment &gt; 1">
                        <matchingsegment>
                            <xsl:attribute name="rank"><xsl:value-of select="$firstmatchingsegment/@rank"/></xsl:attribute>
                            <xsl:attribute name="index"><xsl:value-of select="$firstmatchingsegment/@index"/></xsl:attribute>
                            <seg><xsl:copy-of select="$firstmatchingsegment/seg/child::node()[position()>1]" copy-namespaces="no"/></seg>
                            <txt><xsl:value-of select="$firstmatchingsegment/txt"/></txt>
                        </matchingsegment>
                    </xsl:if>
                    <xsl:copy-of select="$matchingsegments/matchingsegment[position()>1]"/>
                </xsl:variable>
                <xsl:call-template name="addFirstNodeToMixedContent">
                    <xsl:with-param name="mixedcontent"><xsl:copy-of select="$mixedcontent"/></xsl:with-param>
                    <xsl:with-param name="matchingsegments"><xsl:copy-of select="$updatedmatchingsegments"/></xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$nodetoadd/self::bpt">
                <!-- Process 3 TMX nodes (bpt + text + ept), 4 nodes (bpt + text + ph + ept) or 5 nodes (pbt + text + ph + text + ept)
                    because they are represented by only one element in the HTML file -->
                <xsl:element name="{name($mixedcontent/child::node()[1])}" namespace="http://www.w3.org/1999/xhtml">
                    <xsl:copy-of select="$mixedcontent/child::node()[1]/@*"/>
                    <xsl:for-each select="$firstmatchingsegment/seg[1]/ept[1]/preceding-sibling::node()">
                        <xsl:choose>
                            <xsl:when test="./self::text()"><xsl:value-of select="."/></xsl:when>
                            <xsl:when test="./self::ph">
                                <xsl:element name="sup" namespace="http://www.w3.org/1999/xhtml">
                                    <xsl:attribute name="onclick">alert('<xsl:value-of select="string(./sub[1])"/>')</xsl:attribute>
                                    <xsl:text>*</xsl:text>
                                </xsl:element>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:element>
                <xsl:variable name="updatedmixedcontent">
                    <xsl:copy-of select="$mixedcontent/child::node()[position()>1]"/>
                </xsl:variable>
                <xsl:variable name="updatedmatchingsegments">
                    <xsl:variable name="nbofprocessednodes" select="count($firstmatchingsegment/seg[1]/ept[1]/preceding-sibling::node())"/>
                        <xsl:if test="$numberofnodesinfirstmatchingsegment &gt; $nbofprocessednodes">
                        <matchingsegment>
                            <xsl:attribute name="rank"><xsl:value-of select="$firstmatchingsegment/@rank"/></xsl:attribute>
                            <xsl:attribute name="index"><xsl:value-of select="$firstmatchingsegment/@index"/></xsl:attribute>
                            <seg><xsl:copy-of select="$firstmatchingsegment/seg/child::node()[position()>$nbofprocessednodes]" copy-namespaces="no"/></seg>
                            <txt><xsl:value-of select="substring($firstmatchingsegment/txt, string-length(string-join($firstmatchingsegment/seg[1]/ept[1]/preceding-sibling::text(),''))+1)"/></txt>
                        </matchingsegment>
                    </xsl:if>
                    <xsl:copy-of select="$matchingsegments/matchingsegment[position()>1]"/>
                </xsl:variable>
                <xsl:call-template name="addFirstNodeToMixedContent">
                    <xsl:with-param name="mixedcontent"><xsl:copy-of select="$updatedmixedcontent"/></xsl:with-param>
                    <xsl:with-param name="matchingsegments"><xsl:copy-of select="$updatedmatchingsegments"/></xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$nodetoadd/self::ept">
                <!-- Output nothing as the processing was done in the ept tag above -->
                <xsl:variable name="updatedmatchingsegments">
                    <xsl:if test="$numberofnodesinfirstmatchingsegment &gt; 1">
                        <matchingsegment>
                            <xsl:attribute name="rank"><xsl:value-of select="$firstmatchingsegment/@rank"/></xsl:attribute>
                            <xsl:attribute name="index"><xsl:value-of select="$firstmatchingsegment/@index"/></xsl:attribute>
                            <seg><xsl:copy-of select="$firstmatchingsegment/seg/child::node()[position()>1]" copy-namespaces="no"/></seg>
                            <txt><xsl:value-of select="$firstmatchingsegment/txt"/></txt>
                        </matchingsegment>
                    </xsl:if>
                    <xsl:copy-of select="$matchingsegments/matchingsegment[position()>1]"/>
                </xsl:variable>
                <xsl:call-template name="addFirstNodeToMixedContent">
                    <xsl:with-param name="mixedcontent"><xsl:copy-of select="$mixedcontent"/></xsl:with-param>
                    <xsl:with-param name="matchingsegments"><xsl:copy-of select="$updatedmatchingsegments"/></xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$nodetoadd/self::text() and (starts-with(string($mixedcontent), $nodetoadd) or starts-with(string($mixedcontent), concat(' ', $nodetoadd)))">
                <!-- If the node is a text node, output it and remove the corresponding text from $mixedcontent and $matchingsegments -->
                <xsl:variable name="mixedcontentstartswithspace" select="starts-with(string($mixedcontent),' ')"/> <!-- Common typographic rule in latin alphabet languages: After period or other major punctuation mark used for text segmentation, a space (that does not appear in the TMX) may be automatically added in the target language HTML. -->
                <xsl:variable select="string-length($nodetoadd) + number($mixedcontentstartswithspace)" name="mixedcontentlength"/>
                <xsl:variable select="string-length($nodetoadd)" name="nodelength"/>
                <xsl:value-of select="substring(string($mixedcontent),1, $mixedcontentlength)"/>
                <xsl:if test="string-length($mixedcontent/child::node()[1])=$mixedcontentlength">
                    <!-- If all the first mixed content node has been processed, remove this node from $mixedcontent and $matchingsegments -->
                    <xsl:variable name="updatedmixedcontent">
                        <xsl:copy-of select="$mixedcontent/child::node()[position()>1]"/>
                    </xsl:variable>
                     <xsl:variable name="updatedmatchingsegments">
                         <xsl:if test="$numberofnodesinfirstmatchingsegment &gt; 1">
                             <matchingsegment>
                                <xsl:attribute name="rank"><xsl:value-of select="$firstmatchingsegment/@rank"/></xsl:attribute>
                                <xsl:attribute name="index"><xsl:value-of select="$firstmatchingsegment/@index"/></xsl:attribute>
                                <seg><xsl:copy-of select="$firstmatchingsegment/seg/child::node()[position()>1]" copy-namespaces="no"/></seg>
                                <txt><xsl:value-of select="substring($firstmatchingsegment/txt,$nodelength+1)"/></txt>
                            </matchingsegment>
                         </xsl:if>
                         <xsl:copy-of select="$matchingsegments/matchingsegment[position()>1]"/>
                    </xsl:variable>
                    <xsl:if test="count($updatedmatchingsegments/node())">
                        <!-- Recursive call if there is something left to process -->
                        <xsl:call-template name="addFirstNodeToMixedContent">
                            <xsl:with-param name="mixedcontent"><xsl:copy-of select="$updatedmixedcontent"/></xsl:with-param>
                            <xsl:with-param name="matchingsegments"><xsl:copy-of select="$updatedmatchingsegments"/></xsl:with-param>
                        </xsl:call-template>
                    </xsl:if>
                </xsl:if>
                <xsl:if test="string-length($mixedcontent/child::node()[1])&gt;$mixedcontentlength">
                    <!-- If the text in the mixed content node is longer than the text in the TMX segment (because there is a note or an bpt, ept... element just after, or because there are some other segments left to be processed.),
                        shorten but keep the mixed content node -->
                    <xsl:variable name="updatedmixedcontent">
                        <xsl:value-of select="substring($mixedcontent/child::node()[1], $mixedcontentlength+1)"/>
                        <xsl:copy-of select="$mixedcontent/child::node()[position()>1]"/>
                    </xsl:variable>
                    <xsl:variable name="updatedmatchingsegments">
                        <xsl:if test="$numberofnodesinfirstmatchingsegment &gt; 1">
                        <matchingsegment>
                            <xsl:attribute name="rank"><xsl:value-of select="$firstmatchingsegment/@rank"/></xsl:attribute>
                            <xsl:attribute name="index"><xsl:value-of select="$firstmatchingsegment/@index"/></xsl:attribute>
                            <seg><xsl:copy-of select="$firstmatchingsegment/seg/child::node()[position()>1]" copy-namespaces="no"/></seg>
                            <txt><xsl:value-of select="substring($firstmatchingsegment/txt,$nodelength+1)"/></txt>
                        </matchingsegment>
                        </xsl:if>
                        <xsl:copy-of select="$matchingsegments/matchingsegment[position()>1]"/>
                    </xsl:variable>
                    <xsl:call-template name="addFirstNodeToMixedContent">
                        <xsl:with-param name="mixedcontent"><xsl:copy-of select="$updatedmixedcontent"/></xsl:with-param>
                        <xsl:with-param name="matchingsegments"><xsl:copy-of select="$updatedmatchingsegments"/></xsl:with-param>
                    </xsl:call-template>  
                </xsl:if> 
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>Could not add this node: <xsl:value-of select="$nodetoadd"/></xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template> <!-- End of addFirstNodeToMixedContent template  -->
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
            <!--xsl:copy-of select="$segments" /-->
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