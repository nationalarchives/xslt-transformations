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

    <xsl:param name="closure-csv-xml-path" as="xs:string"/>
    <xsl:param name="metadata-csv-xml-path" as="xs:string"/>
    <xsl:variable name="ret-rec-vals-split" select="','"/>
    <xsl:variable name="ret-rec-split" select="'ZZZ'"/>

    <xsl:variable name="metadata-csv">
        <xsl:choose>
            <xsl:when test="doc-available($metadata-csv-xml-path)">
                <xsl:copy-of select="doc($metadata-csv-xml-path)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes"
                             select="concat('Metadata CSV ''', $metadata-csv-xml-path,''' is not available!')"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:key name="row-by-filepath" match="root/row"
             use="f:decode-uri(string(elem[@name eq 'identifier']/text()))"/>

    <!-- All retained records are listed in the closure csv. Use this to determine if new SIP elements required  -->
    <xsl:variable name="closure-csv">
        <xsl:choose>
            <xsl:when test="doc-available($closure-csv-xml-path)">
                <xsl:copy-of select="doc($closure-csv-xml-path)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes"
                             select="concat('Metadata CSV ''', $closure-csv-xml-path,''' is not available!')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- the content folder is the root folder from which working path is resolved this needs to be in the csv file
         csv file://home/wherever/I/put/my/data/on my machine/series/content/{files or folders}
         xip working path content/{files or folder}
         shortest value in csv will be used to get content
    -->
    <xsl:variable name="csv-file-path-root">
        <xsl:variable name ="shortest-path" select="f:shortest-value-of-row($closure-csv,'identifier')"/>
        <xsl:variable name="content-folder" select="'content/'"/>
        <xsl:value-of select="substring($shortest-path,1,(string-length($shortest-path) - string-length($content-folder) ))"/>
    </xsl:variable>

    <xsl:variable name="collection-identifier"
                  select="string(/xip:XIP/xip:Collections/xip:Collection/xip:CollectionCode/text())"/>

    <xsl:variable name="ingested-file-set-ref"
                  select="string(/xip:XIP/xip:IngestedFileSets/xip:IngestedFileSet/xip:IngestedFileSetRef/text())"/>

    <xsl:key name="file-by-title" match="xip:DeliverableUnits/xip:DeliverableUnit" use="xip:Title"/>

    <xsl:variable name="retained-file-csv-rows" select="$closure-csv/root/row[elem[@name = 'retention_type'] != '']/elem[@name='identifier'] "/>

    <xsl:variable name="identifier-du-and-file-uuids">
          <xsl:for-each select="1 to count($retained-file-csv-rows)">
             <xsl:variable name="position" select="position()"/>
              <xsl:variable name="end">
                  <xsl:choose>
                      <xsl:when  test="$position &lt; count($retained-file-csv-rows)">
                          <xsl:value-of select="$ret-rec-split"/>
                      </xsl:when>
                      <xsl:otherwise>
                          <xsl:value-of select="''"/>
                      </xsl:otherwise>
                  </xsl:choose>
              </xsl:variable>
             <xsl:value-of select="concat($retained-file-csv-rows[$position]/text(),$ret-rec-vals-split,ext:random-uuid(),$ret-rec-vals-split,ext:random-uuid(), $end)"/>
        </xsl:for-each>
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
        <xsl:element name="DeliverableUnits">
            <xsl:call-template name="create-dus">
               <xsl:with-param name="dus" select="."/>
            </xsl:call-template>
            <xsl:apply-templates/>
            <xsl:call-template name="create-manifestations"></xsl:call-template>
        </xsl:element>
    </xsl:template>

    <xsl:template match="xip:Files">
        <xsl:element name="Files">
            <xsl:apply-templates/>
            <xsl:call-template name="create-files">
                <xsl:with-param name="dus" select="../xip:DeliverableUnits"/>
            </xsl:call-template>
        </xsl:element>
    </xsl:template>

    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@*, node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xip:DeliverableUnit">
        <xsl:copy-of select="."/>
    </xsl:template>


    <xsl:template name="create-files">
        <xsl:param name="dus"/>
        <xsl:variable name="retained-rec" select="tokenize($identifier-du-and-file-uuids,$ret-rec-split)"/>
        <xsl:for-each select="$retained-rec">
            <xsl:variable name="ret-rec-vals" select="tokenize(.,$ret-rec-vals-split)"/>
             <xsl:variable name="metadata-identifier"
                          select="$ret-rec-vals[1]"/>
            <xsl:variable name="identifier"
                          select="substring-after($metadata-identifier,$csv-file-path-root)"/>
            <xsl:variable name="parent">
                <xsl:call-template name="substring-before-last">
                    <xsl:with-param name="input" select="$identifier"/>
                    <xsl:with-param name="substr" select="'/'"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="csv-row" select="$metadata-csv/key('row-by-filepath',$metadata-identifier)"/>
            <xsl:call-template name="create-file">
                <xsl:with-param name="file-ref" select="$ret-rec-vals[3]"/>
                <xsl:with-param name="file-name" select="tokenize($identifier,'/')[last()]"/>
                <xsl:with-param name="working-path" select="$parent"/>
                <xsl:with-param name="checksum" select="$csv-row/elem[@name = 'checksum']/text()"/>
                <xsl:with-param name="date_last_modified"
                                select="$csv-row/elem[@name = 'date_last_modified']/text()"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>


    <xsl:template name="create-manifestations">
        <xsl:variable name="retained-records" select="tokenize($identifier-du-and-file-uuids,$ret-rec-split)"/>
        <xsl:for-each select="$retained-records">
            <xsl:variable name="ret-rec-vals" select="tokenize(.,$ret-rec-vals-split)"/>
            <xsl:variable name="identifier"
                          select="substring-after($ret-rec-vals[1],$csv-file-path-root)"/>
            <xsl:variable name="parent">
                <xsl:call-template name="substring-before-last">
                    <xsl:with-param name="input" select="$identifier"/>
                    <xsl:with-param name="substr" select="'/'"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:call-template name="create-manifestation">
                <xsl:with-param name="du-ref" select="$ret-rec-vals[2]"/>
                <xsl:with-param name="file-ref" select="$ret-rec-vals[3]"/>
                <xsl:with-param name="file-path" select="$parent"/>
                <xsl:with-param name="manifestation-ref" select="ext:random-uuid()"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

     <xsl:template name="create-dus">
        <xsl:param name="dus"/>
         <xsl:variable name="retained-records" select="tokenize($identifier-du-and-file-uuids,$ret-rec-split)"/>
         <xsl:for-each select="$retained-records">
            <xsl:variable name="ret-rec-vals" select="tokenize(.,$ret-rec-vals-split)"/>
            <xsl:variable name="identifier"
                          select="substring-after($ret-rec-vals[1],$csv-file-path-root)"/>
            <xsl:variable name="parentDU" select="f:selectParent($ret-rec-vals[1],$dus)"/>
            <xsl:call-template name="create-du">
                <xsl:with-param name="du-name" select="tokenize($identifier,'/')[last()]"/>
                <xsl:with-param name="du-ref" select="$ret-rec-vals[2]"/>
                <xsl:with-param name="parent" select="$parentDU"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <xsl:function name="f:selectParent">
        <xsl:param name="retainedRecord"/>
        <xsl:param name="dus"/>

        <xsl:variable name="identifier"
                      select="substring-after($retainedRecord,$csv-file-path-root)"/>

       <xsl:variable name="parent">
            <xsl:call-template name="substring-before-last">
                <xsl:with-param name="input" select="$identifier"/>
                <xsl:with-param name="substr" select="'/'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="parents" select="key('file-by-title',tokenize($parent,'/')[last()],$dus)"/>
        <xsl:copy-of select="f:checkFullPath($parent,$parents,$dus)"/>

    </xsl:function>

    <!-- There could be many folders with the same name so need to check full path to ensure the correct parent is identified -->
    <xsl:function name="f:checkFullPath">
        <xsl:param name="parentPath"/>
        <xsl:param name="possibles"/>
        <xsl:param name="dus"/>
        <xsl:copy-of select="f:checkFullPathWorker($parentPath,$possibles,count($possibles),$dus)"/>
    </xsl:function>

    <xsl:function name="f:checkFullPathWorker">
        <xsl:param name="parentPath"/>
        <xsl:param name="possibles"/>
        <xsl:param name="possibleIndex"/>
        <xsl:param name="dus"/>
        <xsl:choose>
            <xsl:when test="f:getPath($dus,$possibles[$possibleIndex],'') eq concat($parentPath,'/')">
               <xsl:copy-of select="$possibles[$possibleIndex]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="f:checkFullPathWorker($parentPath,$possibles,$possibleIndex -1,$dus)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template name="substring-before-last">
        <xsl:param name="input"/>
        <xsl:param name="substr"/>
        <xsl:if test="$substr and contains($input, $substr)">
            <xsl:variable name="temp" select="substring-after($input, $substr)"/>
            <xsl:value-of select="substring-before($input, $substr)"/>
            <xsl:if test="contains($temp, $substr)">
                <xsl:value-of select="$substr"/>
                <xsl:call-template name="substring-before-last">
                    <xsl:with-param name="input" select="$temp"/>
                    <xsl:with-param name="substr" select="$substr"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <xsl:function name="f:getParentDu">
        <xsl:param name="parentRef" as="xs:string"/>
        <xsl:param name="dus" as="node()"/>
        <xsl:copy-of select="$dus/xip:DeliverableUnit[xip:DeliverableUnitRef eq $parentRef]"/>
    </xsl:function>

    <xsl:function name="f:getPath">
        <xsl:param name="dus" as="node()"/>
        <xsl:param name="du" as="node()"/>
        <xsl:param name="path" as="xs:string"/>
        <xsl:choose>
             <xsl:when test="$du/xip:ParentRef">
                <xsl:variable name="parentDu" select="f:getParentDu($du/xip:ParentRef,$dus)"/>
                <xsl:value-of select="f:getPath($dus, $parentDu,concat($du/xip:ScopeAndContent/text(),'/',$path))"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- root element not used for working path -->
                <xsl:value-of select="$path"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

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

    <xsl:template name="create-manifestation">
        <xsl:param name="du-ref"/>
        <xsl:param name="manifestation-ref"/>
        <xsl:param name="file-ref"/>
        <xsl:param name="file-path"/>
        <xsl:element name="Manifestation" namespace="http://www.tessella.com/XIP/v4">
            <xsl:attribute name="status">new</xsl:attribute>
            <xsl:element name="DeliverableUnitRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$du-ref"/>
            </xsl:element>
            <xsl:element name="ManifestationRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$manifestation-ref"/>
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
            <xsl:element name="ManifestationFile" namespace="http://www.tessella.com/XIP/v4">
                <xsl:attribute name="status">new</xsl:attribute>
                <xsl:element name="FileRef" namespace="http://www.tessella.com/XIP/v4">
                    <xsl:value-of select="$file-ref"/>
                </xsl:element>
                <xsl:element name="Path" namespace="http://www.tessella.com/XIP/v4">
                    <xsl:value-of select="$file-path"/>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template name="create-file">
        <xsl:param name="file-name"/>
        <xsl:param name="file-ref"/>
        <xsl:param name="working-path"/>
        <xsl:param name="checksum"/>
        <xsl:param name="date_last_modified"/>
        <xsl:element name="File" namespace="http://www.tessella.com/XIP/v4">
            <xsl:attribute name="status">new</xsl:attribute>
            <xsl:element name="FileRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$file-ref"/>
            </xsl:element>
            <xsl:element name="IngestedFileSetRef" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$ingested-file-set-ref"/>
            </xsl:element>
            <xsl:element name="FileName" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$file-name"/>
            </xsl:element>
            <xsl:element name="Extant" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="false()"/>
            </xsl:element>
            <xsl:element name="Directory" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="false()"/>
            </xsl:element>
            <xsl:element name="FileSize">
                <xsl:value-of select="888"/>
            </xsl:element>
            <xsl:element name="LastModifiedDate">
                <xsl:choose>
                    <xsl:when test="$date_last_modified ne ''">
                        <xsl:value-of select="$date_last_modified"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="current-dateTime()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element>
            <xsl:element name="FixityInfo">
                <xsl:element name="FixityAlgorithmRef">
                    <xsl:value-of select="3"/>
                </xsl:element>
                <xsl:element name="FixityValue">
                    <xsl:choose>
                        <xsl:when test="$checksum ne ''">
                            <xsl:value-of select="$checksum"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="999"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
            </xsl:element>
            <xsl:element name="WorkingPath" namespace="http://www.tessella.com/XIP/v4">
                <xsl:value-of select="$working-path"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>
