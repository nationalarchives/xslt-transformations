<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:mdf="http://metadata/functions"
                exclude-result-prefixes="xs">

    <xsl:import href="metadata-functions.xslt"/>

    <xsl:output method="xml" omit-xml-declaration="no" byte-order-mark="no" media-type="application/xml" version="1.0"
                indent="yes" encoding="UTF-8"/>

    <xsl:param name="transcription">file:///home/dev/git/transformations/src/test/resources/mock-transcription.csv.xml
    </xsl:param>


    <xsl:variable name="trans-csv">
        <xsl:choose>
            <xsl:when test="doc-available($transcription)">
                <xsl:copy-of select="doc($transcription)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes"  select="concat('Metadata CSV ''', $transcription,''' is not available!')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="division">division</xsl:variable>
    <xsl:variable name="series">series</xsl:variable>
    <xsl:variable name="piece">piece</xsl:variable>
    <xsl:variable name="item">item</xsl:variable>
    <xsl:variable name="sub-item">sub_item</xsl:variable>
    <xsl:variable name="ordinal">item</xsl:variable>
    <xsl:variable name="closure-identifier-in-closure">identifier</xsl:variable>

    <xsl:key name="row-by-division-series-piece-item-ordinal-sub-item" match="row"
             use="concat(elem[@name=$division],
             '|', elem[@name=$series] ,
             '|', elem[@name=$piece] ,
             '|', elem[@name=$item],
             '|', elem[@name=$ordinal],
             '|', elem[@name=$sub-item])"/>

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
        <xsl:variable name="transcription-identifier"
                      select="concat(elem[@name=$division]/text(),
                      '|', elem[@name=$series]/text() ,
                      '|', elem[@name=$piece]/text() ,
                      '|', elem[@name=$item]/text() ,
                      '|', elem[@name=$ordinal]/text() ,
                      '|', elem[@name=$sub-item]/text())"/>

        <xsl:variable name="matching-transcription-row">
            <xsl:sequence select="key('row-by-division-series-piece-item-ordinal-sub-item' , $transcription-identifier ,$trans-csv)"/>
        </xsl:variable>

         <xsl:element name="row">

             <xsl:for-each select="node()">
                 <xsl:if test="@name eq 'held_by' and ./text() ne ''">
                     <xsl:copy-of select="."/>
                 </xsl:if>
                 <xsl:if test="@name eq 'legal_status' and ./text() ne ''">
                     <xsl:copy-of select="."/>
                 </xsl:if>
                 <xsl:if test="@name eq 'covering_dates' and ./text() ne ''">
                     <xsl:copy-of select="."/>
                 </xsl:if>
                 <xsl:if test="@name eq 'description' and ./text() ne ''">
                     <xsl:copy-of select="."/>
                 </xsl:if>
                 <xsl:if test="not(@name eq 'held_by') and
                             not(@name eq 'legal_status') and
                             not(@name eq 'covering_dates') and
                             not(@name eq 'description')">
                     <xsl:copy-of select="."/>
                 </xsl:if>
             </xsl:for-each>

             <xsl:variable name="has-held-by" select="elem[@name eq 'held_by']/text() ne ''"/>
             <xsl:variable name="has-legal_status" select="elem[@name eq 'legal_status']/text() ne ''"/>
             <xsl:variable name="has-covering_dates" select="elem[@name eq 'covering_dates']/text() ne ''"/>
             <xsl:variable name="has-description" select="elem[@name eq 'description']/text() ne ''"/>

             <xsl:if test="$matching-transcription-row">
                 <xsl:if test="not($has-held-by) and $matching-transcription-row/row/elem[@name eq 'held_by']">
                     <xsl:copy-of select="$matching-transcription-row/row/elem[@name eq 'held_by']"/>
                 </xsl:if>
                 <xsl:if test="not($has-legal_status) and $matching-transcription-row/row/elem[@name eq 'legal_status']">
                     <xsl:copy-of select="$matching-transcription-row/row/elem[@name eq 'legal_status']"/>
                 </xsl:if>
                 <xsl:if test="not($has-covering_dates) and $matching-transcription-row/row/elem[@name eq 'covering_dates']">
                    <xsl:copy-of select="$matching-transcription-row/row/elem[@name eq 'covering_dates']"/>
                 </xsl:if>
                 <xsl:if test="not($has-description) and $matching-transcription-row/row/elem[@name eq 'description']">
                    <xsl:copy-of select="$matching-transcription-row/row/elem[@name eq 'description']"/>
                 </xsl:if>
            </xsl:if>
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>