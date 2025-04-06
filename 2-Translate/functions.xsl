<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:functx="http://www.functx.com" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xsl functx xs" version="2.0">
  <xsl:function name="functx:escape-for-regex" as="xs:string" xmlns:functx="http://www.functx.com">
    <!-- The functx:escape-for-regex function escapes a string that you wish to be taken literally rather than treated like a regular expression.
      This is useful when, for example, you are calling the built-in fn:replace function and you want any periods or parentheses to be treated like literal characters rather than regex special characters.  -->
    <xsl:param name="arg" as="xs:string?"/>
    <xsl:sequence select="replace($arg,'(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))', '\\$1')"/>
  </xsl:function>
  
  <xsl:function name="functx:number-of-matches" as="xs:integer" xmlns:functx="http://www.functx.com">
    <!-- The functx:number-of-matches function counts the number of times a string matches a particular pattern (regular expression). It does not count overlapping regions. -->
    <xsl:param name="arg" as="xs:string?"/>
    <xsl:param name="pattern" as="xs:string"/>
    <xsl:sequence select="max((0, count(tokenize($arg,$pattern)) - 1))"/>
  </xsl:function>
</xsl:stylesheet>
 
    