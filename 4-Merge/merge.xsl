<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:h="http://www.w3.org/1999/xhtml"
    xmlns:r="https://github.com/japotrad/blue-sora/ris" exclude-result-prefixes="xs h r"
    version="2.0">
    <xsl:variable name="base-uri-radical" select="substring-before(base-uri(),'_')"/> <!-- URI to process truncated before the language code -->
    <!-- 2-letter code of the language the document has been translated into -->
    <xsl:variable name="rawLang" select="substring-after(substring-before(base-uri(), '.html'),'_')"/>
    <xsl:variable name="defaultLang">
        <xsl:if test="contains($rawLang, '_')"><xsl:value-of select="substring-before($rawLang, '_')"/></xsl:if>
        <xsl:if test="not(contains($rawLang, '_'))"><xsl:value-of select="$rawLang"/></xsl:if>
    </xsl:variable>
    <xsl:param name="lang" select="$defaultLang"/>
    <!-- Full path to the RIS XML file -->
    <xsl:param name="ris" select="concat($base-uri-radical, '_', $lang, '_ris.xml')"/>
    <!-- Full path to the preface HTML file in the target language -->
    <xsl:param name="preface" select="concat($base-uri-radical, '_', $lang, '_preface.html')"/>
    <!-- Full path to the HTML document file in Japanese -->
    <xsl:param name="ja" select="concat($base-uri-radical, '_rich.html')"/>
    <xsl:output method="xml" encoding="UTF-8" indent="no" omit-xml-declaration="no"/>
    <xsl:template match="/">
        <book>
            <xsl:attribute name="xml:lang">
                <xsl:value-of select="$lang"/>
            </xsl:attribute>
            <xsl:call-template name="info"/>
            <xsl:if test="not(doc-available($preface))">
                <xsl:message>Info: No preface is generated, because no file has been found at: <xsl:value-of select="$preface"/></xsl:message>
            </xsl:if>
            <xsl:if test="doc-available($preface)">
                <xsl:message>Info: Start processing <xsl:value-of select="$preface"/></xsl:message>
                <xsl:call-template name="preface"/>
                <xsl:message>Info: End processing <xsl:value-of select="$preface"/></xsl:message>
            </xsl:if>
            <xsl:if test="not(//h:h3) and not(//h:h4)">
                <xsl:message>Info: Start processing <xsl:value-of select="base-uri()"/> as an article</xsl:message>
                <xsl:call-template name="article"/>
                <xsl:message>Info: End processing the article <xsl:value-of select="base-uri()"/></xsl:message>
            </xsl:if>
        </book>
    </xsl:template>
    <xsl:template name="article">
        <article>
            <xsl:variable name="risDoc" select="document($ris)"/>
            <xsl:variable name="jaDoc" select="document($ja)"/>
            <info>
                <title>
                    <xsl:copy-of select="$risDoc/r:ris/r:TI/text()"/>
                    <source xml:lang="ja">
                        <xsl:value-of select="$jaDoc/h:html/h:body/descendant::h:h1[@class = 'title']"/>
                    </source>
                </title>
            </info>
            <xsl:apply-templates/>
        </article>
    </xsl:template>
    <xsl:template match="h:a[@class='footnote']"/>
    <xsl:template match="h:body/text()"/>
    <xsl:template match="h:div/text()"/>
    <xsl:template match="h:h1"/> <!-- The document title is retrieved in the info template -->
    <xsl:template match="h:head"/>
    <xsl:template name="info">
        <xsl:variable name="risDoc" select="document($ris)"/>
        <xsl:variable name="jaDoc" select="document($ja)"/>
        <info>
            <title>
                <xsl:copy-of select="$risDoc/r:ris/r:TI/text()"/>
                <source xml:lang="ja">
                    <xsl:value-of select="$jaDoc/h:html/h:body/descendant::h:h1[@class = 'title']"/>
                </source>
            </title>
            <abstract>
                <literallayout>
                    <xsl:copy-of select="$risDoc/r:ris/r:AB/text()"/>
                </literallayout>
            </abstract>
            <authorgroup>
                <author>
                    <xsl:variable name="jaAuthor"
                        select="$jaDoc/h:html/h:head/h:meta[@name = 'author']/@content"/>
                    <!-- There is no clue about how to decompose this name into first name and last name -->
                    <xsl:variable name="jaAuthorStart"
                        select="substring($jaAuthor, 1, string-length($jaAuthor) div 2)"/>
                    <xsl:variable name="jaAuthorEnd"
                        select="substring-after($jaAuthor, $jaAuthorStart)"/>
                    <xsl:variable name="isPerson"
                        select="$risDoc/r:ris/r:AU/r:LAST or $risDoc/r:ris/r:AU/r:FIRST"/>
                    <xsl:if test="$isPerson">
                        <xsl:message>Warning: Arbitrarily set the Japanese author first name as
                                <xsl:value-of select="$jaAuthorEnd"/>, and last name as
                                <xsl:value-of select="$jaAuthorStart"/></xsl:message>
                        <personname>
                            <xsl:if test="$risDoc/r:ris/r:AU/r:FIRST">
                                <firstname>
                                    <xsl:copy-of select="$risDoc/r:ris/r:AU/r:FIRST/text()"/>
                                    <source xml:lang="ja">
                                        <xsl:value-of select="$jaAuthorEnd"/>
                                    </source>
                                </firstname>
                            </xsl:if>
                            <xsl:if test="$risDoc/r:ris/r:AU/r:LAST">
                                <surname>
                                    <xsl:copy-of select="$risDoc/r:ris/r:AU/r:LAST/text()"/>
                                    <source xml:lang="ja">
                                        <xsl:value-of select="$jaAuthorStart"/>
                                    </source>
                                </surname>
                            </xsl:if>
                        </personname>
                    </xsl:if>
                    <xsl:if test="not($isPerson)">
                        <orgname>
                            <xsl:copy-of select="$risDoc/r:ris/r:AU/text()"/>
                            <source xml:lang="ja">
                                <xsl:value-of select="$jaAuthor"/>
                            </source>
                        </orgname>
                    </xsl:if>
                </author>
                <xsl:if test="$risDoc/r:ris/r:A4">
                    <!-- Add translator's name -->
                    <othercredit class="translator">
                        <xsl:variable name="isPerson"
                            select="$risDoc/r:ris/r:A4/r:LAST or $risDoc/r:ris/r:A4/r:FIRST"/>
                        <xsl:if test="$isPerson">
                            <personname>
                                <xsl:if test="$risDoc/r:ris/r:A4/r:FIRST">
                                    <firstname>
                                        <xsl:copy-of select="$risDoc/r:ris/r:A4/r:FIRST/text()"/>
                                    </firstname>
                                </xsl:if>
                                <xsl:if test="$risDoc/r:ris/r:A4/r:LAST">
                                    <surname>
                                        <xsl:copy-of select="$risDoc/r:ris/r:A4/r:LAST/text()"/>
                                    </surname>
                                </xsl:if>
                            </personname>
                        </xsl:if>
                        <xsl:if test="not($isPerson)">
                            <orgname>
                                <xsl:copy-of select="$risDoc/r:ris/r:A4/text()"/>
                            </orgname>
                        </xsl:if>
                    </othercredit>
                </xsl:if>
            </authorgroup>
            <xsl:if test="$risDoc/r:ris/r:PY">
                <pubdate>
                    <xsl:copy-of select="$risDoc/r:ris/r:PY/text()"/>
                </pubdate>
            </xsl:if>
        </info>
    </xsl:template>
    <!-- End of info element -->
    <xsl:template match="h:html/text()"/>
    <xsl:template match="h:i">
        <emphasis role="italic">
            <xsl:apply-templates/>
        </emphasis>
    </xsl:template>
    <xsl:template match="h:p">
        <xsl:call-template name="para">
            <xsl:with-param name="p" select="."/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template name="para">
        <xsl:param name="p"/>
        <para>
            <xsl:if test="string($p[@id])">
                <xsl:attribute name="xml:id"><xsl:value-of select="$p/@id"/></xsl:attribute>
            </xsl:if>
            <xsl:apply-templates />
            <xsl:if test="string($p[@id])">
                <xsl:variable name="jaDoc" select="document($ja)"/>
                <xsl:variable name="jaSource" select="$jaDoc/h:html/h:body//h:p[@id = $p/@id]"/>
                <source xml:lang="ja">
                    <xsl:apply-templates select="$jaSource/node()|$jaSource/text()"/>
                </source>
            </xsl:if>
        </para>
    </xsl:template>
    <xsl:template name="preface">
        <xsl:variable name="pDoc" select="document($preface)"/>
        <preface>
            <xsl:if test="$pDoc/h:html/h:body/h:h1">
                <info>  
                    <title>
                        <xsl:copy-of select="$pDoc/h:html/h:body/h:h1/text()"/>
                    </title>
                </info>
                <xsl:for-each select="$pDoc/h:html/h:body/h:p">
                    <xsl:call-template name="para"><xsl:with-param name="p" select="$pDoc/h:html/h:body/h:p"/></xsl:call-template>
                </xsl:for-each>
            </xsl:if>
        </preface>
    </xsl:template>
    <!-- End of preface element -->
    <xsl:template match="h:rt">
        <rt><xsl:apply-templates/></rt>
    </xsl:template>
    <xsl:template match="h:ruby">
        <ruby><xsl:apply-templates select="h:rb/text()"/><xsl:apply-templates select="h:rt"/></ruby>
    </xsl:template>
    <xsl:template match="h:span[@class='footnoteText']">
        <footnote><para><xsl:value-of select="./child::text()"/></para></footnote>
    </xsl:template>
    <xsl:template match="h:strong[ancestor::h:html[@lang='ja']]|h:em[ancestor::h:html[@lang='ja']]">
        <emphasis>
            <xsl:if test="string(.[@class])">
                <xsl:attribute name="role" select="./@class"/>
            </xsl:if>
            <xsl:apply-templates/>
        </emphasis>
    </xsl:template><!-- End of strong and em element in Japanese -->
    <xsl:template match="h:strong[ancestor::h:html[@lang!='ja']]|h:em[ancestor::h:html[@lang!='ja']]">
        <emphasis>
            <xsl:if test="string(.[@class])">
                <xsl:variable name="role">
                    <xsl:choose> <!-- The role attribute value depends on the target language and on the class attribute value -->
                        <xsl:when test="$lang='en'">
                            <xsl:choose>
                                <xsl:when test="lower-case(./@class)='sesame_dot'"><xsl:text>bold</xsl:text></xsl:when>
                                <xsl:when test="lower-case(./@class)='white_circle'"><xsl:text>bold</xsl:text></xsl:when>
                                <xsl:otherwise><xsl:value-of select="./@class"/></xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:when test="$lang='fr'">
                            <xsl:choose>
                                <xsl:when test="lower-case(./@class)='sesame_dot'"><xsl:text>bold</xsl:text></xsl:when>
                                <xsl:when test="lower-case(./@class)='white_circle'"><xsl:text>underline</xsl:text></xsl:when>
                                <xsl:otherwise><xsl:value-of select="./@class"/></xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise><xsl:value-of select="./@class"/></xsl:otherwise><!-- Copy Japanese typography instructions in the target language as is -->
                    </xsl:choose>
                </xsl:variable>
                <xsl:attribute name="role" select="$role"/>
            </xsl:if>
            <xsl:apply-templates/>
        </emphasis>
    </xsl:template><!-- End of strong and em element in other languages -->
    <!--xsl:template match="text()">
        <xsl:value-of select="."/>
    </xsl:template-->
</xsl:stylesheet>
