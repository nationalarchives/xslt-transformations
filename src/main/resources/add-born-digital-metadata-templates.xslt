<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:api="http://nationalarchives.gov.uk/dri/catalogue/api"
                xmlns:api-dms="http://nationalarchives.gov.uk/dri/catalogue/api/dms"
                xmlns:csf="http://catalogue/service/functions" xmlns:dcterms="http://purl.org/dc/terms/"
                xmlns:f="http://local/functions" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:cf="http://catalogue/functions"
                xmlns:tna="http://nationalarchives.gov.uk/metadata/tna#"
                xmlns:xip="http://www.tessella.com/XIP/v4" xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:uuid="java:java.util.UUID"
                exclude-result-prefixes="api csf dcterms f rdf xip xsi cf" version="2.0">



    <xsl:template name="selects">
        <xsl:param name="i" />
        <xsl:param name="count" />
        <xsl:param name="csv-row" as="node()"/>

        <xsl:if test="$i &lt;= $count">
            <xsl:call-template name="select_case_details" >
                <xsl:with-param name="csv-row" select="$csv-row"/>
                <xsl:with-param name="i" select="$i"/>
            </xsl:call-template>

        </xsl:if>


        <!--begin_: RepeatTheLoopUntilFinished-->
        <xsl:if test="$i &lt;= $count">
            <xsl:call-template name="selects">
                <xsl:with-param name="i">
                    <xsl:value-of select="$i + 1"/>
                </xsl:with-param>
                <xsl:with-param name="csv-row" select="$csv-row"/>
                <xsl:with-param name="count">
                    <xsl:value-of select="$count"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>

    </xsl:template>


    <xsl:template name="select_case_details">
        <xsl:param name="i"/>
        <xsl:param name="csv-row" as="node()"/>

        <xsl:variable name="case_id" select = "concat('case_id_', $i)"></xsl:variable>
        <xsl:variable name="case_name" select = "concat('case_name_', $i)"></xsl:variable>
        <xsl:variable name="case_summary_id" select = "concat('case_summary_', $i)"></xsl:variable>

        <xsl:variable name="case_summary_id_judgment" select = "concat('case_summary_', $i, '_judgment')"></xsl:variable>
        <xsl:variable name="case_summary_id_reasons_for_judgment" select = "concat('case_summary_', $i, '_reasons_for_judgment')"></xsl:variable>

        <xsl:variable name="hearing_start_date_id" select = "concat('hearing_start_date_', $i)"></xsl:variable>
        <xsl:variable name="hearing_end_date_id" select = "concat('hearing_end_date_', $i)"></xsl:variable>


        <xsl:if test="$csv-row/elem[@name eq  $case_id] != ''">
            <xsl:element name="tna:{$case_id}">
                <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                <xsl:value-of select="$csv-row/elem[@name eq  $case_id]"/>
            </xsl:element>
        </xsl:if>

        <xsl:if test="$csv-row/elem[@name eq  $case_name] != ''">
            <xsl:element name="tna:{$case_name}">
                <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                <xsl:value-of select="$csv-row/elem[@name eq  $case_name]"/>
            </xsl:element>
        </xsl:if>

        <xsl:if test="$csv-row/elem[@name eq  $case_summary_id] != ''">
            <xsl:element name="tna:{$case_summary_id}">
                <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                <xsl:value-of select="$csv-row/elem[@name eq $case_summary_id]"/>
            </xsl:element>
        </xsl:if>

        <xsl:if test="$csv-row/elem[@name eq  $case_summary_id_judgment] != ''">
            <xsl:element name="tna:{$case_summary_id_judgment}">
                <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                <xsl:value-of select="$csv-row/elem[@name eq $case_summary_id_judgment]"/>
            </xsl:element>
        </xsl:if>

        <xsl:if test="$csv-row/elem[@name eq  $case_summary_id_reasons_for_judgment] != ''">
            <xsl:element name="tna:{$case_summary_id_reasons_for_judgment}">
                <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                <xsl:value-of select="$csv-row/elem[@name eq $case_summary_id_reasons_for_judgment]"/>
            </xsl:element>
        </xsl:if>

        <xsl:if test="$csv-row/elem[@name eq  $hearing_start_date_id] != ''">
            <xsl:element name="tna:{$hearing_start_date_id}">
                <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                <xsl:value-of select="$csv-row/elem[@name eq $hearing_start_date_id]"/>
            </xsl:element>
        </xsl:if>

        <xsl:if test="$csv-row/elem[@name eq  $hearing_end_date_id] != ''">
            <xsl:element name="tna:{$hearing_end_date_id}">
                <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                <xsl:value-of select="$csv-row/elem[@name eq $hearing_end_date_id]"/>
            </xsl:element>
        </xsl:if>

    </xsl:template>
</xsl:stylesheet>