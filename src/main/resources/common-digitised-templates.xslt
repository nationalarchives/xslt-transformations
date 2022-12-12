<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tessella.com/XIP/v4"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:csf="http://catalogue/service/functions"
                xmlns:dcterms="http://purl.org/dc/terms/"
                xmlns:tnams="http://nationalarchives.gov.uk/metadata/spatial/"
                xmlns:f="http://local/functions"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:tna="http://nationalarchives.gov.uk/metadata/tna#"
                xmlns:xip="http://www.tessella.com/XIP/v4"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dc="http://purl.org/dc/terms/"
                xmlns:tnamp="http://nationalarchives.gov.uk/metadata/person/"
                xmlns:cf="http://catalogue/functions"
                xmlns:tnatrans="http://nationalarchives.gov.uk/dri/transcription"
                xmlns:xl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="dcterms f csf xip xsi tnamp tnams dc cf tnatrans"
                version="2.0">

    <xsl:import href="common-metadata-functions.xslt"/>
    <xsl:import href="catalogue-functions.xslt"/>
    <xsl:template name="create-collection-to-series-metadata">
        <xsl:param name="csv-row" as="node()"/>
        <xsl:param name="department" as="xs:string"/>
        <xsl:param name="series" as="xs:string"/>
        <xsl:param name="collection-identifier" as="xs:string"/>
        <tna:collectionIdentifier rdf:datatype="xs:string">
            <xsl:value-of select="$collection-identifier"/>
        </tna:collectionIdentifier>
        <tna:batchIdentifier rdf:datatype="xs:string">
            <xsl:value-of select="$csv-row/elem[@name eq 'batch_code']/text()"/>
        </tna:batchIdentifier>
        <tna:departmentIdentifier rdf:datatype="xs:string">
            <xsl:value-of select="$department"/>
        </tna:departmentIdentifier>
        <tna:divisionIdentifier rdf:datatype="xs:decimal">
            <xsl:value-of select="$csv-row/elem[@name eq 'division']/text()"/>
        </tna:divisionIdentifier>
        <tna:seriesIdentifier rdf:datatype="xs:string">
            <xsl:value-of select="$series"/>
        </tna:seriesIdentifier>
    </xsl:template>

    <xsl:template name="create-legal-metadata">
        <xsl:param name="csv-row" as="node()"/>
        <xsl:variable name="transcription-row" select="f:get-transcription-row($csv-row)"/>
        <tna:legalStatus>
            <xsl:attribute name="rdf:resource" select="cf:get-legal-status-uri($transcription-row)"/>
        </tna:legalStatus>
        <tna:heldBy rdf:datatype="xs:string">
            <xsl:value-of select="$transcription-row/elem[@name eq 'held_by']/text()"/>
        </tna:heldBy>
    </xsl:template>


    <xsl:template name="create-file-cataloguing">
        <xsl:param name="csv-row" as="node()"/>
        <xsl:param name="collection-identifier" as="xs:string"/>
        <xsl:param name="datagov-resource-root" as="xs:string"/>
        <tna:cataloguing>
              <tna:Cataloguing>
                <xsl:call-template name="create-item-cataloguing-elements">
                    <xsl:with-param name="csv-row" select="$csv-row"/>
                    <xsl:with-param name="collection-identifier" select="$collection-identifier"/>
                    <xsl:with-param name="is-du" select="false()"/>
                </xsl:call-template>
                <xsl:call-template name="create-legal-metadata">
                    <xsl:with-param name="csv-row" select="$csv-row"/>
                </xsl:call-template>
            </tna:Cataloguing>
        </tna:cataloguing>
    </xsl:template>


    <xsl:template name="create-item-cataloguing">
        <xsl:param name="csv-row" as="node()"/>
        <xsl:param name="collection-identifier" as="xs:string"/>
        <xsl:param name="datagov-resource-root" as="xs:string"/>
        <tna:cataloguing>
            <tna:Cataloguing>
                <xsl:call-template name="create-item-cataloguing-elements">
                    <xsl:with-param name="csv-row" select="$csv-row"/>
                    <xsl:with-param name="collection-identifier" select="$collection-identifier"/>
                    <xsl:with-param name="is-du" select="true()"/>
                </xsl:call-template>
                <xsl:call-template name="prepend-archivist-note-with-closure-note">
                    <xsl:with-param name="csv-row" select="$csv-row"/>
                </xsl:call-template>
                <xsl:call-template name="create-legal-metadata">
                    <xsl:with-param name="csv-row" select="$csv-row"/>
                </xsl:call-template>
                <xsl:if test="$csv-row/transcription/elem[@name eq 'note'] ne ''">
                    <tna:note rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/transcription/elem[@name eq 'note']"/>
                    </tna:note>
                </xsl:if>
            </tna:Cataloguing>
        </tna:cataloguing>
    </xsl:template>

    <xsl:template name="prepend-archivist-note-with-closure-note">
        <xsl:param name="csv-row" as="node()"/>
        <xsl:if test="$csv-row/transcription/elem[@name eq 'archivist_note'] ne''">
            <xsl:element name="tna:archivistNote">
                <xsl:element name="tna:ArchivistNote">
                    <xsl:element name="tna:archivistNoteInfo">
                        <xsl:value-of
                                select="$csv-row/transcription/elem[@name eq 'archivist_note']"/>
                    </xsl:element>
                    <xsl:element name="tna:archivistNoteDate">
                        <xsl:value-of
                                select="$csv-row/transcription/elem[@name eq 'archivist_note_year']"/>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <xsl:template name="create-item-cataloguing-elements">
        <xsl:param name="csv-row" as="node()"/>
        <xsl:param name="collection-identifier" as="xs:string"/>
        <xsl:param name="is-du" as="xs:boolean"/>
        <xsl:variable name="transcription-row" select="f:get-transcription-row($csv-row)"/>

        <xsl:call-template name="create-collection-to-series-metadata">
            <xsl:with-param name="csv-row" select="$csv-row"/>
            <xsl:with-param name="department" select="$csv-row/elem[@name eq 'department']/text()"/>
            <xsl:with-param name="series" select="$csv-row/elem[@name eq 'series']/text()"/>
            <xsl:with-param name="collection-identifier" select="$collection-identifier"/>
        </xsl:call-template>

        <xsl:call-template name="create-sub-series-metadata">
            <xsl:with-param name="csv-row" select="$csv-row"/>
        </xsl:call-template>

        <tna:pieceIdentifier rdf:datatype="xs:decimal">
            <xsl:value-of select="$csv-row/elem[@name eq 'piece']/text()"/>
        </tna:pieceIdentifier>
        <xsl:if test="not($is-du)">
            <xl:if test="$csv-row/elem[@name eq 'item'] !=''">
                <tna:itemIdentifier rdf:datatype="xs:string">
                    <xsl:value-of select="$csv-row/elem[@name eq 'item']"/>
                </tna:itemIdentifier>
            </xl:if>
        </xsl:if>
        <xsl:if test="$is-du">
            <tna:itemIdentifier rdf:datatype="xs:string">
                <xsl:value-of select="$csv-row/elem[@name eq 'item']"/>
            </tna:itemIdentifier>
        </xsl:if>
        <xsl:if test="$csv-row/elem[@name eq 'sub_item'] !=''">
            <tna:subItemIdentifier rdf:datatype="xs:string">
                <xsl:value-of select="$csv-row/elem[@name eq 'sub_item']"/>
            </tna:subItemIdentifier>
        </xsl:if>
        <xsl:if test="$is-du">
            <xsl:if test="$transcription-row/elem[@name eq 'iaid'] !=''">
                <tna:iaid rdf:datatype="xs:string">
                    <xsl:value-of select="$transcription-row/elem[@name eq 'iaid']"/>
                </tna:iaid>
            </xsl:if>
            <xsl:if test="$transcription-row/elem[@name eq 'related_iaid'] !=''">
                <tna:relatedIaid rdf:datatype="xs:string">
                    <xsl:value-of select="$transcription-row/elem[@name eq 'related_iaid']"/>
                </tna:relatedIaid>
            </xsl:if>
        </xsl:if>
        <xsl:if test="not($is-du) and $csv-row/elem[@name eq 'ordinal'] != ''">
            <tna:ordinal rdf:datatype="xs:decimal">
                <xsl:value-of select="$csv-row/elem[@name eq 'ordinal']"/>
            </tna:ordinal>
        </xsl:if>
        <xsl:if test="$transcription-row/elem[@name eq 'description'] != ''">
            <dc:description rdf:datatype="xs:string">
                <xsl:value-of select="$transcription-row/elem[@name eq 'description']"/>
            </dc:description>
        </xsl:if>
        <xsl:call-template name="create-coverage">
            <xsl:with-param name="csv-row" select="$csv-row"/>
        </xsl:call-template>

    </xsl:template>

    <xsl:template name="create-digital-file">
        <xsl:param name="csv-row" as="node()"/>
        <tna:digitalFile>
            <tna:DigitalFile>
                <tna:fileIdentifier rdf:datatype="xs:string">
                    <xsl:value-of select="$csv-row/elem[@name eq 'file_uuid']"/>
                </tna:fileIdentifier>
                <tna:filePathAndName rdf:datatype="xs:string">
                    <xsl:value-of select="$csv-row/elem[@name eq 'file_path']"/>
                </tna:filePathAndName>
                <tna:sha256Checksum rdf:datatype="xs:string">
                    <xsl:value-of select="$csv-row/elem[@name eq 'file_checksum']"/>
                </tna:sha256Checksum>
                <xsl:if test="$csv-row/elem[@name eq 'discovery_file_id']">
                    <tna:discoveryFileId rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/elem[@name eq 'discovery_file_id']"/>
                    </tna:discoveryFileId>
                </xsl:if>
            </tna:DigitalFile>
        </tna:digitalFile>
    </xsl:template>

    <xsl:template name="create-provenance">
        <xsl:param name="csv-row" as="node()"/>
        <tna:provenance>
            <tna:Provenance>
                <tna:scanOperator rdf:datatype="xs:string">
                    <xsl:value-of select="$csv-row/elem[@name eq 'scan_operator']"/>
                </tna:scanOperator>
                <tna:scanId rdf:datatype="xs:string">
                    <xsl:value-of select="$csv-row/elem[@name eq 'scan_id']"/>
                </tna:scanId>
                <tna:scanLocation rdf:datatype="xs:string">
                    <xsl:value-of select="$csv-row/elem[@name eq 'scan_location']"/>
                </tna:scanLocation>
                <xsl:variable name="image-split" select="$csv-row/elem[@name eq 'image_split']"/>
                <tna:imageSplit rdf:datatype="xs:string">
                    <xsl:value-of select="$image-split"/>
                </tna:imageSplit>
                <xsl:if test="$image-split eq 'composite'">
                    <tna:imageSplitOrdinal rdf:datatype="xs:decimal">
                        <xsl:value-of select="$csv-row/elem[@name eq 'image_split_ordinal']"/>
                    </tna:imageSplitOrdinal>
                </xsl:if>
                <xsl:if test="($image-split eq 'yes') or ($image-split eq 'composite')">
                    <tna:imageSplitOtherUuid rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/elem[@name eq 'image_split_other_uuid']"/>
                    </tna:imageSplitOtherUuid>
                </xsl:if>
                <tna:imageCrop rdf:datatype="xs:string">
                    <xsl:value-of select="$csv-row/elem[@name eq 'image_crop']"/>
                </tna:imageCrop>
                <tna:imageDeskew rdf:datatype="xs:string">
                    <xsl:value-of select="$csv-row/elem[@name eq 'image_deskew']"/>
                </tna:imageDeskew>
                <xsl:if test="$csv-row/elem[@name eq 'scan_native_format'] ne ''">
                    <tna:scanNativeFormat rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/elem[@name eq 'scan_native_format']"/>
                    </tna:scanNativeFormat>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'process_location'] ne ''">
                    <tna:processLocation rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/elem[@name eq 'process_location']"/>
                    </tna:processLocation>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'scan_timestamp'] ne ''">
                    <tna:scanTimestamp rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/elem[@name eq 'scan_timestamp']"/>
                    </tna:scanTimestamp>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'jp2_creation_timestamp'] ne ''">
                    <tna:jp2CreationTimestamp rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/elem[@name eq 'jp2_creation_timestamp']"/>
                    </tna:jp2CreationTimestamp>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'uuid_timestamp'] ne ''">
                    <tna:uuidTimestamp rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/elem[@name eq 'uuid_timestamp']"/>
                    </tna:uuidTimestamp>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'embed_timestamp'] ne ''">
                    <tna:embedTimestamp rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/elem[@name eq 'embed_timestamp']"/>
                    </tna:embedTimestamp>
                </xsl:if>

               <!-- Tech env data -->

                <xsl:if test="$csv-row/techenv/elem[@name eq 'company_name'] ne ''">
                    <tna:companyName rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/techenv/elem[@name eq 'company_name']"/>
                    </tna:companyName>
                </xsl:if>
                <xsl:if test="$csv-row/techenv/elem[@name eq 'jp2_creation_software'] ne ''">
                    <tna:jp2CreationSoftware rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/techenv/elem[@name eq 'jp2_creation_software']"/>
                    </tna:jp2CreationSoftware>
                </xsl:if>
                <xsl:if test="$csv-row/techenv/elem[@name eq 'uuid_software'] ne ''">
                    <tna:uuidSoftware rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/techenv/elem[@name eq 'uuid_software']"/>
                    </tna:uuidSoftware>
                </xsl:if>
                <xsl:if test="$csv-row/techenv/elem[@name eq 'embed_software'] ne ''">
                    <tna:embedSoftware rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/techenv/elem[@name eq 'embed_software']"/>
                    </tna:embedSoftware>
                </xsl:if>
                <xsl:if test="$csv-row/techenv/elem[@name eq 'image_crop_software'] ne ''">
                    <tna:imageCropSoftware rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/techenv/elem[@name eq 'image_crop_software']"/>
                    </tna:imageCropSoftware>
                </xsl:if>
                <xsl:if test="$csv-row/techenv/elem[@name eq 'image_split_software'] ne ''">
                    <tna:imageSplitSoftware rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/techenv/elem[@name eq 'image_split_software']"/>
                    </tna:imageSplitSoftware>
                </xsl:if>
                <xsl:if test="$csv-row/techenv/elem[@name eq 'image_deskew_software'] ne ''">
                    <tna:imageDeskewSoftware rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/techenv/elem[@name eq 'image_deskew_software']"/>
                    </tna:imageDeskewSoftware>
                </xsl:if>
                <xsl:if test="$csv-row/elem[@name eq 'tiled_jp2'] ne ''">
                    <tna:tiledJp2 rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/elem[@name eq 'tiled_jp2']"/>
                    </tna:tiledJp2>
                </xsl:if>

                <!-- End tech env data -->

            </tna:Provenance>
        </tna:provenance>
    </xsl:template>


    <xsl:template name="create-digital-image">
        <xsl:param name="csv-row" as="node()"/>
        <tna:digitalImage>
            <tna:DigitalImage>
                <tna:imageResolution rdf:datatype="xs:decimal">
                    <xsl:value-of select="$csv-row/elem[@name eq 'image_resolution']"/>
                </tna:imageResolution>
                <tna:imageWidth rdf:datatype="xs:decimal">
                    <xsl:value-of select="$csv-row/elem[@name eq 'image_width']"/>
                </tna:imageWidth>
                <tna:imageHeight rdf:datatype="xs:decimal">
                    <xsl:value-of select="$csv-row/elem[@name eq 'image_height']"/>
                </tna:imageHeight>
                <tna:imageTonalResolution rdf:datatype="xs:string">
                    <xsl:value-of select="$csv-row/elem[@name eq 'image_tonal_resolution']"/>
                </tna:imageTonalResolution>
                <tna:imageFormat rdf:datatype="xs:string">
                    <xsl:value-of select="$csv-row/elem[@name eq 'image_format']"/>
                </tna:imageFormat>
                <xsl:if test="$csv-row/elem[@name eq 'image_compression'] ne ''">
                    <tna:imageCompression rdf:datatype="xs:string">
                        <xsl:value-of select="$csv-row/elem[@name eq 'image_compression']"/>
                    </tna:imageCompression>
                </xsl:if>
                <tna:imageColourSpace rdf:datatype="xs:decimal">
                    <xsl:value-of select="$csv-row/elem[@name eq 'image_colour_space']"/>
                </tna:imageColourSpace>
            </tna:DigitalImage>
        </tna:digitalImage>
    </xsl:template>

    <xsl:template name="create-coverage">
        <xsl:param name="csv-row" as="node()"/>
        <xsl:variable name="transcription-row" select="f:get-transcription-row($csv-row)"/>
         <dcterms:coverage>
            <xsl:choose>
                <xsl:when test="$transcription-row/elem[@name eq 'date_range'] != ''">
                    <xsl:element name="tna:dateRange">
                        <xsl:attribute name="rdf:datatype" select="'xs:string'"/>
                        <xsl:value-of select="$transcription-row/elem[@name eq 'date_range']"/>
                    </xsl:element>
                </xsl:when>
                <xsl:when test="$transcription-row/elem[@name eq 'covering_dates'] != ''">
                    <tna:CoveringDates>
                        <xsl:variable name="cover-date" select="$transcription-row/elem[@name eq 'covering_dates']"/>
                        <xsl:variable name="start" select="substring-before($cover-date,'-')"/>
                        <xsl:variable name="end" select="substring-after($cover-date,'-')"/>
                        <!-- startDate and endDate are mandatory. fullDate is optional for backward compatibility
                             The splitting here is based upon ADM_362 More robust date handling in discovery transfer-->
                        <tna:fullDate>
                            <xsl:value-of select="$cover-date"/>
                        </tna:fullDate>
                        <tna:startDate>
                            <xsl:choose>
                                <xsl:when test="contains($start,'[')">
                                    <xsl:value-of select="normalize-space(substring-after($start, '['))"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="normalize-space($start)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </tna:startDate>
                        <tna:endDate>
                            <xsl:choose>
                                <xsl:when test="contains($end,']')">
                                    <xsl:value-of select="normalize-space(substring-before($end, ']'))"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="normalize-space($end)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </tna:endDate>
                    </tna:CoveringDates>
                </xsl:when>
            </xsl:choose>
        </dcterms:coverage>
    </xsl:template>

    <xsl:template name="create-sub-series-metadata">
        <xsl:param name="csv-row" as="node()"/>
        <xsl:if test="$csv-row/elem[@name eq 'sub_series']/text() ne ''">
            <tna:subSeriesIdentifier rdf:datatype="xs:decimal">
                <xsl:value-of select="$csv-row/elem[@name eq 'sub_series']/text()"/>
            </tna:subSeriesIdentifier>
        </xsl:if>
        <xsl:if test="$csv-row/elem[@name eq 'sub_sub_series']/text() ne ''">
            <tna:subSubSeriesIdentifier rdf:datatype="xs:decimal">
                <xsl:value-of select="$csv-row/elem[@name eq 'sub_sub_series']/text()"/>
            </tna:subSubSeriesIdentifier>
        </xsl:if>
    </xsl:template>

    <xsl:function name="f:get-transcription-row">
        <xsl:param name="csv-row" as="node()"/>
        <xsl:choose>
            <xsl:when test="exists($csv-row/transcription)">
                <xsl:copy-of select="$csv-row/transcription"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$csv-row"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
</xsl:stylesheet>