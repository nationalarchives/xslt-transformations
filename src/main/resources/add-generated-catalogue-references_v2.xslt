<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:api="http://nationalarchives.gov.uk/dri/catalogue/api"
    xmlns:dc="http://purl.org/dc/terms/"
    xmlns:f="http://local/functions"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:tna="http://nationalarchives.gov.uk/metadata/tna#"
    xmlns:xip="http://www.tessella.com/XIP/v4"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="api f xip xs xsi"
    version="2.0">
    
    <xsl:import href="du-path-function.xslt"/>
    
    <!-- e.g. http://dri-facts1.prd.dri.web.local:8082/dri-catalogue/resources/catalogue/generated-catalogue-reference/{dept}/{series}/next?count={count} -->
    <xsl:param name="cs-gcr-uri" as="xs:string" required="yes"/>
    <xsl:param name="testing" as="xs:boolean" select="false()"/>
    
    <xsl:variable name="datagov-root" select="'http://datagov.nationalarchives.gov.uk'"/>
    
    <xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>
    
    <xsl:variable name="dept-series" select="substring-after(/xip:XIP/xip:DeliverableUnits/xip:DeliverableUnit[1]/xip:CatalogueReference, '/')" as="xs:string"/>
    <xsl:variable name="dept" select="substring-before($dept-series, ' ')" as="xs:string"/>
    <xsl:variable name="series" select="substring-after($dept-series, ' ')" as="xs:string"/>
    <xsl:variable name="du-count" select="count(/xip:XIP/xip:DeliverableUnits/xip:DeliverableUnit)"/>
    <xsl:variable name="uuids" select="/xip:XIP/xip:DeliverableUnits/xip:DeliverableUnit[exists(xip:Metadata)]/xip:DeliverableUnitRef"/>
    
    <xsl:variable name="gcrs" select="f:generate-catalogue-references($dept, $series, $du-count, $uuids)"/>
    
    <xsl:template match="xip:CatalogueReference">
        <xsl:copy>
            <xsl:variable name="du" select="parent::xip:DeliverableUnit"/>
            <xsl:variable name="path" select="f:du-path($du, node-name($du/xip:Title))"/>
            <xsl:choose>
                <xsl:when test="$path[1] eq '_metadata'">
                    <xsl:copy-of select="string-join($path,'/')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="dept" select="../xip:Metadata/tna:metadata/rdf:RDF//tna:cataloguing/tna:Cataloguing/tna:departmentIdentifier"/>
                    <xsl:variable name="series" select="../xip:Metadata/tna:metadata/rdf:RDF//tna:cataloguing/tna:Cataloguing/tna:seriesIdentifier"/>
                    <xsl:variable name="du-ref" select="$du/xip:DeliverableUnitRef" as="xs:string"/>
                    <xsl:variable name="gcr" select="$gcrs/gcr[uuid eq $du-ref]/recordNumber"/>
                    <xsl:value-of select="string-join(($dept, $series, $gcr, 'Z'), '/')"/>                        
                </xsl:otherwise>
            </xsl:choose>    
        </xsl:copy>
    </xsl:template>
    
    <!-- metadata either refers to a DigitalFolder or a BornDigitalRecord (a file)
        While a file is never a DigitalFolder the metadata for a file can appear at DeliverableUnit or File level -->
    <xsl:template match="tna:DigitalFolder|tna:BornDigitalRecord">
        <xsl:choose>
            <xsl:when test="ancestor::xip:DeliverableUnit">                
                <xsl:copy>
                    <xsl:variable name="du-ref" select="ancestor::xip:DeliverableUnit/xip:DeliverableUnitRef"/>
                    <xsl:attribute name="rdf:about" select="string-join(($datagov-root,'66',$dept, $series, $gcrs/gcr[uuid eq $du-ref]/recordNumber, 'Z'),'/')"/>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="ancestor::xip:File">
                <xsl:copy>
                    <xsl:variable name="file-ref" select="ancestor::xip:File/xip:FileRef"/>
                    <xsl:variable name="du-ref" select="/xip:XIP/xip:DeliverableUnits/xip:Manifestation[xip:ManifestationFile/xip:FileRef = $file-ref]/xip:DeliverableUnitRef"/>
                    <xsl:attribute name="rdf:about" select="string-join(($datagov-root,'66',$dept, $series, $gcrs/gcr[uuid eq $du-ref]/recordNumber, 'Z'),'/')"/>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tna:seriesIdentifier">
        <xsl:copy-of select="."/>
        <xsl:choose>
            <xsl:when test="ancestor::xip:DeliverableUnit">
                <xsl:variable name="du-ref" select="ancestor::xip:DeliverableUnit/xip:DeliverableUnitRef" as="xs:string"/>                
                <xsl:element name="tna:pieceIdentifier">
                    <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                    <xsl:value-of select="$gcrs/gcr[uuid eq $du-ref]/recordNumber"/> 
                </xsl:element>
            </xsl:when>
            <xsl:when test="ancestor::xip:File">
                <xsl:variable name="file-ref" select="ancestor::xip:File/xip:FileRef"/>
                <xsl:variable name="du-ref" select="/xip:XIP/xip:DeliverableUnits/xip:Manifestation[xip:ManifestationFile/xip:FileRef = $file-ref]/xip:DeliverableUnitRef"/>
                <xsl:element name="tna:pieceIdentifier">
                    <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                    <xsl:value-of select="$gcrs/gcr[uuid eq $du-ref]/recordNumber"/> 
                </xsl:element>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="node()|@*">
        <xsl:param name="gcr" required="no" as="element(api:generatedCatalogueReference)?"/>
        <xsl:copy exclude-result-prefixes="xs api">
            <xsl:apply-templates select="node()|@*">
                <xsl:with-param name="gcr" select="$gcr"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <!--
        Converts a generated catalogue reference into a string
        to be stored in SDB's XIP
        
        i.e. {department}/{series}/{record-number}/Z
    -->
    <xsl:function name="f:generated-catalogue-reference-to-string" as="xs:string">
        <xsl:param name="gcr" as="element(api:generatedCatalogueReference)"/>
        <xsl:value-of select="string-join(($gcr/api:department, $gcr/api:series, $gcr/api:recordNumber, if($gcr/api:department ne '_metadata')then 'Z' else()), '/')"/>
    </xsl:function>
    
    <!--
        Connects to the dri catalogue and retreives `count`
        newly generated catalogue references
    -->
    <xsl:function name="f:generate-catalogue-references" as="element(gcrs)">
        <xsl:param name="dept" as="xs:string"/>
        <xsl:param name="series" as="xs:string"/>
        <xsl:param name="count" as="xs:integer"/>
        <xsl:param name="uuids" as="element(xip:DeliverableUnitRef)*"/>
        
        <!-- check string parameters -->
        <xsl:if test="string-length($dept) eq 0">
            <xsl:message terminate="yes">$dept must be provided to f:generate-catalogueReferences#3</xsl:message>    
        </xsl:if>        
        <xsl:if test="string-length($series) eq 0">
            <xsl:message terminate="yes">$series must be provided to f:generate-catalogueReferences#3</xsl:message>
        </xsl:if>
        
        <xsl:variable name="uri">
            <xsl:choose>
                <xsl:when test="$testing">
                    <xsl:value-of select="$cs-gcr-uri"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="replace(replace(replace($cs-gcr-uri, '\{dept\}', $dept), '\{series\}', $series), '\{count\}', $count cast as xs:string)"></xsl:value-of>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="catalogue-refs" select="doc($uri)/api:result" as="node()"/>
            
        
        <xsl:element name="gcrs">
            <xsl:for-each select="$uuids">
                <xsl:variable name="count" select="position()"/>
                <xsl:element name="gcr">
                    <xsl:element name="uuid">
                        <xsl:value-of select="."/>
                    </xsl:element>
                    <xsl:element name="recordNumber">
                        <xsl:value-of select="$catalogue-refs/api:generatedCatalogueReference[$count]/api:recordNumber"/>
                    </xsl:element>    
                </xsl:element>               
            </xsl:for-each>             
        </xsl:element>
        
    </xsl:function>
    
</xsl:stylesheet>