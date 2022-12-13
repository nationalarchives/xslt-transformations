<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tessella.com/XIP/v4"
                xmlns:csf="http://catalogue/service/functions"
                xmlns:ext="http://tna/saxon-extension"
                xmlns:dcterms="http://purl.org/dc/terms/"
                xmlns:f="http://local/functions"
                xmlns:xip="http://www.tessella.com/XIP/v4"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="dcterms f csf xip"
                version="2.0">

    <xsl:import href="du-path-function.xslt"/>
    <xsl:import href="catalogue-service-functions.xslt"/>
    <xsl:import href="decode-uri-function.xslt"/>
    <xsl:import href="common-digitised-templates.xslt"/>


    <xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>


    <xsl:param name="transcription-metadata-csv-xml-path" as="xs:string"
    >file:///home/dev/git/transformations/src/test/resources/mock-techacq-transcription-env.xml</xsl:param>
    <xsl:param name="transcription-matadata-file"  as="xs:string">tech_acq_metadata_v1_ADM362Y14B000.csv</xsl:param>

    <xsl:variable name="csv">
        <xsl:choose>
            <xsl:when test="doc-available($transcription-metadata-csv-xml-path)">
                <xsl:copy-of select="doc($transcription-metadata-csv-xml-path)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes"  select="concat('Metadata CSV ''', $transcription-metadata-csv-xml-path,''' is not available!')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="held-by" select="'The National Archives, Kew'"/>
    <xsl:variable name="datagov-root" select="'http://datagov.nationalarchives.gov.uk/'"/>
    <xsl:variable name="datagov-reference-root" select="concat($datagov-root,'66/')"/>
    <xsl:variable name="datagov-resource-root" select="concat($datagov-root,'resource/')"/>


    <xsl:variable name="part-id" select="/xip:XIP/xip:DeliverableUnits/xip:DeliverableUnit[1]/xip:CatalogueReference"/>
    <xsl:variable name="csv-schema" as="xs:string">
        <xsl:choose>
            <xsl:when test="matches($transcription-matadata-file, '[0-9]{3}.csv')">
                <xsl:value-of select="replace($transcription-matadata-file,'[0-9]{3}.csv','000.csvs')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="replace($transcription-matadata-file, '.csv','.csvs')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="csv-file-path-bare-root">
        <xsl:variable name="identifier" select="$csv/root/row[1]/elem[@name = 'file_path']/text()"/>
        <xsl:value-of select="substring-before($identifier,substring-after($part-id,'/'))"/>
    </xsl:variable>

    <!-- substitution path only needs / adding when it doesn't already end with a / -->
    <xsl:variable name="csv-file-path-root" as="xs:string"
                  select="concat($csv-file-path-bare-root, if(not(ends-with($csv-file-path-bare-root,'/')))then '/' else())"/>
    <xsl:variable name="tna-metadata-schema-uri"
                  select="xs:string('http://nationalarchives.gov.uk/metadata/tna#')"/>
    <xsl:variable name="collection-identifier"
                  select="string(/xip:XIP/xip:Collections/xip:Collection/xip:CollectionCode/text())"/>

    <xsl:key name="file-by-ref" match="xip:File" use="xip:FileRef"/>

    <xsl:key name="csv-row-by-filename" match="root/row" use="elem[@name='file_path']"/>



    <xsl:variable name="series">series</xsl:variable>
    <xsl:variable name="piece">piece</xsl:variable>
    <xsl:variable name="item">item</xsl:variable>
    <xsl:key name="row-by-series-piece-item" match="root/row"
             use="concat(elem[@name=$series] ,
             '|', elem[@name=$piece] ,
             '|', elem[@name=$item])
             "/>

    <xsl:template match="xip:XIP">
          <xsl:copy>
            <xsl:copy-of select="xmlns"/>
            <xsl:namespace name="tna" select="'http://nationalarchives.gov.uk/metadata/tna#'"/>
            <xsl:namespace name="xs" select="'http://www.w3.org/2001/XMLSchema'"/>
            <xsl:namespace name="rdf" select="'http://www.w3.org/1999/02/22-rdf-syntax-ns#'"/>
            <xsl:namespace name="rdfs" select="'http://www.w3.org/2000/01/rdf-schema#'"/>
             <xsl:apply-templates select="xip:DeliverableUnits/xip:DeliverableUnit"/>
        </xsl:copy>

    </xsl:template>

    <xsl:template match="xip:DeliverableUnit">
        <!--<xsl:copy-of select="."/>-->
        <xsl:variable name="parent" >
            <xsl:copy-of select="."/>
        </xsl:variable>


         <xsl:variable name="paths" as="element()">
            <du-path>
                <xsl:value-of select="f:getPath(./parent::xip:DeliverableUnits, .)"/>
            </du-path>
        </xsl:variable>

        <xsl:variable name="du-path" select="replace($paths/text(),' ','')"/>


        <xsl:variable name="tokenised-path" select="tokenize($du-path, '/')"/>

        <xsl:if test="count($tokenised-path) &gt; 3 ">
            <xsl:variable name="ident" select="concat(substring-after($tokenised-path[1],'_'),
            '|', $tokenised-path[3],
            '|', $tokenised-path[4])"/>

            <xsl:variable name="sub_items" select="key('row-by-series-piece-item',$ident, $csv)"/>
            <xsl:for-each select="$sub_items">
                <xsl:if test="position() != 1">
                    <xsl:variable name="du-ref" select="ext:random-uuid()"/>
                    <xsl:call-template name="create-du">
                        <xsl:with-param name="du-name" select="./elem[@name = 'sub_item']/text()"/>
                        <xsl:with-param name="parent" select="$parent/xip:DeliverableUnit"/>
                        <xsl:with-param name="du-ref" select="$du-ref"/>
                    </xsl:call-template>
                    <xsl:call-template name="create-manifestation">
                        <xsl:with-param name="du-ref" select="$du-ref"/>
                     </xsl:call-template>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>

    </xsl:template>

    <xsl:template name="create-du">
        <xsl:param name="du-name"/>
        <xsl:param name="parent"/>
        <xsl:param name="du-ref"/>

        <xsl:element name="DeliverableUnit" namespace="http://www.tessella.com/XIP/v4">
              <xsl:attribute name="status">new</xsl:attribute>
            <xsl:element name="DeliverableUnitRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$du-ref"/>
            </xsl:element>
            <xsl:element name="CollectionRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$parent/xip:CollectionRef"/>
            </xsl:element>
            <xsl:element name="AccessionRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$parent/xip:AccessionRef"/>
            </xsl:element>
            <xsl:element name="AccumulationRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$parent/xip:AccumulationRef"/>
            </xsl:element>
            <xsl:element name="ParentRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$parent/xip:DeliverableUnitRef"/>
            </xsl:element>
            <xsl:element name="DigitalSurrogate" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$parent/xip:DigitalSurrogate"/>
            </xsl:element>
            <xsl:element name="CatalogueReference" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$parent/xip:CatalogueReference"/>
            </xsl:element>
            <xsl:element name="ScopeAndContent" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$du-name"/>
            </xsl:element>
            <xsl:element name="CoverageFrom" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$parent/xip:CoverageFrom"/>
            </xsl:element>
            <xsl:element name="CoverageTo" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$parent/xip:CoverageTo"/>
            </xsl:element>
            <xsl:element name="Title" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$du-name"/>
            </xsl:element>
            <xsl:element name="TypeRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$parent/xip:TypeRef"/>
            </xsl:element>
            <xsl:element name="SecurityTag" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$parent/xip:SecurityTag"/>
            </xsl:element>
        </xsl:element>
     </xsl:template>


    <xsl:function name="f:getParentDu">
        <xsl:param name="parentRef" as="xs:string"/>
        <xsl:param name="dus" as="node()"/>
        <xsl:copy-of select="$dus/xip:DeliverableUnit[xip:DeliverableUnitRef eq $parentRef]"/>
    </xsl:function>

    <xsl:function name="f:getPath">
        <xsl:param name="dus" as="node()"/>
        <xsl:param name="du" as="node()"/>
        <xsl:if test="$du/xip:ParentRef">
            <xsl:variable name="parentDu" select="f:getParentDu($du/xip:ParentRef,$dus)"/>
            <!--<path><xsl:value-of select="$parentDu"/></path>-->
            <xsl:value-of select="f:getPath($dus, $parentDu),'/'"/>
        </xsl:if>
        <xsl:value-of select="$du/xip:ScopeAndContent"/>
    </xsl:function>

    <xsl:template name="create-manifestation">
        <xsl:param name="du-ref"/>

        <xsl:element name="Manifestation" namespace="http://www.tessella.com/XIP/v4">
            <xsl:attribute name="status">new</xsl:attribute>
            <xsl:element name="DeliverableUnitRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$du-ref"/>
            </xsl:element>
            <xsl:element name="ManifestationRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="ext:random-uuid()"/>
            </xsl:element>

            <xsl:element name="ManifestationRelRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of>1</xsl:value-of>
            </xsl:element>

            <xsl:element name="Originality" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of>true</xsl:value-of>
            </xsl:element>

            <xsl:element name="Active" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of>true</xsl:value-of>
            </xsl:element>

            <xsl:element name="TypeRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of>1</xsl:value-of>
            </xsl:element>

        </xsl:element>

    </xsl:template>

</xsl:stylesheet>
