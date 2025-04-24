<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:functx="http://www.functx.com" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xsl functx xs" version="2.0">
  <xsl:function name="functx:index-of-string-first" as="xs:integer?" xmlns:functx="http://www.functx.com">
  <!-- The functx:index-of-string-first function returns an integer representing the first position of $substring within $arg. If $arg does not contain $substring, the empty sequence is returned. -->
  <xsl:param name="arg" as="xs:string?"/>
  <xsl:param name="substring" as="xs:string"/>

  <xsl:sequence select="
  if (contains($arg, $substring))
  then string-length(substring-before($arg, $substring))+1
  else ()
 "/>

</xsl:function>
</xsl:stylesheet>
 
    