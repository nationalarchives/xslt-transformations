<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cf="http://catalogue/functions"
    version="2.0">

    <xsl:variable name="datagov-resource-root"
                  select="'http://datagov.nationalarchives.gov.uk/resource/'"/>

    <xsl:function name="cf:get-legal-status-uri" as="xs:anyURI">
        <xsl:param name="csv-row" as="node()"/>
        <xsl:variable name="legal-status" select="lower-case($csv-row/elem[@name eq 'legal_status'])"/>
        <xsl:variable name="rdf-status">
            <xsl:choose>
                <xsl:when test="$legal-status = 'public record'">Public_Record</xsl:when>
                <xsl:when test="$legal-status = 'public records'">Public_Records</xsl:when>
                <xsl:when test="$legal-status = 'public record(s)'">Public_Record(s)</xsl:when>
                <xsl:when test="$legal-status = 'not public record'">Not_Public_Record</xsl:when>
                <xsl:when test="$legal-status = 'not public record(s)'">Not_Public_Record(s)</xsl:when>
                <xsl:when test="$legal-status = 'welsh public record'">Welsh_Public_Record</xsl:when>
                <xsl:when test="$legal-status = 'welsh public records'">Welsh_Public_Records</xsl:when>
                <xsl:when test="$legal-status = 'welsh public record(s)'">Welsh_Public_Record(s)</xsl:when>
                <xsl:otherwise>
                    <xsl:message select="concat('No legal status provided:',$legal-status)" terminate="yes"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="concat($datagov-resource-root,$rdf-status)"/>
    </xsl:function>
</xsl:stylesheet>