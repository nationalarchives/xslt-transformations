<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns="http://www.tessella.com/XIP/v4"
    xmlns:dcterms="http://purl.org/dc/terms/" xpath-default-namespace="http://www.tessella.com/XIP/v4"
    xmlns:ext="http://tna/saxon-extension"
    xmlns:fntc="http://tna.gov.uk/transform/functions/common"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:tna="http://nationalarchives.gov.uk/metadata/tna#"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xip="http://www.tessella.com/XIP/v4" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    exclude-result-prefixes="dcterms ext fntc rdf tna xip xs xsi">

    <!-- 
        Rearrange the metadata file generated by the SDB SIP generator and the corresponding physical files so that:
        - TNA-internal metadata and closure files are held in a new subtree starting _metadata/[unit]/[series]
        - Source DUs are removed from the content DU (which is deleted) 
        - The series is renamed with underscores replaced by spaces outside _metadata
        - The path in metadata generated by add-born-digital-metadata-to-sip is rewritten
        
        Graham Seaman 2014-02-13
    -->

    <xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>

    <xsl:param name="contentLocation"
        select="'/var/spool/sdb4/jobqueue/WF/34b10f11-f22d-45cc-8f9a-f4a2db7f196e/ecfc5232-c502-4a77-8268-0f04664f7e23/25d0acf6-171a-4677-abe4-2e3feaf16bed/content'"/>

    <xsl:param name="born-digital" select="'true'"/>

    <!-- xproc always sends parameters as strings? -->
    <xsl:param name="testing" select="'false'" as="xs:string"/>

    <xsl:variable name="security-tag">
        <xsl:value-of select="/XIP/Collections/Collection/SecurityTag"/>
    </xsl:variable>

    <xsl:variable name="root-du" as="node()">
        <xsl:copy-of select="/XIP/DeliverableUnits/DeliverableUnit[not(ParentRef)]"/>
    </xsl:variable>

    <xsl:variable name="root-uuid" as="xs:string">
        <xsl:value-of
            select="/XIP/DeliverableUnits/DeliverableUnit[not(ParentRef)]/DeliverableUnitRef"/>
    </xsl:variable>

    <xsl:variable name="unit" as="xs:string">
        <xsl:value-of
            select="substring-before(/XIP/DeliverableUnits/DeliverableUnit[not(ParentRef)]/CatalogueReference, '/')"
        />
    </xsl:variable>

    <xsl:variable name="series" as="xs:string">
        <xsl:value-of
            select="/XIP/DeliverableUnits/DeliverableUnit[(not(ParentRef)) and (not(ScopeAndContent = '_metadata'))]/ScopeAndContent"
        />
    </xsl:variable>

    <xsl:variable name="displayable-series" as="xs:string">
        <xsl:value-of select="translate($series, '_', ' ')"/>
    </xsl:variable>

    <!-- UUIDs for new DUs to be generated -->
    <xsl:variable name="content-uuid" as="xs:string">
        <xsl:value-of
            select="/XIP/DeliverableUnits/DeliverableUnit[Title='content']/DeliverableUnitRef"/>
    </xsl:variable>

    <xsl:variable name="metadata-uuid" as="xs:string">
        <xsl:value-of select="ext:random-uuid()"/>
    </xsl:variable>

    <xsl:variable name="metadata-unit-uuid" as="xs:string">
        <xsl:value-of select="ext:random-uuid()"/>
    </xsl:variable>

    <xsl:variable name="metadata-series-uuid" as="xs:string">
        <xsl:value-of select="ext:random-uuid()"/>
    </xsl:variable>

    <!-- main -->
    <xsl:template match="XIP">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="/XIP/Collections"/>
            <xsl:copy-of select="/XIP/Aggregations"/>
            
            <xsl:variable name="metadata-file-du-uuids" as="element()*">
                <xsl:for-each select="/XIP/Files/File[WorkingPath = '/']">
                    <uuid>
                        <xsl:value-of select="ext:random-uuid()"/>
                    </uuid>
                </xsl:for-each>
            </xsl:variable>
            
            <DeliverableUnits>
                <xsl:call-template name="create-du">
                    <xsl:with-param name="uuid" select="$metadata-uuid"/>
                    <xsl:with-param name="du-name">
                        <xsl:text>_metadata</xsl:text>
                    </xsl:with-param>                                       
                </xsl:call-template>
                <xsl:call-template name="create-du">
                    <xsl:with-param name="uuid" select="$metadata-unit-uuid"/>
                    <xsl:with-param name="du-name" select="$unit"/>
                    <xsl:with-param name="parent" select="$metadata-uuid"/>
                </xsl:call-template>
                <xsl:call-template name="create-du">
                    <xsl:with-param name="uuid" select="$metadata-series-uuid"/>
                    <xsl:with-param name="du-name" select="$series"/>
                    <xsl:with-param name="parent" select="$metadata-unit-uuid"/>
                </xsl:call-template>
                
                <xsl:if test="$born-digital != 'true'">
                    <xsl:for-each select="/XIP/Files/File[WorkingPath = '/']">
                        <xsl:variable name="pos" select="position()"/>
                        <xsl:call-template name="create-du">
                            <xsl:with-param name="uuid" select="$metadata-file-du-uuids[$pos]"/>
                            <xsl:with-param name="du-name" select="FileName"/>
                            <xsl:with-param name="parent" select="$metadata-series-uuid"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                
                <!-- reproduce all the metadata dus, now within the new structure -->
                <xsl:apply-templates
                    select="/XIP/DeliverableUnits/DeliverableUnit[ParentRef=$root-uuid and Title !='content']"/>
                
                <!-- rename the content folder with the new name -->
                <xsl:variable name="from" select="concat($contentLocation, '/content')"/>
                <xsl:variable name="to" select="concat($contentLocation, '/', $displayable-series)"/>
                <xsl:message
                    select="concat('XSLT FileSystem: Renaming ''', $from, ''' to ''', $to, '''')"/>
                 <xsl:choose>
                    <xsl:when test="$testing = 'true'">
                        <xsl:if test="not(ext:file-exists(xs:string($to)))">
                            <xsl:sequence select="ext:rename-file($from, $to)"/>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="ext:rename-file($from, $to)"/>
                    </xsl:otherwise>
                </xsl:choose>
                
                
                <!-- reproduce all the non-metadata deliverable units within the content/series folder -->
                <xsl:apply-templates
                    select="/XIP/DeliverableUnits/DeliverableUnit[(ParentRef != $root-uuid) or (ParentRef=$root-uuid and Title ='content')]"/>
                <xsl:call-template name="create-manifestation">
                    <xsl:with-param name="du-ref" select="$metadata-uuid"/>
                </xsl:call-template>
                <xsl:call-template name="create-manifestation">
                    <xsl:with-param name="du-ref" select="$metadata-unit-uuid"/>
                </xsl:call-template>
                <xsl:call-template name="create-manifestation">
                    <xsl:with-param name="du-ref" select="$metadata-series-uuid"/>
                </xsl:call-template>
                
                <xsl:if test="$born-digital != 'true'">
                    <xsl:for-each select="/XIP/Files/File[WorkingPath = '/']">
                        <xsl:variable name="pos" select="position()"/>
                        <xsl:call-template name="create-manifestation">
                            <xsl:with-param name="du-ref" select="$metadata-file-du-uuids[$pos]"/>
                            <xsl:with-param name="file-ref" select="FileRef"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
                
                <!-- reproduce all existing manifestations apart from the 'root' one -->
                <xsl:apply-templates
                    select="/XIP/DeliverableUnits/Manifestation[DeliverableUnitRef != $root-uuid]"/>
            </DeliverableUnits>
            <xsl:apply-templates select="/XIP/Files"/>
            <xsl:apply-templates select="/XIP/IngestedFileSets"/>            
        </xsl:copy>
    </xsl:template>

    <!-- default action is to copy from input -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- metadata dus need parentref pointing to new _metadata du 
       and the corresponding file needs to be moved to the new structure -->
    <xsl:template match="ParentRef[.=$root-uuid and ../Title !='content']">
        <ParentRef>
            <xsl:value-of select="$metadata-series-uuid"/>
        </ParentRef>
        <xsl:variable name="from" select="concat($contentLocation, '/', ../Title)"/>
        <xsl:variable name="to"
            select="concat($contentLocation, '/_metadata/', $unit, '/', $series, '/', ../Title)"/>
        <xsl:message
            select="concat('XSLT FileSystem: Moving from ''', $from, ''' to ''', $to, '''')"/>
        <xsl:sequence select="ext:move-file($from, $to)"/>
    </xsl:template>

    <!-- content du must lose its parentref -->
    <xsl:template match="ParentRef[.=$root-uuid and ../Title = 'content']"/>

    <!-- content du needs renaming as 'series' -->
    <xsl:template match="Title[../ParentRef=$root-uuid and . = 'content']">
        <Title>
            <xsl:value-of select="$displayable-series"/>
        </Title>
    </xsl:template>

    <!-- content du needs scopeAndContent setting to series -->
    <xsl:template match="ScopeAndContent[../ParentRef=$root-uuid and ../Title = 'content']">
        <ScopeAndContent>
            <xsl:value-of select="$displayable-series"/>
        </ScopeAndContent>
    </xsl:template>

    <!-- content du metadata must lose any dc:relation parent reference -->
    <xsl:template match="tna:parentIdentifier[ancestor::DeliverableUnit/ParentRef=$root-uuid and ancestor::DeliverableUnit/Title ='content']"/>

    <xsl:template match="tna:Cataloguing/dcterms:title[. eq 'content']">
        <dcterms:title>
            <xsl:value-of select="$displayable-series"/>
        </dcterms:title>
    </xsl:template>

    <!-- rewrite the path in DU metadata -->
    <xsl:template match="//DeliverableUnit//tna:DigitalFile/tna:filePathAndName">
        <xsl:variable name="old-path">
            <xsl:value-of select="."/>
        </xsl:variable>
        <xsl:variable name="new-path">
            <xsl:value-of
                select="replace(replace($old-path, '/content', ''),$series,encode-for-uri($displayable-series))"
            />
        </xsl:variable>
        <tna:filePathAndName rdf:datatype="xs:string">
            <xsl:value-of select="$new-path"/>
        </tna:filePathAndName>
    </xsl:template>


    <xsl:template match="//File//tna:DigitalFile/tna:filePathAndName">
        <xsl:variable name="old-path">
            <xsl:value-of select="."/>
        </xsl:variable>
        <xsl:variable name="new-path">
            <xsl:value-of
                    select="replace(replace($old-path, '/content', ''),$series,$displayable-series)"
            />
        </xsl:variable>
        <tna:filePathAndName rdf:datatype="xs:string">
            <xsl:value-of select="$new-path"/>
        </tna:filePathAndName>
    </xsl:template>
    <!-- template to rewrite a path for a DU (NOT the metadata)
      @param old-path string
      @returns string
  -->
    <xsl:template name="correct-path">
        <xsl:param name="old-path"/>

        <xsl:choose>
            <xsl:when test="matches($old-path, '^content')">
                <xsl:value-of select="replace($old-path, '^content', $displayable-series)"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- if not content, must be metadata -->
                <xsl:value-of select="concat('_metadata/', $unit, '/', $series)"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <!-- rewrite the path in manifestation -->
    <xsl:template match="/XIP/DeliverableUnits/Manifestation/ManifestationFile/Path">

        <xsl:variable name="new-path">
            <xsl:call-template name="correct-path">
                <xsl:with-param name="old-path">
                    <xsl:value-of select="."/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>

        <Path>
            <xsl:value-of select="$new-path"/>
        </Path>

    </xsl:template>

    <!-- rewrite the path for a file -->
    <xsl:template match="/XIP/Files/File/WorkingPath">

        <xsl:variable name="new-path">
            <xsl:call-template name="correct-path">
                <xsl:with-param name="old-path">
                    <xsl:value-of select="."/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>

        <WorkingPath>
            <xsl:value-of select="$new-path"/>
        </WorkingPath>

    </xsl:template>

    <!-- lower dus need parentref pointing to new series du -->
    <!--   <xsl:template match="ParentRef[.=$content-uuid]">
        <ParentRef><xsl:value-of select="$series-uuid"/></ParentRef>
    </xsl:template>
 -->
    <!-- dus need catalogue reference changing to replace underscore with space -->
    <xsl:template match="CatalogueReference">
        <CatalogueReference>
            <xsl:value-of select="$unit"/>
            <xsl:text>/</xsl:text>
            <xsl:value-of select="$displayable-series"/>
        </CatalogueReference>
    </xsl:template>

    <!-- create a new manifestation, given a UUID for its associated DU -->
    <xsl:template name="create-manifestation">
        <xsl:param name="du-ref"/>
        <xsl:param name="file-ref"/>
        <Manifestation status="new">
            <DeliverableUnitRef>
                <xsl:value-of select="$du-ref"/>
            </DeliverableUnitRef>
            <ManifestationRef>
                <xsl:value-of select="ext:random-uuid()"/>
            </ManifestationRef>
            <ManifestationRelRef>1</ManifestationRelRef>
            <Originality>true</Originality>
            <Active>true</Active>
            <TypeRef>1</TypeRef>
            <xsl:if test="$file-ref != ''">
                <ManifestationFile status="new">
                    <FileRef>
                        <xsl:value-of select="$file-ref"/>
                    </FileRef>
                    <Path>content/</Path>
                </ManifestationFile>
            </xsl:if>
        </Manifestation>
    </xsl:template>

    <!-- create a new DU, given its UUID, name, and (optionally) a parent UUID -->
    <xsl:template name="create-du">
        <xsl:param name="uuid"/>
        <xsl:param name="du-name"/>
        <xsl:param name="parent">none</xsl:param>
        <DeliverableUnit status="new">
            <DeliverableUnitRef>
                <xsl:value-of select="$uuid"/>
            </DeliverableUnitRef>
            <CollectionRef>
                <xsl:value-of select="/XIP/Collections/Collection/CollectionRef"/>
            </CollectionRef>
            <AccessionRef>
                <xsl:value-of select="/XIP/Aggregations/Accession/AccessionRef"/>
            </AccessionRef>
            <AccumulationRef>
                <xsl:value-of select="/XIP/Aggregations/Accession/AccumulationRef"/>
            </AccumulationRef>
            <xsl:if test="$parent != 'none'">
                <ParentRef>
                    <xsl:value-of select="$parent"/>
                </ParentRef>
            </xsl:if>
            <DigitalSurrogate>
              <xsl:value-of select="/XIP/DeliverableUnits/DeliverableUnit/DigitalSurrogate[../DeliverableUnitRef=$root-uuid]"/>
            </DigitalSurrogate>
            <CatalogueReference>
                <xsl:value-of select="$unit"/>
                <xsl:text>/</xsl:text>
                <xsl:value-of select="$displayable-series"/>
            </CatalogueReference>
            <ScopeAndContent>
                <xsl:value-of select="$du-name"/>
            </ScopeAndContent>
            <CoverageFrom>
                <xsl:value-of select="$root-du/CoverageFrom"/>
            </CoverageFrom>
            <CoverageTo>
                <xsl:value-of select="$root-du/CoverageFrom"/>
            </CoverageTo>
            <Title>
                <xsl:value-of select="$du-name"/>
            </Title>
            <TypeRef>1</TypeRef>
            <SecurityTag>
                <xsl:value-of select="$security-tag"/>
            </SecurityTag>
        </DeliverableUnit>
    </xsl:template>


</xsl:stylesheet>