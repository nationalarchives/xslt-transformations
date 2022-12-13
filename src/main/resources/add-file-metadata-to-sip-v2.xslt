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
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="dcterms f csf xip"
                version="2.0">

    <xsl:import href="du-path-function.xslt"/>
    <xsl:import href="catalogue-service-functions.xslt"/>
    <xsl:import href="decode-uri-function.xslt"/>
    <xsl:import href="common-transcriptions.xslt"/>
    <xsl:import href="common-digitised-templates.xslt"/>
    <xsl:output indent="yes"/>



    <xsl:param name="file-metadata-csv-xml-path" as="xs:string"
        >file:///home/dev/git/transformations/src/test/resources/mock-techacq-transcription-env.xml</xsl:param>

    <xsl:param name="file-matadata-csv-schema-name" as="xs:string">tech_acq_metadata_v1_ADM362Y14B000.csv</xsl:param>



    <xsl:variable name="isSurrogate">
        <xsl:choose>
            <xsl:when test="xip:XIP/xip:Collections/xip:Collection[1]/xip:SecurityTag = 'Surrogate'">
                <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="csv">
        <xsl:choose>
            <xsl:when test="doc-available($file-metadata-csv-xml-path)">
                <xsl:copy-of select="doc($file-metadata-csv-xml-path)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes"  select="concat('Metadata CSV ''', $file-metadata-csv-xml-path,''' is not available!')"/>
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
            <xsl:when test="matches($file-matadata-csv-schema-name, '[0-9]{3}.csv')">
                <xsl:value-of select="replace($file-matadata-csv-schema-name,'[0-9]{3}.csv','000.csvs')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="replace($file-matadata-csv-schema-name, '.csv','.csvs')"/>
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

    <xsl:template match="xip:XIP">

        <xsl:copy>
           <xsl:apply-templates/>
        </xsl:copy>

    </xsl:template>

    <xsl:template match="xip:ManifestationFile">
        <xsl:copy>
            <xsl:copy-of select="@status"/>
            <xsl:choose>
                <xsl:when test="xip:Path ne '/'">
                    <xsl:variable name="file-name"
                                  select="key('file-by-ref', xip:FileRef)/xip:FileName/text()"/>
                    <xsl:variable name="file-path" as="xs:string"
                                  select="concat($csv-file-path-root, substring-after($part-id,'/'), '/', concat(xip:Path,'/', $file-name))"/>
                    <xsl:variable name="csv-row"
                                  select="key('csv-row-by-filename', $file-path, $csv)"/>
                    <xsl:element name="FileRef" namespace="http://www.tessella.com/XIP/v4">
                        <xsl:value-of select="$csv-row/elem[@name eq 'file_uuid']"/>
                    </xsl:element>
                    <xsl:copy-of select="xip:Path"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xip:File">

        <xsl:variable name="file-name" as="xs:string"
                      select="concat($csv-file-path-root, substring-after($part-id,'/'), '/', if(xip:WorkingPath ne '/')then concat(xip:WorkingPath,'/') else(), xip:FileName)"/>
        <!-- <xsl:message terminate="no"><xsl:value-of select="concat('$csv-file-path-root = ', $csv-file-path-root, ' $part-id = ', $part-id, ' $file-name = ', $file-name)"/></xsl:message>-->

        <xsl:variable name="csv-row" select="key('csv-row-by-filename', $file-name, $csv)"/>
        <xsl:copy>
            <xsl:copy-of select="@status"/>
            <xsl:variable name="children" select="child::*[position() ne 1]" as="element()+"/>
            <xsl:choose>
                <xsl:when test="xip:WorkingPath ne '/'">
                    <!-- we are not interested in adding metadata to the actual metadata files that reside in the root-->
                    <!-- <xsl:variable name="children" select="child::*" as="element()+"/> -->
                    <xsl:element name="FileRef" namespace="http://www.tessella.com/XIP/v4">
                        <xsl:value-of select="$csv-row/elem[@name eq 'file_uuid']"/>
                    </xsl:element>
                    <xsl:copy-of
                            select="$children[position() le index-of($children/local-name(.), 'Directory')]"/>
                    <xsl:element name="Metadata" namespace="http://www.tessella.com/XIP/v4">
                        <xsl:attribute name="schemaURI" select="$tna-metadata-schema-uri"/>
                        <tna:metadata>
                            <rdf:RDF>
                                <xsl:choose>
                                    <xsl:when test="$isSurrogate = true()">
                                        <tna:DigitalSurrogate>
                                            <xsl:call-template name="add-file-info">
                                                <xsl:with-param name="csv-row" select="$csv-row"/>
                                            </xsl:call-template>
                                        </tna:DigitalSurrogate>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <tna:DigitalRecord>
                                            <xsl:call-template name="add-file-info">
                                                <xsl:with-param name="csv-row" select="$csv-row"/>
                                            </xsl:call-template>
                                        </tna:DigitalRecord>
                                    </xsl:otherwise>
                                </xsl:choose>
                          </rdf:RDF>
                        </tna:metadata>
                    </xsl:element>
                    <xsl:copy-of
                            select="$children[position() gt index-of($children/local-name(.), 'Directory')]"
                    />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>

        </xsl:copy>
    </xsl:template>


    <xsl:template name="add-file-info">
        <xsl:param name="csv-row" as="node()"/>
        <xsl:attribute name="rdf:about">
            <xsl:value-of
                    select="$csv-row/elem[@name eq 'resource_uri']"/>
        </xsl:attribute>
        <xsl:call-template name="create-file-cataloguing">
            <xsl:with-param name="csv-row" select="$csv-row"/>
            <xsl:with-param name="collection-identifier"
                            select="$collection-identifier"/>
            <xsl:with-param name="datagov-resource-root"
                            select="$datagov-resource-root"/>
        </xsl:call-template>
        <xsl:call-template name="create-digital-file">
            <xsl:with-param name="csv-row" select="$csv-row"/>
        </xsl:call-template>

        <xsl:call-template name="create-provenance">
            <xsl:with-param name="csv-row" select="$csv-row"/>
        </xsl:call-template>

        <xsl:call-template name="create-digital-image">
            <xsl:with-param name="csv-row" select="$csv-row"/>
        </xsl:call-template>

        <xsl:if test="$csv-row/elem[@name eq 'comments'] ne ''">
            <rdfs:comment rdf:datatype="xs:string">
                <xsl:value-of
                        select="$csv-row/elem[@name eq 'comments']"/>
            </rdfs:comment>
        </xsl:if>
    </xsl:template>


    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
