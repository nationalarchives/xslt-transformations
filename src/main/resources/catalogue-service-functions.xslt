<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:csf="http://catalogue/service/functions"
    xmlns:api="http://nationalarchives.gov.uk/dri/catalogue/api"
    version="2.0">

    <!-- 
        Various Catalogue Service functions
        
        @author Adam Retter <adam.retter@googlemail.com>
    --> 

    <!-- given a part-id retrieve the transfer agreement from the catalogue -->
    <xsl:function name="csf:transfer-agreement" as="element(api:map)">
        <xsl:param name="cs-part-transfer-agreement-uri" as="xs:string"/>
        <xsl:param name="part-id" as="xs:string"/>
        <xsl:copy-of select="doc(csf:resolve-cs-part-uri($cs-part-transfer-agreement-uri, $part-id))/api:result/api:map"/>
    </xsl:function>

    <xsl:function name="csf:series" >
        <xsl:param name="cs-series-uri" as="xs:string"/>
        <xsl:param name="series-id" as="xs:string"/>
        <xsl:copy-of select="document(csf:resolve-cs-part-uri($cs-series-uri, $series-id))"/>
    </xsl:function>

    <!-- takes a uri with a part-id template and replaces it with the part-id -->
    <xsl:function name="csf:resolve-cs-part-uri" as="xs:anyURI">
        <xsl:param name="template-uri" as="xs:string"/>
        <xsl:param name="part-id" as="xs:string"/>
        <xsl:value-of select="xs:anyURI(replace($template-uri, '\{part-id\}', $part-id))"/>
    </xsl:function>
    
</xsl:stylesheet>