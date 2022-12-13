<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tessella.com/XIP/v4"
                xmlns:csf="http://catalogue/service/functions"
                xmlns:dcterms="http://purl.org/dc/terms/"
                xmlns:f="http://local/functions"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                xmlns:tna="http://nationalarchives.gov.uk/metadata/tna#"
                xmlns:xip="http://www.tessella.com/XIP/v4"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:dc="http://purl.org/dc/terms/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="dcterms f csf xip"
                version="2.0">

    <xsl:import href="du-path-function.xslt"/>
    <xsl:import href="catalogue-service-functions.xslt"/>
    <xsl:import href="decode-uri-function.xslt"/>
    <xsl:import href="common-digitised-templates.xslt"/>
    <xsl:output indent="yes"/>



    <xsl:param name="generated-sub-item-dus-manifestations-xml-path" as="xs:string"
    >file:///home/dev/git/transformations/src/test/resources/mock-techacq-transcription-env.xml</xsl:param>


    <xsl:variable name="subitems">
        <xsl:choose>
            <xsl:when test="doc-available($generated-sub-item-dus-manifestations-xml-path)">
                <xsl:copy-of select="doc($generated-sub-item-dus-manifestations-xml-path)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes"  select="concat('Metadata CSV ''', $generated-sub-item-dus-manifestations-xml-path,''' is not available!')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>


    <xsl:template match="xip:XIP">

        <xsl:copy>
            <xsl:copy-of select="xmlns"/>
            <xsl:namespace name="tna" select="'http://nationalarchives.gov.uk/metadata/tna#'"/>
            <xsl:namespace name="xs" select="'http://www.w3.org/2001/XMLSchema'"/>
            <xsl:namespace name="rdf" select="'http://www.w3.org/1999/02/22-rdf-syntax-ns#'"/>
            <xsl:namespace name="rdfs" select="'http://www.w3.org/2000/01/rdf-schema#'"/>
            <xsl:apply-templates/>
        </xsl:copy>

    </xsl:template>

    <xsl:template match="xip:DeliverableUnits">
        <xsl:copy>
        <xsl:copy-of select="$subitems/xip:XIP/xip:DeliverableUnit"/>
        <xsl:apply-templates/>
        <xsl:copy-of select="$subitems/xip:XIP/xip:Manifestation"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@*, node()"/>
        </xsl:copy>
    </xsl:template>


</xsl:stylesheet>
