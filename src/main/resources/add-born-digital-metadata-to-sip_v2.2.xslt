<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:api="http://nationalarchives.gov.uk/dri/catalogue/api"
    xmlns:api-dms="http://nationalarchives.gov.uk/dri/catalogue/api/dms"
    xmlns:csf="http://catalogue/service/functions" xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:f="http://local/functions" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:cf="http://catalogue/functions"
    xmlns:ext="http://tna/saxon-extension"
    xmlns:tna="http://nationalarchives.gov.uk/metadata/tna#"
    xmlns:xip="http://www.tessella.com/XIP/v4" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="api csf dcterms ext f rdf xip xsi cf" version="2.0">

    <xsl:import href="du-path-function.xslt"/>
    <xsl:import href="catalogue-service-functions.xslt"/>
    <xsl:import href="decode-uri-function.xslt"/>
    <xsl:import href="catalogue-functions.xslt"/>
    <xsl:import href="add-born-digital-metadata-templates.xslt"/>


    <xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>

    <!-- stylesheet parameters -->
    <xsl:param name="redacted-manifestation-type">100</xsl:param>
    <xsl:param name="presentation-manifestation-type">101</xsl:param>
    <xsl:param name="metadata-csv-xml-path" as="xs:string" required="yes"/>
    <xsl:param name="cs-part-schemas-uri" as="xs:string" required="yes"/>
    <xsl:param name="cs-series-uri" as="xs:string" required="yes"/>

    <!--     testing-->

    <!--<xsl:param name="metadata-csv-xml-path" as="xs:string">/opt/preservica/JobQueue/temp/WF/b6ccb5cc-7e6b-4b77-9039-559b8e8f882f/ffc76b5d-737b-49d9-895a-4f58ed6bc033/8a89db36-4ada-43f9-abaa-b6c7b92641bf/content/metadata_v5_HO519Y13S001.csv.xml</xsl:param>
    <xsl:param name="cs-part-schemas-uri" as="xs:string"
        >http://localhost:8080/dri-catalogue/resources/unit/{part-id}/schemas</xsl:param>
    <xsl:param name="cs-series-uri" as="xs:string">
        http://localhost:8080/dri-catalogue/resources/series/{part-id}</xsl:param>-->

    <!-- global variables for stylesheet -->
    <!-- get csv filename from csv.xml file path -->
    <xsl:variable name="csv-file" select="replace($metadata-csv-xml-path, '.*/(.*)\.xml', '$1')"/>
    <xsl:variable name="collectionIdentifier"
        select="string(/xip:XIP/xip:Collections/xip:Collection/xip:CollectionCode/text())"/>
    <xsl:variable name="csv">
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
    <xsl:variable name="datagov-resource-root"
        select="'http://datagov.nationalarchives.gov.uk/resource/'"/>
    <xsl:variable name="tna-metadata-schema-uri"
        select="'http://nationalarchives.gov.uk/metadata/tna#'"/>
    <xsl:variable name="part-id"
        select="/xip:XIP/xip:DeliverableUnits/xip:DeliverableUnit[1]/xip:CatalogueReference"/>
    <!-- just take the first one as they are all the same -->
    <xsl:variable name="csv-schema" as="xs:string">
        <xsl:choose>
            <xsl:when test="matches($csv-file, '[0-9]{3}.csv')">
                <xsl:value-of select="replace($csv-file,'[0-9]{3}.csv','000.csvs')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="replace($csv-file, '.csv','.csvs')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="csv-file-substitution-path">
        <xsl:variable name="identifier" select="$csv/root/row[1]/elem[@name = 'identifier']/text()"/>
        <xsl:value-of select="substring-before($identifier,substring-after($part-id,'/'))"/>
    </xsl:variable>





    <!-- keys -->
    <xsl:key name="row-by-filepath" match="root/row"
        use="f:decode-uri(string(elem[@name eq 'identifier']/text()))"/>
    <xsl:key name="row-by-filepath-original" match="root/row"
        use="f:decode-uri(string(elem[@name eq 'original_identifier']/text()))"/>
    <xsl:key name="row-by-filepath-original-retained" match="root/row"
             use="f:decode-uri(string(elem[@name eq 'retained_record_identifier']/text()))"/>

    <xsl:key name="man-by-fileref"
        match="/xip:XIP/xip:DeliverableUnits/xip:Manifestation/xip:ManifestationFile"
        use="string(xip:FileRef/text())"/>
    <xsl:key name="du-by-duref" match="/xip:XIP/xip:DeliverableUnits/xip:DeliverableUnit"
        use="string(xip:DeliverableUnitRef/text())"/>

    <!-- to check if the original identifier exists-->
    <xsl:variable name = "original-identifier">
        <xsl:value-of select = "$csv/root/row[1]/elem[@name='original_identifier']"></xsl:value-of>
    </xsl:variable>

    <!-- functions -->

    <!-- FIXME - this function can be removed if dates in the CSV file are provided in ISO 8601 format -->
    <xsl:function name="f:datetime-from-string">
        <xsl:param name="datetime-string" as="xs:string"/>
        <xsl:variable name="tokenised-date" select="tokenize($datetime-string, '/')"/>
        <xsl:variable name="month" select="$tokenised-date[1]"/>
        <xsl:variable name="day" select="$tokenised-date[2]"/>
        <xsl:variable name="year" select="concat('20',substring-before($tokenised-date[3],' '))"/>
        <xsl:variable name="time"
            select="substring-before(substring-after($tokenised-date[3],' '),' ')"/>
        <xsl:variable name="hours" select="substring-before($time,':')"/>
        <xsl:variable name="mins" select="substring-after($time,':')"/>
        <xsl:variable name="period"
            select="substring-after(substring-after($tokenised-date[3],' '),' ')"/>
        <xsl:choose>
            <xsl:when
                test="($period eq 'AM' and $hours ne '12') or ($period eq 'PM' and $hours eq '12')">
                <xsl:value-of select="concat($year,'-',$month,'-',$day,'T',$hours,':',$mins,':00Z')"
                />
            </xsl:when>
            <xsl:when test="$period eq 'AM' and $hours eq '12'">
                <xsl:value-of select="concat($year,'-',$month,'-',$day,'T','00',':',$mins,':00Z')"/>
            </xsl:when>
            <xsl:when test="$period eq 'PM'">
                <xsl:variable name="adjusted-hours" select="xs:integer($hours) + 12"/>
                <xsl:value-of
                    select="concat($year,'-',$month,'-',$day,'T',$adjusted-hours,':',$mins,':00Z')"
                />
            </xsl:when>
            <xsl:otherwise>
                <!-- error -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


    <xsl:function name="f:redacted-version-row">
        <xsl:param name="decoded-row-identifier"/>
        <xsl:choose>
            <xsl:when test="$csv/key('row-by-filepath-original',$decoded-row-identifier)">
                <xsl:copy-of select="$csv/key('row-by-filepath-original',$decoded-row-identifier)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$csv/key('row-by-filepath-original-retained',$decoded-row-identifier)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="f:unredacted-version-identifier">
        <xsl:param name="current-csv-row"/>
        <xsl:choose>
            <xsl:when test="$current-csv-row/elem[@name eq 'original_identifier'] != ''">
                <xsl:value-of select="$current-csv-row/elem[@name eq 'original_identifier']"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$current-csv-row/elem[@name eq 'retained_record_identifier']"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

        <!-- rights_copyright is a mandatory csv metadata field for born digital -->
    <xsl:function name="f:get-copyright-url" as="xs:anyURI">
        <xsl:param name="elem" as="xs:string"/>
        <xsl:choose>
            <!-- TODO what other values could there be? -->
            <xsl:when test="lower-case($elem) eq 'crown copyright'"><xsl:value-of select="concat($datagov-resource-root,'Crown_copyright')"/></xsl:when>
            <!-- the default is crown copyright -->
            <xsl:otherwise>
                <xsl:value-of  select="concat($datagov-resource-root, replace($elem, ' ', '_') )" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>



    <!-- match templates -->
    <xsl:template match="xip:XIP">
         <xsl:copy>
            <xsl:copy-of select="xmlns"/>
            <xsl:namespace name="dcterms" select="'http://purl.org/dc/terms/'"/>
            <xsl:namespace name="rdf" select="'http://www.w3.org/1999/02/22-rdf-syntax-ns#'"/>
            <xsl:namespace name="rdfs" select="'http://www.w3.org/2000/01/rdf-schema#'"/>
            <xsl:namespace name="tna" select="'http://nationalarchives.gov.uk/metadata/tna#'"/>
            <xsl:namespace name="xs" select="'http://www.w3.org/2001/XMLSchema'"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="xip:DeliverableUnit">
        <xsl:variable name="du-title-path" select="f:du-path(., node-name(xip:Title))"/>
        <xsl:variable name="encoded-du-title-path"
            select="for $p in $du-title-path return encode-for-uri($p)"/>

        <!-- create a file path from the du-title-path -->
        <xsl:variable name="file-path" select="string-join($encoded-du-title-path, '/')"/>

        <!-- determine if the du represents a folder or file -->
        <xsl:variable name="is-folder" select="f:du-is-folder(.)"/>

        <!-- calculate the row identifer for use in the CSV file -->
        <xsl:variable name="csv-row-identifier"
            select="concat($csv-file-substitution-path, if(not(ends-with($csv-file-substitution-path,'/')))then '/' else(), $file-path, if($is-folder)then '/' else())"/>

        <!-- retrieve the row from the CSV file if present -->
        <xsl:variable name="csv-row-identifier-decode" select="f:decode-uri($csv-row-identifier)"/>


        <xsl:variable name="csv-row" select="$csv/key('row-by-filepath',$csv-row-identifier-decode)"/>

         <xsl:variable name="csv-row-redacted" select="f:redacted-version-row($csv-row-identifier-decode)"/>

        <xsl:variable name="csv-row-identifier-original" select="f:unredacted-version-identifier($csv-row)"/>

        <!-- retrieve the row from the CSV file if present -->
        <xsl:variable name="csv-row-original">
               <xsl:if test="$csv-row-identifier-original">
                   <xsl:copy-of
                       select = "$csv/key('row-by-filepath',f:decode-uri($csv-row-identifier-original))"
                   />
               </xsl:if>
           </xsl:variable>

           <!-- if there is a redacted record, then the current du HAS a redaction and I want to record this and add potential manifestation components-->
        <xsl:choose>
            <!-- if there is an original record, then the current du IS a redaction and I should get rid of it-->

            <!-- I should make the manifesation point to the original DU and increase the typeref-->
            <xsl:when test="$csv-row-original != ''">
                <xsl:message select="$csv-row-original/identifier"/>
                <xsl:message select="xip:DeliverableUnitRef">Deleted DU!!!!! </xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@status"/>
                    <xsl:variable name="children" select="child::xip:*" as="element()+"/>
                    <xsl:copy-of
                        select="$children[position() le index-of($children/local-name(.), 'SecurityTag')]"/>
                    <!-- add metadata to DUs in content folder only -->
                    <xsl:variable name="content-regex">
                        <xsl:value-of select="concat('^',substring-after(xip:CatalogueReference, '/'), '/content')"/>
                    </xsl:variable>

                    <xsl:if test="matches($file-path, $content-regex)">
                        <xsl:element name="Metadata" namespace="http://www.tessella.com/XIP/v4">
                            <xsl:attribute name="schemaURI" select="$tna-metadata-schema-uri"/>
                            <xsl:element name="tna:metadata"
                                namespace="http://nationalarchives.gov.uk/metadata/tna#">
                                <xsl:namespace name="dcterms" select="'http://purl.org/dc/terms/'"/>
                                <xsl:namespace name="ead" select="'urn:isbn:1-931666-22-9'"/>
                                <xsl:namespace name="rdf"
                                    select="'http://www.w3.org/1999/02/22-rdf-syntax-ns#'"/>
                                <xsl:namespace name="xs" select="'http://www.w3.org/2001/XMLSchema'"/>
                                <xsl:element name="rdf:RDF">
                                    <xsl:choose>
                                        <xsl:when test="$is-folder">
                                            <xsl:element name="tna:DigitalFolder">
                                                <xsl:call-template
                                                  name="create-cataloguing-metadata">
                                                  <xsl:with-param name="du" select="."/>
                                                  <xsl:with-param name="csv-row" select="$csv-row"/>
                                                </xsl:call-template>
                                                <xsl:call-template name="create-digital-file-metadata">
                                                    <xsl:with-param name="file-path" select="$file-path"/>
                                                    <xsl:with-param name="csv-row" select="$csv-row"/>
                                                    <xsl:with-param name="csv-row-redacted" select="$csv-row-redacted"/>
                                                </xsl:call-template>
                                            </xsl:element>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:element name="tna:BornDigitalRecord">
                                                <xsl:call-template
                                                  name="create-cataloguing-metadata">
                                                  <xsl:with-param name="du" select="."/>
                                                  <xsl:with-param name="csv-row" select="$csv-row"/>
                                                </xsl:call-template>
                                                <xsl:call-template name="create-digital-file-metadata">
                                                    <xsl:with-param name="file-path" select="$file-path"/>
                                                    <xsl:with-param name="csv-row" select="$csv-row"/>
                                                    <xsl:with-param name="csv-row-redacted" select="$csv-row-redacted"/>
                                                    
                                                </xsl:call-template>
                                            </xsl:element>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:element>
                            </xsl:element>
                        </xsl:element>
                    </xsl:if>
                    
                    <xsl:copy-of select="$children[position() gt index-of($children/local-name(.), 'SecurityTag')]"/>
                    
                    <!-- if I have a redaction, I must copy potential DeliverableUnitComponents-->
                    <xsl:if test="$csv-row-redacted != ''">

                        <xsl:variable name="files" select="ancestor::xip:XIP/xip:Files"/>
                        <xsl:variable name="parentDus" select="parent::xip:DeliverableUnits"/>

                        <xsl:for-each select="$csv-row-redacted">
                            <xsl:variable name="fileName" select="./elem[@name='file_name']/text()"/>
                            <xsl:variable name="identifierValue" select="./elem[@name='identifier']/text()"/>
                            <xsl:variable name="workingPath"
                                          select="$files/xip:File[xip:FileName=$fileName]/xip:WorkingPath/text()"/>
                            <xsl:variable name="file"
                                          select="$files/xip:File[xip:FileName=$fileName and contains(f:decode-uri($identifierValue),$workingPath)]"></xsl:variable>

                            <xsl:variable name="redactedDURef"
                                          select="$parentDus/xip:Manifestation[xip:ManifestationFile/xip:FileRef=$file/xip:FileRef]/xip:DeliverableUnitRef/text()"/>

                            <xsl:variable name="redactedDUComponent"
                                          select="$parentDus/xip:DeliverableUnit[xip:DeliverableUnitRef=$redactedDURef]/xip:DeliverableUnitComponent/xip:ComponentRef/text()">
                            </xsl:variable>

                            <xsl:apply-templates
                                    select="$parentDus/xip:DeliverableUnit/xip:DeliverableUnitComponent[xip:ComponentRef=$redactedDUComponent]"/>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>

        <!-- end temp -->
    </xsl:template>
    
    <xsl:template match="xip:DeliverableUnitComponent">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>


    <xsl:template match="xip:Manifestation">
        <xsl:variable name="du-ref" select="xip:DeliverableUnitRef"/>
        <xsl:variable name = "du" select="key('du-by-duref', $du-ref)"/>

        <xsl:variable name="TitleFromDU" select="node-name($du/xip:Title)"/>

        <xsl:variable name="du-title-path" select="f:du-path($du, $TitleFromDU)"/>
        <xsl:variable name="encoded-du-title-path" select="for $p in $du-title-path return encode-for-uri($p)"/>

        <!-- create a file path from the du-title-path -->
        <xsl:variable name="file-path" select="string-join($encoded-du-title-path, '/')"/>

        <!-- determine if the du represents a folder or file -->
        <xsl:variable name="is-folder" select="f:du-is-folder($du)"/>

        <!-- calculate the row identifer for use in the CSV file -->
        <xsl:variable name="csv-row-identifier" select="concat($csv-file-substitution-path, if(not(ends-with($csv-file-substitution-path,'/')))then '/' else(), $file-path, if($is-folder)then '/' else())"/>

        <!-- retrieve the row from the CSV file if present -->
        <xsl:variable name="csv-row-identifier-decode" select="f:decode-uri($csv-row-identifier)"/>

        <!-- retrieve the row from the CSV file if present -->
        <xsl:variable name="csv-row" select="$csv/key('row-by-filepath',$csv-row-identifier-decode)"/>


        <xsl:variable name="csv-row-identifier-original" select="f:unredacted-version-identifier($csv-row)"/>

        <xsl:variable name="csv-row-original">
            <xsl:if test="$csv-row-identifier-original">
                <xsl:copy-of
                        select="$csv/key('row-by-filepath',f:decode-uri($csv-row-identifier-original))"
                />
            </xsl:if>
        </xsl:variable>

         <xsl:choose>
            <!-- if there is an original record, then the current manifestation IS a redaction -->
            <!-- I should make the manifesation point to the original DU and increase the typeref-->
            <xsl:when test="$csv-row-original != ''">
                <xsl:element name="Manifestation" namespace="http://www.tessella.com/XIP/v4">
                    <xsl:attribute name="status">new</xsl:attribute>
                    <!-- copy uuid from the original -->
                    <xsl:element name="DeliverableUnitRef" namespace="http://www.tessella.com/XIP/v4">
                        <xsl:variable name="file" select="ancestor::xip:XIP/xip:Files/xip:File[xip:FileName=$csv-row-original/row/elem[@name='file_name']/text() and contains($csv-row-original/row/elem[@name='identifier']/text(),xip:ManifestationFile/xip:Path/text())]"></xsl:variable>
                        <xsl:value-of select="parent::xip:DeliverableUnits/xip:Manifestation[xip:ManifestationFile/xip:FileRef=$file/xip:FileRef]/xip:DeliverableUnitRef/text()"/>
                    </xsl:element>

                    <!-- calculate the row identifer for use in the CSV file -->
                    <!-- current reacted row identifier -->
                    <xsl:variable name="csv-row-identifier"
                                  select="concat($csv-file-substitution-path, if(not(ends-with($csv-file-substitution-path,'/')))then '/' else(), $file-path, if($is-folder)then '/' else())"/>
                     <!-- retrieve the row from the CSV file if present -->
                    <xsl:variable name="csv-row-identifier-decode" select="f:decode-uri($csv-row-original/row/elem[@name='identifier']/text())"/>
                    <!-- redacted rows -->

                    <xsl:variable name="csv-row-redacted" select="f:redacted-version-row($csv-row-identifier-decode)"/>
                    <xsl:copy-of select="xip:ManifestationRef"/>
                    <xsl:variable name="originality" select="xip:Originality"/>
                    <xsl:variable name="active" select="xip:Active"/>
                        <xsl:for-each select="$csv-row-redacted">
                            <xsl:if test="./elem[@name = 'identifier']/text() eq $csv-row-identifier">
                            <xsl:variable name="position" select="position()"/>
                            <!--TODO - When I have multiple redactions, I need to read the value from the catalogue This will be rquired for accumulations-->
                            <xsl:element name="ManifestationRelRef" namespace="http://www.tessella.com/XIP/v4">
                                <xsl:value-of select="$position +1"/>
                            </xsl:element>
                            <xsl:copy-of select="$originality"/>
                            <xsl:copy-of select="$active"/>
                            <xsl:element name="TypeRef" namespace="http://www.tessella.com/XIP/v4">
                                <xsl:analyze-string select="string-join($encoded-du-title-path,'')" regex="(.*_R\d*\..*)">
                                    <xsl:matching-substring>
                                        <xsl:value-of select="$redacted-manifestation-type"/>
                                    </xsl:matching-substring>
                                </xsl:analyze-string>
                                <xsl:analyze-string select="string-join($encoded-du-title-path,'')" regex="(.*_P\d*\..*)">
                                    <xsl:matching-substring>
                                        <xsl:value-of select="$presentation-manifestation-type"/>
                                    </xsl:matching-substring>
                                </xsl:analyze-string>
                            </xsl:element>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:variable name="children" select="child::xip:*" as="element()+"/>
                    <xsl:copy-of select="$children[position() gt index-of($children/local-name(.), 'TypeRef')]"/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@*|node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="xip:File">
        <xsl:variable name="file-path"
            select="concat(substring-after($part-id,'/'),'/', if(xip:WorkingPath ne '/')then concat(xip:WorkingPath,'/') else(), xip:FileName)"/>

        <xsl:variable name="csv-row-identifier"
            select="concat($csv-file-substitution-path, if(not(ends-with($csv-file-substitution-path,'/')))then '/' else(), $file-path)"/>
        <xsl:variable name="csv-row" select="$csv/key('row-by-filepath',f:decode-uri($csv-row-identifier))"/>
        <xsl:variable name="csv-row-redacted" select="f:redacted-version-row($csv-row-identifier)"/>
        <xsl:variable name="csv-row-identifier-original" select="f:unredacted-version-identifier($csv-row)"/>
        <xsl:variable name="csv-row-original" >
            <xsl:if test="$csv-row-identifier-original">
                <xsl:copy-of select="$csv/key('row-by-filepath', f:decode-uri($csv-row-identifier-original))"/>
            </xsl:if>
        </xsl:variable>

        <xsl:copy>
            <xsl:copy-of select="@status"/>
            <!--<xsl:variable name="children" select="child::*[position() ne 1]" as="element()+"/>-->
            <xsl:variable name="children" select="child::*" as="element()+"/>
            <xsl:variable name="file-ref" select="xip:FileRef/text()"/>
            <xsl:choose>
                <xsl:when test="xip:WorkingPath ne '/'">
                    <!-- we are not interested in adding metadata to the actual metadata files that reside in the root-->

                    <xsl:if test="empty($csv-row)">
                        <xsl:message
                            select="concat('raw-path : ',$csv-row-identifier, ' row:  ', $csv-row)"
                            terminate="yes"/>
                    </xsl:if>


                    <!-- <xsl:variable name="children" select="child::*" as="element()+"/> -->
                    <!--<xip:FileRef><xsl:value-of select="$csv-row/elem[@name eq 'file_uuid']"/></xip:FileRef>-->
                    <xsl:copy-of
                        select="$children[position() le index-of($children/local-name(.), 'Directory')]"/>
                    <xsl:element name="Metadata" namespace="http://www.tessella.com/XIP/v4">
                        <xsl:attribute name="schemaURI" select="$tna-metadata-schema-uri"/>
                        <xsl:element name="tna:metadata"
                            namespace="http://nationalarchives.gov.uk/metadata/tna#">
                            <xsl:namespace name="dcterms" select="'http://purl.org/dc/terms/'"/>
                            <xsl:namespace name="ead" select="'urn:isbn:1-931666-22-9'"/>
                            <xsl:namespace name="rdf"
                                select="'http://www.w3.org/1999/02/22-rdf-syntax-ns#'"/>
                            <xsl:namespace name="xs" select="'http://www.w3.org/2001/XMLSchema'"/>

                            <xsl:element name="rdf:RDF">

                                <xsl:element name="tna:BornDigitalRecord"
                                    namespace="http://nationalarchives.gov.uk/metadata/tna#">
                                    <xsl:variable name="du-ref"
                                        select="key('man-by-fileref', $file-ref)/../xip:DeliverableUnitRef"/>
                                    <!--<xsl:variable name="du-ref" select="ancestor::xip:XIP/xip:DeliverableUnits/xip:Manifestation[xip:ManifestationFile/xip:FileRef eq $file-ref]/xip:DeliverableUnitRef"/>-->
                                    <xsl:call-template name="create-cataloguing-metadata">
                                        <!--<xsl:with-param name="du" select="/xip:XIP/xip:DeliverableUnits/xip:DeliverableUnit[xip:DeliverableUnitRef eq $du-ref]"/>-->
                                        <xsl:with-param name="du"
                                            select="key('du-by-duref', $du-ref)"/>
                                        <xsl:with-param name="csv-row" select="$csv-row"/>
                                    </xsl:call-template>
                                    <xsl:call-template name="create-digital-file-metadata">
                                        <xsl:with-param name="file-path" select="$file-path"/>
                                        <xsl:with-param name="csv-row" select="$csv-row"/>
                                        <xsl:with-param name="file-identifier" select="xip:FileRef"/>
                                        <xsl:with-param name="csv-row-redacted" select="$csv-row-redacted"/>
                                        <xsl:with-param name="csv-row-original" select="$csv-row-original"/>
                                    </xsl:call-template>
                                </xsl:element>
                            </xsl:element>
                        </xsl:element>
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

    <xsl:template name="create-cataloguing-metadata">
        <xsl:param name="du" as="node()"/>
        <xsl:param name="csv-row" as="node()"/>
        <xsl:element name="tna:cataloguing">
            <xsl:element name="tna:Cataloguing">
                <xsl:element name="tna:collectionIdentifier">
                    <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                    <xsl:value-of select="$collectionIdentifier"/>
                </xsl:element>
                <xsl:element name="tna:batchIdentifier">
                    <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                    <xsl:value-of select="substring-before($du/xip:CatalogueReference, '/')"/>
                </xsl:element>
                <xsl:element name="tna:departmentIdentifier">
                    <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                    <xsl:value-of
                        select="substring-before(substring-after($du/xip:CatalogueReference, '/'),'_')"/>
                </xsl:element>
                <xsl:element name="tna:seriesIdentifier">
                    <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                    <xsl:value-of
                        select="substring-after(substring-after($du/xip:CatalogueReference, '/'), '_')"
                    />
                </xsl:element>
                <xsl:if test="$csv-row/elem[@name eq 'iaid'] != ''">
                    <xsl:element name="tna:iaid">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'iaid']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$du/xip:ParentRef">
                    <xsl:element name="tna:parentIdentifier">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$du/xip:ParentRef"/>
                    </xsl:element>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="$csv-row/elem[@name eq 'file_name'] != ''">
                        <xsl:element name="dcterms:title">
                            <xsl:if test="$csv-row/elem[@name eq 'file_name_language'] != ''">
                                <xsl:attribute name="xml:lang" select="$csv-row/elem[@name eq 'file_name_language']"/>
                            </xsl:if>
                            <xsl:value-of select="$csv-row/elem[@name eq 'file_name']"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:when test="$csv-row/elem[@name eq 'title']">
                        <xsl:element name="dcterms:title">
                            <xsl:value-of select="$csv-row/elem[@name eq 'title']"/>
                        </xsl:element>
                    </xsl:when>
                </xsl:choose>
                <xsl:if test="$csv-row/elem[@name eq 'file_name_translation'] != ''">
                    <xsl:element name="dcterms:title">
                        <xsl:if test="$csv-row/elem[@name eq 'file_name_translation_language'] != ''">
                            <xsl:attribute name="xml:lang" select="$csv-row/elem[@name eq 'file_name_translation_language']"/>
                        </xsl:if>
                        <xsl:value-of select="$csv-row/elem[@name eq 'file_name_translation']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'description']">
                    <xsl:element name="dcterms:description">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'description']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:element name="dcterms:creator">
                    <xsl:attribute name="rdf:resource">
                        <xsl:value-of
                            select="csf:series($cs-series-uri, substring-after($du/xip:CatalogueReference, '/'))/api-dms:series/api-dms:creatingBody"/>
                    </xsl:attribute>
                </xsl:element>
                <xsl:if test="$csv-row/elem[@name eq 'start_date'] and $csv-row/elem[@name eq 'end_date']">
                    <xsl:element name="dcterms:coverage">
                        <xsl:element name="tna:CoveringDates">
                            <xsl:element name="tna:startDate">
                                <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                                <xsl:value-of select="$csv-row/elem[@name eq 'start_date']"/>
                            </xsl:element>
                            <xsl:element name="tna:endDate">
                                <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                                <xsl:value-of select="$csv-row/elem[@name eq 'end_date']"/>
                            </xsl:element>
                        </xsl:element>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="not($csv-row/elem[@name eq 'start_date']) and $csv-row/elem[@name eq 'end_date'] != ''">
                    <xsl:element name="dcterms:coverage">
                        <xsl:element name="tna:CoveringDates">
                            <xsl:element name="tna:startDate">
                                <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                                <xsl:value-of select="$csv-row/elem[@name eq 'end_date']"/>
                            </xsl:element>
                            <xsl:element name="tna:endDate">
                                <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                                <xsl:value-of select="$csv-row/elem[@name eq 'end_date']"/>
                            </xsl:element>
                        </xsl:element>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'date_range'] != ''">
                    <xsl:element name="dcterms:coverage">
                        <xsl:element name="tna:dateRange">
                            <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                            <xsl:value-of select="$csv-row/elem[@name eq 'date_range']"/>
                       </xsl:element>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'curated_title'] != ''">
                    <xsl:element name="tna:curatedTitle">
                        <xsl:value-of select="$csv-row/elem[@name eq 'curated_title']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'physical_condition'] != ''">
                    <xsl:element name="tna:physicalCondition">
                        <xsl:value-of select="$csv-row/elem[@name eq 'physical_condition']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'department'] != ''">
                    <xsl:element name="tna:internalGovernmentDepartment">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'department']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'former_reference_department'] != ''">
                    <xsl:element name="tna:formerReferenceDepartment">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'former_reference_department']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'former_ref_department'] != ''">
                    <xsl:element name="tna:formerReferenceDepartment">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'former_ref_department']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'former_reference_TNA'] != ''">
                    <xsl:element name="tna:formerReferenceTNA">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'former_reference_TNA']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'archivist_note'] != ''">
                    <xsl:element name="tna:archivistNote">
                        <xsl:element name="tna:ArchivistNote">
                            <xsl:element name="tna:archivistNoteInfo">
                                <xsl:value-of select="$csv-row/elem[@name eq 'archivist_note']"/>
                            </xsl:element>
                            <xsl:if test="$csv-row/elem[@name eq 'date_archivist_note'] != ''">
                                <xsl:element name="tna:archivistNoteDate">
                                    <xsl:value-of
                                            select="$csv-row/elem[@name eq 'date_archivist_note']"/>
                                </xsl:element>
                            </xsl:if>
                        </xsl:element>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'language'] !=''">
                    <xsl:element name="dcterms:language">
                       <xsl:value-of select="$csv-row/elem[@name eq 'language']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:variable name="rights-array" as="xs:string*" select="tokenize($csv-row/elem[@name eq 'rights_copyright']/text(),',')"/>
                <xsl:for-each select="$rights-array">
                    <xsl:element name="dcterms:rights">
                        <xsl:attribute name="rdf:resource" select="f:get-copyright-url(.)"/>
                    </xsl:element>
                </xsl:for-each>

                <xsl:element name="tna:legalStatus">
                    <xsl:attribute name="rdf:resource" select="cf:get-legal-status-uri($csv-row)"/>
                </xsl:element>
                <xsl:element name="tna:heldBy">
                    <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                    <xsl:choose>
                        <xsl:when test="$csv-row/elem[@name eq 'held_by'] != ''">
                            <xsl:value-of select="$csv-row/elem[@name eq 'held_by']"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="xs:string('The National Archives, Kew')"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
                <xsl:if test="$csv-row/elem[@name eq 'note'] != ''">
                    <xsl:element name="tna:note">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'note']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'administrative_background'] != ''">
                    <xsl:element name="tna:administrativeBackground">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'administrative_background']"/>
                    </xsl:element>
                </xsl:if>



                <xsl:if test="$csv-row/elem[@name eq 'original_format'] != ''">
                    <xsl:element name="tna:originalFormat">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'original_format']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'video_or_audio_length_in_hours_mins_and_secs'] != ''">
                    <xsl:element name="tna:VideoOrAudioLengthInHoursMinsAndSecs">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'video_or_audio_length_in_hours_mins_and_secs']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'used_footage_duration_in_hours_mins_and_secs'] != ''">
                    <xsl:element name="tna:UsedFootageDurationInHoursMinsAndSecs">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'used_footage_duration_in_hours_mins_and_secs']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'related_material'] != ''">
                    <xsl:element name="tna:relatedMaterial">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'related_material']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'session'] != ''">
                    <xsl:element name="tna:session">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'session']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:element name="tna:session_date">
                    <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                    <xsl:value-of select="$csv-row/elem[@name eq 'session_date']"/>
                </xsl:element>

                <xsl:call-template name="selects">
                    <xsl:with-param name="i">1</xsl:with-param>
                    <xsl:with-param name="count">5</xsl:with-param>
                    <xsl:with-param name="csv-row" select="$csv-row"/>
                </xsl:call-template>

                <xsl:if test="$csv-row/elem[@name eq 'hearing_date'] != ''">
                    <xsl:element name="tna:hearing_date">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'hearing_date']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'witness_list_1'] != ''">
                    <xsl:element name="tna:witness_list_1">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'witness_list_1']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'subject_role_1'] != ''">
                    <xsl:element name="tna:subject_role_1">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'subject_role_1']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'witness_list_2'] != ''">
                    <xsl:element name="tna:witness_list_2">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'witness_list_2']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'subject_role_2'] != ''">
                    <xsl:element name="tna:subject_role_2">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'subject_role_2']"/>
                    </xsl:element>
                </xsl:if>


                <xsl:if test="$csv-row/elem[@name eq 'witness_list_3'] != ''">
                    <xsl:element name="tna:witness_list_3">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'witness_list_3']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'subject_role_3'] != ''">
                    <xsl:element name="tna:subject_role_3">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'subject_role_3']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'web_archive_url'] != ''">
                    <xsl:element name="tna:webArchiveUrl">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'web_archive_url']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'category'] != ''">
                    <xsl:element name="tna:category">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'category']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'classification'] != ''">
                    <xsl:element name="tna:classification">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'classification']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'corporate_body'] != ''">
                    <xsl:element name="tna:corporateBody">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'corporate_body']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'curated_date'] != ''">
                    <xsl:element name="tna:curatedDate">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'curated_date']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'curated_date_note'] != ''">
                    <xsl:element name="tna:curatedDateNote">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'curated_date_note']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'duration_mins'] != ''">
                    <xsl:element name="tna:durationMins">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'duration_mins']"/>
                    </xsl:element>
                </xsl:if>


                <xsl:if test="$csv-row/elem[@name eq 'film_maker'] != ''">
                    <xsl:element name="tna:filmMaker">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'film_maker']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'film_name'] != ''">
                    <xsl:element name="tna:filmName">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'film_name']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'internal_department'] != ''">
                    <xsl:element name="tna:internalDepartment">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'internal_department']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'original_identifier'] != ''">
                    <xsl:element name="tna:originalIdentifier">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'original_identifier']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'photographer'] != ''">
                    <xsl:element name="tna:photographer">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'photographer']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'summary'] != ''">
                    <xsl:element name="tna:summary">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'summary']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'attachment_former_reference'] != ''">
                    <xsl:element name="tna:attachmentFormerReference">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'attachment_former_reference']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'attachment_link'] != ''">
                    <xsl:element name="tna:attachmentLink">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'attachment_link']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'evidence_provided_by'] != ''">
                    <xsl:element name="tna:evidenceProvidedBy">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'evidence_provided_by']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'Content_management_system_container'] != ''">
                    <xsl:element name="tna:contentManagementSystemContainer">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'Content_management_system_container']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'Business_area'] != ''">
                    <xsl:element name="tna:businessArea">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'Business_area']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'distressing_content'] != ''">
                    <xsl:element name="tna:distressingContent">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'distressing_content']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'date_created'] != ''">
                    <xsl:element name="tna:dateCreated">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'date_created']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'separated_material'] != ''">
                    <xsl:element name="tna:separatedMaterial">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'separated_material']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'TDR_consignment_ref'] != ''">
                    <xsl:element name="tna:tdrConsignmentRef">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'TDR_consignment_ref']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'judgment_court'] != ''">
                    <xsl:element name="tna:judgmentCourt">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'judgment_court']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'judgment_date'] != ''">
                    <xsl:element name="tna:judgmentDate">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'judgment_date']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'judgment_name'] != ''">
                    <xsl:element name="tna:judgmentName">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'judgment_name']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'judgment_neutral_citation'] != ''">
                    <xsl:element name="tna:judgmentNeutralCitation">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'judgment_neutral_citation']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'checksum_md5'] != ''">
                    <xsl:element name="tna:checksumMd5">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'checksum_md5']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'google_id'] != ''">
                    <xsl:element name="tna:googleId">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'google_id']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'google_parent_id'] != ''">
                    <xsl:element name="tna:googleParentId">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'google_parent_id']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'other_format_version_identifier'] != ''">
                    <xsl:element name="tna:otherFormatVersionIdentifier">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'other_format_version_identifier']"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'parent_dri_ref'] != ''">
                    <xsl:element name="tna:parentDriRef">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$csv-row/elem[@name eq 'parent_dri_ref']"/>
                    </xsl:element>
                </xsl:if>
              </xsl:element>
        </xsl:element>
    </xsl:template>

    <!-- we receive file identifier for files but not for folders -->
    <xsl:template name="create-digital-file-metadata">
        <xsl:param name="file-path" as="xs:string"/>
        <xsl:param name="csv-row" as="node()"/>
        <xsl:param name="csv-row-redacted" as="node()*"/>
        <xsl:param name="csv-row-original" as="node()?"/>
        <xsl:param name="file-identifier" required="no"/>
        <xsl:element name="tna:digitalFile">
            <xsl:element name="tna:DigitalFile">
                <xsl:if test="$csv-row/elem[@name eq 'date_last_modified']">
                    <xsl:element name="dcterms:modified">
                        <xsl:attribute name="rdf:datatype" select="'xs:dateTime'"/>
                        <!--<xsl:value-of select="f:datetime-from-string($csv-row/elem[@name eq 'date_last_modified'])"/>-->
                        <xsl:value-of select="$csv-row/elem[@name eq 'date_last_modified']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$csv-row/elem[@name eq 'last_modified_date']">
                    <xsl:element name="dcterms:modified">
                        <xsl:attribute name="rdf:datatype" select="'xs:dateTime'"/>
                        <!--<xsl:value-of select="f:datetime-from-string($csv-row/elem[@name eq 'date_last_modified'])"/>-->
                        <xsl:value-of select="$csv-row/elem[@name eq 'last_modified_date']"/>
                    </xsl:element>
                </xsl:if>

                <xsl:if test="$file-identifier">
                    <xsl:element name="tna:fileIdentifier">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$file-identifier"/>
                    </xsl:element>
                </xsl:if>
                <xsl:element name="tna:filePathAndName">
                    <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                    <xsl:value-of select="$file-path"/>
                </xsl:element>
                <!-- if we have a file need to add hasRedacted -->
                <xsl:if test="$csv-row-redacted/elem[@name eq 'identifier'] and $csv-row-redacted/elem[@name eq 'identifier'] != '' ">
                      <xsl:for-each select="$csv-row-redacted">
                           <xsl:analyze-string select="./elem[@name = 'identifier']/text()" regex="(.*_R\d*\..*)|(.*_P\d*\..*)">
                              <xsl:non-matching-substring>
                                  <xsl:message terminate="yes"
                                               select="concat('Redacted name ''', $csv-row-redacted[1]/elem[@name eq 'identifier']/text(),''' does not respect naming convention _P/_R')"/>
                              </xsl:non-matching-substring>
                          </xsl:analyze-string>
                          <xsl:analyze-string select="./elem[@name = 'identifier']" regex=".*_R\d*\..*">
                            <xsl:matching-substring>
                                  <xsl:element name="tna:hasRedactedFile">
                                     <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                                     <xsl:value-of select="substring-after(.,$csv-file-substitution-path)"/>
                                 </xsl:element>
                            </xsl:matching-substring>
                                </xsl:analyze-string>
                                <xsl:analyze-string select="./elem[@name = 'identifier']/text()" regex=".*_P\d*\..*">
                                    <xsl:matching-substring>
                                        <xsl:element name="tna:hasPresentationManifestationFile">
                                            <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                                            <xsl:value-of select="substring-after(.,$csv-file-substitution-path)"/>
                                        </xsl:element>
                                    </xsl:matching-substring>
                                </xsl:analyze-string>
                            </xsl:for-each>
                </xsl:if>

                <!-- Each redacted file will enter here but only want to add once-->
                <xsl:if test="$csv-row-original/row/elem[@name eq 'identifier'] and $csv-row-original/row/elem[@name eq 'identifier'] != '' ">
                    <xsl:analyze-string regex="(.*_R\d*\..*)|(.*_P\d*\..*)" select="$file-path">
                        <xsl:non-matching-substring>
                            <xsl:message terminate="yes"
                                         select="concat('Redacted name ''', $csv-row-redacted[1]/elem[@name eq 'identifier']/text(),''' does not respect naming convention _P/_R')"/>
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                    <xsl:analyze-string regex=".*_R\d*\..*" select="$file-path">
                        <xsl:matching-substring>
                                <xsl:element name="tna:isRedactionOf">
                                <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                                 <xsl:value-of select="substring-after($csv-row-original/row/elem[@name eq 'identifier']/text(),$csv-file-substitution-path)"/>
                            </xsl:element>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                    <xsl:analyze-string regex=".*_P\d*\..*" select="$file-path">
                        <xsl:matching-substring>
                            <xsl:element name="tna:isPresentationOff">
                                <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                                <xsl:value-of select="substring-after($csv-row-original/row/elem[@name eq 'identifier']/text(),$csv-file-substitution-path)"/>
                            </xsl:element>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:if>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
