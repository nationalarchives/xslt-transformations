<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns="http://www.tessella.com/XIP/v4"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:ext="http://tna/saxon-extension"
                xmlns:tna="http://nationalarchives.gov.uk/metadata/tna#"
                exclude-result-prefixes="ext xs"
                xpath-default-namespace="http://www.tessella.com/XIP/v4"
                version="2.0">

    <!-- For Digitised Surrogates...
        adds a new manifestation for all existing manifestations which are not metadata manifestations to represent the existing paper record.
        The paper manifestations are the 1st manifestation and therefore the digital surrogate must becomes the 2nd manifestation.
        The paper manifestations are not active - i.e. they are not considered to be at risk.
        The paper mainfestations are the original ones - not the surrogate manifestation.
        Author : Rob Walpole <robkwalpole@gmail.com>
        Date: 8-10-2014
     -->

    <xsl:output indent="yes"/>

    <xsl:variable name="metadata-du"
                  select="/XIP/DeliverableUnits/DeliverableUnit[Title eq '_metadata']/DeliverableUnitRef/text()"
                  as="xs:string"/>

    <xsl:variable name="metadata-dus" as="element()*">
        <xsl:call-template name="find-metadata-dus">
            <xsl:with-param name="metadata-du-param" select="$metadata-du"/>
        </xsl:call-template>
    </xsl:variable>

    <xsl:template name="find-metadata-dus" as="element()*">
        <xsl:param name="metadata-du-param" as="xs:string"/>
        <xsl:for-each select="/XIP/DeliverableUnits/DeliverableUnit[ParentRef eq $metadata-du-param]">
            <xsl:call-template name="find-metadata-dus">
                <xsl:with-param name="metadata-du-param" select="DeliverableUnitRef/text()"/>
            </xsl:call-template>
            <xsl:copy-of select="DeliverableUnitRef"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:key name="du-by-ref" match="XIP/DeliverableUnits/DeliverableUnit" use="DeliverableUnitRef"/>

    <xsl:template match="ManifestationRelRef">
        <xsl:choose>
            <xsl:when
                    test="not(parent::Manifestation/DeliverableUnitRef = $metadata-dus) and not(parent::Manifestation/DeliverableUnitRef = $metadata-du)">
                <ManifestationRelRef>2</ManifestationRelRef>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="Originality">
        <xsl:choose>
            <xsl:when
                    test="not(parent::Manifestation/DeliverableUnitRef = $metadata-dus) and not(parent::Manifestation/DeliverableUnitRef = $metadata-du)">
                <Originality>false</Originality>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="Manifestation">
        <xsl:variable name="ref" select="DeliverableUnitRef/text()"/>
        <xsl:variable name="relatedDu" select="key('du-by-ref', $ref)"/>
        <xsl:choose>
            <xsl:when test="not(DeliverableUnitRef = $metadata-dus) and not(DeliverableUnitRef = $metadata-du)">
                <xsl:if test="not(exists($relatedDu/Metadata/tna:metadata/rdf:RDF/tna:DigitalFolder/tna:cataloguing/tna:Cataloguing/tna:subItemIdentifier))">
                    <Manifestation status="new">
                        <DeliverableUnitRef>
                            <xsl:value-of select="DeliverableUnitRef"/>
                        </DeliverableUnitRef>
                        <ManifestationRef>
                            <xsl:value-of select="ext:random-uuid()"/>
                        </ManifestationRef>
                        <ManifestationRelRef>1</ManifestationRelRef>
                        <Originality>true</Originality>
                        <Active>false</Active>
                        <TypeRef>1</TypeRef>
                    </Manifestation>
                </xsl:if>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Identity transformation -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>