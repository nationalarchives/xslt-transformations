<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:mdf="http://metadata/functions"
                exclude-result-prefixes="xs">

    <xsl:import href="metadata-functions.xslt"/>

    <xsl:output method="xml" omit-xml-declaration="no" byte-order-mark="no" media-type="application/xml" version="1.0"
                indent="yes" encoding="UTF-8"/>

    <!--
     Matching rows from the transcription file (otherMetadataFiles) are add to the original under a transcription element
     The rows are matched on division/series/piece and item
    -->

    <xsl:param name="transcription">file:///home/dev/git/transformations/src/test/resources/mock-transcription.csv.xml</xsl:param>

    <xsl:variable name="division">division</xsl:variable>
    <xsl:variable name="series">series</xsl:variable>
    <xsl:variable name="piece">piece</xsl:variable>
    <xsl:variable name="item">item</xsl:variable>
    <xsl:variable name="closure-identifier-in-closure">identifier</xsl:variable>

    <xsl:key name="row-by-division-series-piece-item" match="row"
             use="concat(elem[@name=$division],
             '|', elem[@name=$series] ,
             '|', elem[@name=$piece] ,
             '|', elem[@name=$item])"/>

    <xsl:key name="closure-key" match="row" use="elem[@name=$closure-identifier-in-closure]"/>

     <xsl:template match="/">
        <xsl:variable name="transcription-metadata" select="mdf:loadOtherMetaData($transcription, ';')"/>
         <xsl:element name="root">
            <xsl:apply-templates>
                <xsl:with-param name="transcription-metadata" select="$transcription-metadata"/>
            </xsl:apply-templates>
        </xsl:element>
    </xsl:template>


    <xsl:template match="row">
        <xsl:param name="transcription-metadata"/>
        <xsl:variable name="transcription-identifier"
                      select="concat(elem[@name=$division]/text(),
                      '|', elem[@name=$series]/text() ,
                      '|', elem[@name=$piece]/text() ,
                      '|', elem[@name=$item]/text())"/>

         <xsl:element name="row">
             <xsl:variable name="matching-transcription-row">
                <xsl:sequence select="mdf:getMatchingRows($transcription-metadata, $transcription-identifier,1,'row-by-division-series-piece-item')"/>
            </xsl:variable>
            <xsl:copy-of select="node()"/>

            <xsl:if test="$matching-transcription-row/row">
                <xsl:element name="transcription">
                    <xsl:copy-of select="$matching-transcription-row/row/*"/>
                </xsl:element>
            </xsl:if>
         </xsl:element>
    </xsl:template>

</xsl:stylesheet>