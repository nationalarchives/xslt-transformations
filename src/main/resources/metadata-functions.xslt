<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:mdf="http://metadata/functions"
    version="2.0">

    <xsl:function name="mdf:loadOtherMetaData">
        <xsl:param name="inputPath"/>
        <xsl:param name="splitChar"/>
        <xsl:choose>
            <xsl:when test="count(tokenize($inputPath,';')) = 1">
                <xsl:copy-of select="document($inputPath)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="firstDoc" select="document(tokenize($inputPath,';')[1])"/>
                <xsl:copy-of select="mdf:loadOtherMetaDataAcc($inputPath,$splitChar,$firstDoc,2)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


    <xsl:function name="mdf:loadOtherMetaDataAcc">
        <xsl:param name="inputPath"/>
        <xsl:param name="splitChar"/>
        <xsl:param name="docs"/>
        <xsl:param name="pathIndex"/>
        <xsl:choose>
            <xsl:when test="count(tokenize($inputPath,';')) = $pathIndex">
                <xsl:variable name="docs">
                    <xsl:sequence select="$docs"/>
                    <xsl:sequence select="document(tokenize($inputPath,';')[$pathIndex])"/>
                </xsl:variable>
                <xsl:copy-of select="$docs"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="allDocs">
                    <xsl:sequence select="$docs"/>
                    <xsl:sequence select="document(tokenize($inputPath,';')[$pathIndex])"/>
                </xsl:variable>
                <xsl:copy-of select="mdf:loadOtherMetaDataAcc($inputPath,$splitChar,$allDocs,$pathIndex+1)"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

    <xsl:function name="mdf:getMatchingRows">
        <xsl:param name="docs"/>
        <xsl:param name="file-name"/>
        <xsl:param name="docIndex"/>
        <xsl:param name="keyIdentifier"/>
        <xsl:variable name="currentDoc" select="$docs/root[$docIndex]"/>
        <xsl:for-each select="$currentDoc">
            <xsl:choose>
                <xsl:when test="$docIndex &gt; 0 ">
                    <xsl:variable name="rows">
                        <xsl:sequence select="key($keyIdentifier,$file-name)"/>
                        <xsl:sequence select="mdf:getMatchingRows($docs,$file-name,$docIndex -1, $keyIdentifier)"/>
                    </xsl:variable>
                    <xsl:copy-of select="$rows"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="key($keyIdentifier, $file-name)"/>
                    <xsl:variable name="rows">
                        <xsl:sequence select="key($keyIdentifier, $file-name)"/>
                    </xsl:variable>
                    <xsl:copy-of select="$rows"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>

</xsl:stylesheet>