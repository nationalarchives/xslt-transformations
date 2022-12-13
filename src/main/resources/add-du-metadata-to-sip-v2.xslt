<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tessella.com/XIP/v4"
                xmlns:csf="http://catalogue/service/functions"
                xmlns:dcterms="http://purl.org/dc/terms/"
                xmlns:f="http://local/functions"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:tna="http://nationalarchives.gov.uk/metadata/tna#"
                xmlns:xip="http://www.tessella.com/XIP/v4"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:dc="http://purl.org/dc/terms/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="dcterms f csf xip"
                version="2.0">

    <xsl:import href="du-path-function.xslt"/>
    <xsl:import href="catalogue-service-functions.xslt"/>
    <xsl:import href="decode-uri-function.xslt"/>
    <xsl:import href="common-transcriptions.xslt"/>
    <xsl:import href="common-digitised-templates.xslt"/>
    <xsl:output indent="yes"/>


    <xsl:param name="du-metadata-csv-xml-path" as="xs:string"
    >file:///home/dev/git/transformations/src/test/resources/mock-techacq-transcription-env.xml
    </xsl:param>


    <xsl:variable name="csv">
        <xsl:choose>
            <xsl:when test="doc-available($du-metadata-csv-xml-path)">
                <xsl:copy-of select="doc($du-metadata-csv-xml-path)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes"
                             select="concat('Metadata CSV ''', $du-metadata-csv-xml-path,''' is not available!')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="held-by" select="'The National Archives, Kew'"/>
    <xsl:variable name="datagov-root" select="'http://datagov.nationalarchives.gov.uk/'"/>
    <xsl:variable name="datagov-reference-root" select="concat($datagov-root,'66/')"/>
    <xsl:variable name="datagov-resource-root" select="concat($datagov-root,'resource/')"/>


    <xsl:variable name="part-id" select="/xip:XIP/xip:DeliverableUnits/xip:DeliverableUnit[1]/xip:CatalogueReference"/>


    <!-- substitution path only needs / adding when it doesn't already end with a / -->

    <xsl:variable name="tna-metadata-schema-uri"
                  select="xs:string('http://nationalarchives.gov.uk/metadata/tna#')"/>

    <xsl:variable name="collection-identifier"
                  select="string(/xip:XIP/xip:Collections/xip:Collection/xip:CollectionCode/text())"/>


    <xsl:variable name="series">series</xsl:variable>
    <xsl:variable name="piece">piece</xsl:variable>
    <xsl:variable name="item">item</xsl:variable>
    <xsl:variable name="sub-item">sub_item</xsl:variable>
    <xsl:key name="row-by-series-piece-item-sub-item" match="root/row"
             use="concat(elem[@name=$series] ,
             '|', elem[@name=$piece] ,
             '|', elem[@name=$item],
             '|', elem[@name=$sub-item])
             "/>

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
            <xsl:copy-of select="xmlns"/>
            <xsl:namespace name="tna" select="'http://nationalarchives.gov.uk/metadata/tna#'"/>
            <xsl:namespace name="xs" select="'http://www.w3.org/2001/XMLSchema'"/>
            <xsl:namespace name="rdf" select="'http://www.w3.org/1999/02/22-rdf-syntax-ns#'"/>
            <xsl:namespace name="rdfs" select="'http://www.w3.org/2000/01/rdf-schema#'"/>
            <xsl:apply-templates/>
        </xsl:copy>

    </xsl:template>

    <xsl:template match="xip:DeliverableUnit">
        <xsl:variable name="du-title-path" select="f:du-path(., node-name(xip:Title))"/>
        <xsl:variable name="encoded-du-title-path"
                      select="for $p in $du-title-path return encode-for-uri($p)"/>

        <!-- create a file path from the du-title-path -->
        <xsl:variable name="du-file-path" select="string-join($encoded-du-title-path, '/')"/>

        <xsl:variable name="paths" as="element()">
            <du-path>
                <xsl:value-of select="f:getPath(./parent::xip:DeliverableUnits, .)"/>
            </du-path>
        </xsl:variable>

        <xsl:variable name="du-path" select="replace($paths/text(),' ','')"/>


        <xsl:variable name="tokenised-path" select="tokenize($du-path, '/')"/>

        <xsl:variable name="csv-row-identifier" select="concat(substring-after($tokenised-path[1],'_'),
            '|', $tokenised-path[3],
            '|', $tokenised-path[4],
            '|', $tokenised-path[5])"/>

        <!-- calculate the row identifer for use in the CSV file -->
        <xsl:variable name="csv-row" as="node()*">
            <xsl:choose>
                <!-- use key to speed lookup in the most common case -->
                <xsl:when test="key('row-by-series-piece-item-sub-item', $csv-row-identifier, $csv)">
                    <!-- if we have an exact match in the CSV use this row information -->
                    <xsl:copy-of
                            select="key('row-by-series-piece-item-sub-item',$csv-row-identifier, $csv)"/>
                </xsl:when>
                <!-- can't repeat the key lookup trick with the other two cases, but they are hopefully rarer-->
                <xsl:when
                        test="$csv/root/row[elem/@name = 'file_path'][elem/text()[starts-with(., $csv-row-identifier)]][1]">
                    <xsl:message>
                        <xsl:value-of select="concat($csv-row-identifier, ' partially contained in csv file')"/>
                    </xsl:message>
                    <xsl:copy-of
                            select="$csv/root/row[elem/@name = 'file_path'][elem/text()[contains(., $csv-row-identifier)]][1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- surely should never happen? shouldn't we terminate if so? GS -->
                    <xsl:message>
                         <xsl:value-of select="concat($csv-row-identifier, ' not found in csv file - maybe series')"/>
                    </xsl:message>
                    <!-- the series row does not exist so use the first row (piece row) to get cataloging data -->
                    <xsl:copy-of select="$csv/root/row[1]"/>
                </xsl:otherwise>
            </xsl:choose>

        </xsl:variable>

        <xsl:copy>
            <xsl:copy-of select="@status"/>
            <xsl:variable name="children" select="child::*" as="element()+"/>
            <xsl:copy-of
                    select="$children[position() le index-of($children/local-name(.), 'SecurityTag')]"/>

            <xsl:variable name="tokenized-path" select="tokenize($du-path, '/')"/>
            <xsl:variable name="department" select="substring-before($tokenized-path[1],'_')"/>
            <xsl:variable name="series" select="substring-after($tokenized-path[1],'_')"/>
            <xsl:choose>
                <xsl:when test="count($tokenized-path) eq 1 and $csv-row">
                    <!-- we have a series level du -->
                    <xsl:element name="Metadata" namespace="http://www.tessella.com/XIP/v4">
                        <xsl:attribute name="schemaURI" select="$tna-metadata-schema-uri"/>
                        <tna:metadata>
                            <rdf:RDF>
                                <tna:DigitalFolder>
                                    <xsl:attribute name="rdf:about">
                                        <xsl:value-of select="concat($datagov-reference-root,$department,'/',$series)"/>
                                    </xsl:attribute>
                                    <tna:cataloguing>
                                        <tna:Cataloguing>
                                            <xsl:call-template
                                                    name="create-collection-to-series-metadata">
                                                <xsl:with-param name="csv-row" select="$csv-row"/>
                                                <xsl:with-param name="department"
                                                                select="$department"/>
                                                <xsl:with-param name="series" select="$series"/>
                                                <xsl:with-param name="collection-identifier"
                                                                select="$collection-identifier"/>
                                            </xsl:call-template>
                                            <xsl:call-template name="create-legal-metadata">
                                                <xsl:with-param name="csv-row" select="$csv-row"/>
                                             </xsl:call-template>
                                        </tna:Cataloguing>
                                    </tna:cataloguing>
                                    <!-- series level folder -->
                                    <tna:digitalFile>
                                        <tna:DigitalFile>
                                            <tna:filePathAndName rdf:datatype="xs:string">
                                                <xsl:value-of select="$du-file-path"/>
                                            </tna:filePathAndName>
                                        </tna:DigitalFile>
                                    </tna:digitalFile>
                                </tna:DigitalFolder>
                            </rdf:RDF>
                        </tna:metadata>
                    </xsl:element>
                </xsl:when>
                <xsl:when test="count($tokenized-path) eq 3">
                    <!-- we have a piece level du -->
                    <xsl:variable name="piece" select="$tokenized-path[3]"/>
                    <xsl:element name="Metadata" namespace="http://www.tessella.com/XIP/v4">
                        <xsl:attribute name="schemaURI" select="$tna-metadata-schema-uri"/>
                        <tna:metadata>
                            <rdf:RDF>
                                <tna:DigitalFolder>
                                    <xsl:attribute name="rdf:about">
                                        <xsl:value-of
                                                select="concat($datagov-reference-root,$department,'/',$series,'/',$piece)"/>
                                    </xsl:attribute>
                                    <tna:cataloguing>
                                        <tna:Cataloguing>
                                            <xsl:call-template
                                                    name="create-collection-to-series-metadata">
                                                <xsl:with-param name="csv-row" select="$csv-row"/>
                                                <xsl:with-param name="department"
                                                                select="$department"/>
                                                <xsl:with-param name="series" select="$series"/>
                                                <xsl:with-param name="collection-identifier"
                                                                select="$collection-identifier"/>
                                            </xsl:call-template>
                                            <tna:pieceIdentifier rdf:datatype="xs:decimal">
                                                <xsl:value-of select="$csv-row/elem[@name eq 'piece']/text()"/>
                                            </tna:pieceIdentifier>
                                            <xsl:if test="$csv-row/elem[@name eq 'iaid'] !=''">
                                                <tna:iaid rdf:datatype="xs:string">
                                                    <xsl:value-of select="$csv-row/elem[@name eq 'iaid']"/>
                                                </tna:iaid>
                                            </xsl:if>
                                            <dc:description rdf:datatype="xs:string">
                                                <xsl:value-of
                                                        select="$csv-row/elem[@name eq 'description']"/>
                                            </dc:description>
                                            <xsl:call-template name="create-coverage">
                                                <xsl:with-param name="csv-row" select="$csv-row"/>
                                            </xsl:call-template>
                                            <xsl:call-template name="create-legal-metadata">
                                                <xsl:with-param name="csv-row" select="$csv-row"/>
                                            </xsl:call-template>
                                        </tna:Cataloguing>
                                    </tna:cataloguing>
                                    <tna:digitalFile>
                                        <tna:DigitalFile>
                                            <tna:filePathAndName rdf:datatype="xs:string">
                                                <xsl:value-of select="$du-file-path"/>
                                            </tna:filePathAndName>
                                        </tna:DigitalFile>
                                    </tna:digitalFile>
                                </tna:DigitalFolder>
                            </rdf:RDF>
                        </tna:metadata>
                    </xsl:element>
                </xsl:when>
                <xsl:when test="count($tokenized-path) eq 4">
                    <!-- we have an item level du -->
                    <xsl:variable name="piece" select="$tokenized-path[3]"/>
                    <xsl:variable name="item" select="$tokenized-path[4]"/>
                    <xsl:element name="Metadata" namespace="http://www.tessella.com/XIP/v4">
                        <xsl:attribute name="schemaURI" select="$tna-metadata-schema-uri"/>
                        <tna:metadata>
                            <rdf:RDF>
                                <tna:DigitalFolder>
                                    <xsl:attribute name="rdf:about">
                                        <xsl:value-of
                                                select="concat($datagov-reference-root,$department,'/',$series,'/',$piece, '/', $item)"
                                        />
                                    </xsl:attribute>
                                    <xsl:call-template name="create-item-cataloguing">
                                        <xsl:with-param name="csv-row" select="$csv-row"/>
                                        <xsl:with-param name="collection-identifier"
                                                        select="$collection-identifier"/>
                                        <xsl:with-param name="datagov-resource-root"
                                                        select="$datagov-resource-root"/>
                                    </xsl:call-template>
                                    <tna:digitalFile>
                                        <tna:DigitalFile>
                                            <tna:filePathAndName rdf:datatype="xs:string">
                                                <xsl:value-of select="$du-file-path"/>
                                            </tna:filePathAndName>
                                        </tna:DigitalFile>
                                    </tna:digitalFile>
                                    <xsl:call-template name="create-transcription">
                                        <xsl:with-param name="csv-row" select="$csv-row"/>
                                    </xsl:call-template>
                                </tna:DigitalFolder>
                            </rdf:RDF>
                        </tna:metadata>
                    </xsl:element>
                </xsl:when>
                <xsl:when test="count($tokenized-path) eq 5">
                    <!-- we have an sub-itemitem level du -->
                    <xsl:variable name="piece" select="$tokenized-path[3]"/>
                    <xsl:variable name="item" select="$tokenized-path[4]"/>
                    <xsl:variable name="sub-item" select="$tokenized-path[5]"/>
                    <xsl:element name="Metadata" namespace="http://www.tessella.com/XIP/v4">
                        <xsl:attribute name="schemaURI" select="$tna-metadata-schema-uri"/>
                        <tna:metadata>
                            <rdf:RDF>
                                <tna:DigitalFolder>
                                    <xsl:attribute name="rdf:about">
                                        <xsl:value-of
                                                select="concat($datagov-reference-root,$department,'/',$series,'/',$piece, '/', $item,'/', $sub-item)"
                                        />
                                    </xsl:attribute>
                                    <xsl:call-template name="create-item-cataloguing">
                                        <xsl:with-param name="csv-row" select="$csv-row"/>
                                        <xsl:with-param name="collection-identifier"
                                                        select="$collection-identifier"/>
                                        <xsl:with-param name="datagov-resource-root"
                                                        select="$datagov-resource-root"/>
                                    </xsl:call-template>
                                    <tna:digitalFile>
                                        <tna:DigitalFile>
                                            <tna:filePathAndName rdf:datatype="xs:string">
                                                <xsl:value-of select="$du-file-path"/>
                                            </tna:filePathAndName>
                                        </tna:DigitalFile>
                                    </tna:digitalFile>
                                    <xsl:call-template name="create-transcription">
                                        <xsl:with-param name="csv-row" select="$csv-row"/>
                                    </xsl:call-template>

                                </tna:DigitalFolder>
                            </rdf:RDF>
                        </tna:metadata>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <!-- we only put metadata in series, piece or item level dus -->
                </xsl:otherwise>
            </xsl:choose>

            <xsl:copy-of
                    select="$children[position() gt index-of($children/local-name(.), 'SecurityTag')]"/>

        </xsl:copy>
    </xsl:template>


    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
