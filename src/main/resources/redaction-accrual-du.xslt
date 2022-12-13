<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tessella.com/XIP/v4"
                xmlns:csf="http://catalogue/service/functions"
                xmlns:dcterms="http://purl.org/dc/terms/"
                xmlns:f="http://local/functions"
                xmlns:ext="http://tna/saxon-extension"
                xmlns:xip="http://www.tessella.com/XIP/v4"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="dcterms f csf xip"
                version="2.0">

    <xsl:import href="du-path-function.xslt"/>
    <xsl:import href="catalogue-service-functions.xslt"/>
    <xsl:import href="decode-uri-function.xslt"/>
    <xsl:import href="common-transcriptions.xslt"/>
    <xsl:import href="common-digitised-templates.xslt"/>
    <xsl:output indent="yes"/>

    <xsl:param name="accrual-data-xml-path" as="xs:string">/opt/tna_transformations/empty-accmumulation-data.xml
    </xsl:param>

    <xsl:variable name="accrual-data" as="document-node(element(AccrualData))">
        <xsl:choose>
            <xsl:when test="doc-available($accrual-data-xml-path)">
                <xsl:copy-of select="doc($accrual-data-xml-path)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes"
                             select="concat('accrual-data-xml-path ''', $accrual-data-xml-path,''' is not available!')"/>
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

    <xsl:template match="xip:DeliverableUnit">
        <xsl:variable name="du-accrual-data" select="f:du-accrual-data(xip:DeliverableUnitRef/text())"/>
        <xsl:element name="DeliverableUnit">
            <xsl:choose>
                <xsl:when test="$du-accrual-data !=''">
                    <xsl:attribute name="status" select="'changed'"/>
                    <xsl:variable name="children" select="$du-accrual-data/ParentDeliverableUnitMetadata/xip:DeliverableUnit/*" as="element()+"/>
                    <xsl:copy-of select="$children[position() lt count($children)]"/>
                    <xsl:copy-of select="DeliverableUnitComponent"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="status" select="'new'"/>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="xip:Manifestation">
        <xsl:variable name="new" select="'new'"/>
        <xsl:variable name="du-accrual-data" select="f:du-accrual-data(xip:DeliverableUnitRef/text())"/>
        <xsl:element name="Manifestation">
            <xsl:attribute name="status" select="$new"/>
            <xsl:choose>
                <xsl:when test="$du-accrual-data !=''">
                    <xsl:element name="DeliverableUnitRef">
                        <xsl:value-of select="$du-accrual-data/ParentDeliverableUnitRef"/>
                    </xsl:element>
                    <xsl:variable name="children" select="child::*" as="element()+"/>
                    <xsl:copy-of select="$children[position() gt 1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>

    <xsl:function name="f:du-accrual-data">
        <xsl:param name="accrual-dri-ref" as="xs:string"/>
        <xsl:copy-of
                select="$accrual-data/AccrualData/DeliverableUnits/DeliverableUnit[AccrualDeliverableUnitRef/text() eq $accrual-dri-ref]"/>
    </xsl:function>


</xsl:stylesheet>
