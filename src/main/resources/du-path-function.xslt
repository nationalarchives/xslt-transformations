<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xip="http://www.tessella.com/XIP/v4"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:f="http://local/functions"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    version="2.0">
    
    <xsl:key name="du-by-id" match="xip:DeliverableUnit" use="string(xip:DeliverableUnitRef/text())"/>

    <xsl:key name="manifestation-by-du-id" match="xip:Manifestation" use="string(xip:DeliverableUnitRef/text())"/>
    
    <!--
        Builds a path from an ancestor to a descendant Deliverable Unit
        
        @param deliverable-unit
            The descendant Deliverable Unit to build a path from it's ancestor to
        @param path-element-name
            The name of the element with a Deliverable Unit that forms
            each part of the path
        
        @return
            A sequence of path segments
    -->
    <xsl:function name="f:du-path" as="xs:string*">
        <xsl:param name="deliverable-unit" as="element(xip:DeliverableUnit)?"/>
        <xsl:param name="path-element-name" as="xs:QName"/>
        <xsl:if test="not(empty($deliverable-unit))">
            <xsl:variable name="parent-du" select="key('du-by-id', $deliverable-unit/xip:ParentRef, $deliverable-unit/parent::xip:DeliverableUnits)"/>
            <xsl:copy-of select="(f:du-path($parent-du, $path-element-name), string($deliverable-unit/child::element()[node-name(.) eq $path-element-name]))"/>
        </xsl:if>
    </xsl:function>
    
    
    <xsl:function name="f:file-path" as="xs:string*">
        <xsl:param name="working_path" as="xs:string"/>        
        <xsl:variable name="wp" select = "fn:substring-after($working_path,'/')"/>
        <xsl:variable name="root" select = "fn:substring-before($working_path,'/')"/>
        <xsl:choose>
            <xsl:when test="not(empty($wp)) and ($wp != '')">
                <xsl:copy-of select="($root, f:file-path($wp))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="($working_path)"/>
            </xsl:otherwise>        
        </xsl:choose>
    </xsl:function>
    
    <!--
        Determines if a Born Digital Deliverable Unit represents a file of a folder
        
        In Born Digital, each DU represents either a file or a folder.
        
        A DU representing a `Folder will have at least one Manifestation each with NO ManifestationFiles
        A DU representing a `File` will have at least one Manifestation each with ONE ManifestationFile
    -->
    
    <xsl:function name="f:du-is-folder" as="xs:boolean">
        <xsl:param name="deliverable-unit" as="element(xip:DeliverableUnit)"/>
        
        <xsl:choose>
            <xsl:when test="f:is-top-level-du($deliverable-unit)">
                <!-- always report a top-level du as a folder -->
                <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>

                <!-- get all manifestations for a Deliverable Unit -->
                <xsl:variable name="du-manifestations" select="key('manifestation-by-du-id', $deliverable-unit/xip:DeliverableUnitRef, $deliverable-unit/parent::xip:DeliverableUnits)"/>
                
                <!-- determine the number of files in each manifestation -->
                <xsl:variable name="manifestations-file-count" select="$du-manifestations/count(xip:ManifestationFile)"/>
                
                <!-- make an assertion about the properties of born digital deliverable units -->
                <xsl:if test="count(distinct-values($manifestations-file-count)) ne 1">
                    <xsl:message select="concat('The DeliverableUnit ', $deliverable-unit/xip:DeliverableUnitRef, ' has manifestations with different numbers of files (should not be possible in born digital)!')" terminate="yes"/>
                </xsl:if>
                
                <!-- as we have asserted above that the counts of ManifestationFiles in each manifestation are
                    all the same, we can just examine the first count. If the count is zero, we have a DU
                    representing a folder. If the count is one, we have a DU representing a file. -->
                <xsl:value-of select="$manifestations-file-count[1] eq 0"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="f:is-top-level-du" as="xs:boolean">
        <xsl:param name="deliverable-unit" as="element(xip:DeliverableUnit)"/>
        <xsl:value-of select="empty($deliverable-unit/xip:ParentRef)"/>
    </xsl:function>

    <xsl:function name="f:shortest-value-of-row">
        <xsl:param name="csv-file"/>
        <xsl:param name="row-name"/>
        <xsl:variable name="identifiers" select="$csv-file/root/row/elem[@name = $row-name]/text()"/>
        <xsl:choose>
            <xsl:when test="count($identifiers) eq 1 ">
                <xsl:value-of select="$identifiers[1]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="f:shortest-value($identifiers[1],$identifiers,count($identifiers))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="f:shortest-value">
        <xsl:param name="value"/>
        <xsl:param name="options"/>
        <xsl:param name="position"/>
        <xsl:choose>
            <xsl:when test="$position eq 0">
                <xsl:copy-of select="$value"/>
            </xsl:when>
            <xsl:when test="string-length($value) &gt; string-length($options[$position])">
                <xsl:copy-of select="f:shortest-value($options[$position],$options,$position -1)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="f:shortest-value($value,$options,$position -1)"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

</xsl:stylesheet>