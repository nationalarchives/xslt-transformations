<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xip="http://www.tessella.com/XIP/v4"    
    xmlns:api="http://nationalarchives.gov.uk/dri/catalogue/api"
    xmlns:f="http://local/functions"
    xmlns:functx="http://www.functx.com"
    xmlns:tna="http://nationalarchives.gov.uk/metadata/tna#"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    version="2.0">
    
    <xsl:import href="du-path-function.xslt"/>
    
    <xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>
    
    <xsl:template match="xip:DeliverableUnit">
        <xsl:variable name="dept-series" select="substring-after(xip:CatalogueReference, '/')" as="xs:string"/>
        <xsl:variable name="path" select="f:du-path(., node-name(xip:Title))"/>
        <xsl:variable name="metadata" as="xs:string" >
            <xsl:choose>
                <xsl:when test="$path[1] eq '_metadata'">
                    <xsl:copy-of select="string-join($path,'/')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$dept-series"/>       
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
          
        <xsl:copy exclude-result-prefixes="api xs">
            <xsl:apply-templates select="node()|@*">
                <xsl:with-param name="metadata" select="$metadata"/>
            </xsl:apply-templates>
        </xsl:copy>
        
    </xsl:template>
    
    
    <xsl:template match="xip:CatalogueReference">
        <xsl:param name="metadata" as="xs:string" required="no"/>
        <xsl:choose>
            <xsl:when test="contains($metadata,'_metadata')">
                <xsl:copy exclude-result-prefixes="xs api">
                    <xsl:value-of select="$metadata"/>
                </xsl:copy>
            </xsl:when>
           <xsl:otherwise>
             <xsl:variable name="series" select="../xip:Metadata/tna:metadata/rdf:RDF//tna:cataloguing/tna:Cataloguing/tna:seriesIdentifier"/>
             <xsl:variable name="department" select="../xip:Metadata/tna:metadata/rdf:RDF//tna:cataloguing/tna:Cataloguing/tna:departmentIdentifier"/>
             <xsl:variable name="piece"  select="../xip:Metadata/tna:metadata/rdf:RDF//tna:cataloguing/tna:Cataloguing/tna:pieceIdentifier"/>
             <xsl:variable name="item"  select="../xip:Metadata/tna:metadata/rdf:RDF//tna:cataloguing/tna:Cataloguing/tna:itemIdentifier"/>
             <xsl:variable name="sub-item"  select="../xip:Metadata/tna:metadata/rdf:RDF//tna:cataloguing/tna:Cataloguing/tna:subItemIdentifier"/>
             <xsl:copy> <xsl:value-of select="f:surrogate-catalogue-references-to-string(normalize-space($metadata), normalize-space($department), normalize-space($series), normalize-space($piece), normalize-space($item), normalize-space($sub-item))"/></xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="node()|@*">
            <xsl:param name="metadata" required="no"/>
            <xsl:copy exclude-result-prefixes="xs api">
            <xsl:apply-templates select="node()|@*">
                <xsl:with-param name="metadata" select="$metadata"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
        
    <xsl:function name="f:surrogate-catalogue-references-to-string" as="xs:string">
        <xsl:param name="metadata" as="xs:string"/>
        <xsl:param name="dept" as="xs:string"/>
        <xsl:param name="series" as="xs:string"/>
        <xsl:param name="piece" as="xs:string"/>
        <xsl:param name="item" as="xs:string"/>
        <xsl:param name="sub-item" as="xs:string"/>
        <xsl:choose>
        <xsl:when test="string-length($dept) eq 0">
            <xsl:value-of select ="replace($metadata, ' ', '/')"/>    
        </xsl:when>
        <xsl:when test="string-length($piece) eq 0">
            <xsl:value-of select="string-join(($dept, $series), '/')"/>
         </xsl:when>
         <xsl:when test="string-length($item) eq 0">
             <xsl:value-of select="string-join(($dept, $series, $piece), '/')"/>
         </xsl:when>
            <xsl:when test="string-length($sub-item) eq 0">
                <xsl:value-of select="string-join(($dept, $series, $piece, $item), '/')"/>
            </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="string-join(($dept, $series, $piece, $item, $sub-item), '/')"/>
         </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
</xsl:stylesheet>