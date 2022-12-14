<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:api="http://nationalarchives.gov.uk/dri/catalogue/api"
                xmlns:csf="http://catalogue/service/functions" xmlns:dcterms="http://purl.org/dc/terms/"
                xmlns:ext="http://tna/saxon-extension"
                xmlns:f="http://local/functions" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:tna="http://nationalarchives.gov.uk/metadata/tna#"
                xmlns:xip="http://www.tessella.com/XIP/v4" xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="api csf dcterms ext f rdf xip xsi" version="2.0">

    <xsl:import href="du-path-function.xslt"/>

    <xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>

    <!--
        Determines if a Born Digital Deliverable Unit represents a file of a folder
        
        In Born Digital, each DU represents either a file or a folder.
        
        A DU representing a `Folder will have at least one Manifestation each with NO ManifestationFiles
        A DU representing a `File` will have at least one Manifestation each with ONE ManifestationFile
    -->

    <xsl:template match="xip:Manifestation">
        <xsl:variable name="du-ref" select="xip:DeliverableUnitRef"/>
        <xsl:variable name="du"
                      select="parent::xip:DeliverableUnits/xip:DeliverableUnit[xip:DeliverableUnitRef=$du-ref]"/>


        <!-- if I am the manifestation of the top level DU, I need fake manifestations> -->
        <xsl:if test="f:is-top-level-du($du)">

            <xsl:variable name="maxRelRef" as="xs:integer">
                <xsl:value-of select="max(../xip:Manifestation/xip:ManifestationRelRef/text())"/>
            </xsl:variable>

            <!-- will work if only provided with redactions (100) or presentation copies (101)
                when we have retained and redacted will need to create types and rel refs for both -->
            <xsl:variable name="typeRef" as="xs:integer">
                <xsl:value-of select="max(../xip:Manifestation/xip:TypeRef/text())"/>
            </xsl:variable>
            <!-- 1 is always present -->
            <xsl:if test="$maxRelRef gt 1">
                <xsl:call-template name="addManifestation">
                    <xsl:with-param name="relRef" select="$maxRelRef"/>
                    <xsl:with-param name="typeRef" select="$typeRef"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:if>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>

    </xsl:template>

    <xsl:template name="addManifestation">
        <xsl:param name="relRef" as="xs:integer"/>
        <xsl:param name="typeRef" as="xs:integer"/>
        <xsl:element name="Manifestation" namespace="http://www.tessella.com/XIP/v4">
            <xsl:attribute name="status">new</xsl:attribute>
            <xsl:element name="DeliverableUnitRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="xip:DeliverableUnitRef"/>
            </xsl:element>
            <xsl:element name="ManifestationRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="ext:random-uuid()"/>
            </xsl:element>

            <xsl:element name="ManifestationRelRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$relRef"/>
            </xsl:element>

            <xsl:element name="Originality" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of>true</xsl:value-of>
            </xsl:element>

            <xsl:element name="Active" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of>false</xsl:value-of>
            </xsl:element>

            <xsl:element name="TypeRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$typeRef"/>
            </xsl:element>

        </xsl:element>
        <xsl:if test="$relRef gt 2">
            <xsl:call-template name="addManifestation">
                <xsl:with-param name="typeRef" select="$typeRef"/>
                <xsl:with-param name="relRef" select="$relRef -1"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
