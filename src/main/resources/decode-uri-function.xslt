<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:f="http://local/functions"
    xmlns:ext="http://tna/saxon-extension"
    version="2.0">
    
    <!--
        This tail-recursive function is designed to decode any URI - no matter how many times it has been encoded!
        
        Author: Rob Walpole
        Date: 27-03-2014
    -->


    <xsl:function name="f:decode-uri" as="xs:string">
        <xsl:param name="uri" as="xs:string"/>
        <xsl:variable name="uriencoded" select = "replace($uri,'\+', '%2B')"/>
        <xsl:choose>
            <xsl:when test = "matches($uri, '%[0-9A-Fa-f][0-9A-Fa-f]')">
                <xsl:variable name="decoded-uri" select="ext:url-decode($uriencoded)"/>
                <xsl:value-of select="f:decode-uri($decoded-uri)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$uriencoded"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="f:decode-path" as="xs:string">
        <xsl:param name="path" as="xs:string"/>
        <xsl:param name="type" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$type eq 'folder'">
                <xsl:value-of select="concat(f:decode-uri($path),'/')"/>
            </xsl:when>            
            <xsl:otherwise> <!-- for type file, sub_item -->
                <xsl:value-of select="f:decode-uri($path)"/>
            </xsl:otherwise>
        </xsl:choose>     
    </xsl:function>

    
</xsl:stylesheet>