<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:c="http://nationalarchives.gov.uk/dri/closure"
                xmlns:xip="http://www.tessella.com/XIP/v4"
                xmlns:tna="http://nationalarchives.gov.uk/metadata/tna#"
                xmlns:dc="http://purl.org/dc/terms/"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:csf="http://catalogue/service/functions"
                xmlns:f="http://local/functions"
                xmlns:functx="http://www.functx.com"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:xslt="http://www.w3.org/1999/XSL/Transform"
                xmlns:fntcm="http://tna.gov.uk/transform/functions/common/metadata"
                xmlns:fn="http://www.w3.org/2005/xpath-functions"
                exclude-result-prefixes="xs xsi xip tna dc"
                version="2.0">

    <xsl:import href="catalogue-service-functions.xslt"/>
    <xsl:import href="decode-uri-function.xslt"/>
    <xsl:import href="common-metadata-functions.xslt"/>
    <xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>

    <!-- Born Digital Ingest : Create Closure Document
        ===============================================
        Creates a closure document with closure information for all deliverable units and files. This document can then be submitted to the DRI Catalogue.
        This transformation is applied to the XIP document and reads closure information from the XML version of the closure CSV file.

        For deliverable units (DUs) this process works as follows:-
        1) Reads the file path that the DU refers to from the embedded metadata
        2) Checks whether this file path appears in the closure CSV/XML and if so applies this closure
        3) If the file itself does not appear looks for ancestor DUs and checks whether these are referred to in the closure file.
        4) If an ancestor appears in the closure file and it is of folder type then this closure is applied.
        5) Otherwise the default closure (open) is applied.

        For files this process works exactly the same except that the appropriate DU is located first.

        Author: Rob Walpole
        Date: 11-03-2014
    -->

    <!-- stylesheet parameters -->
    <!--<xsl:param name="closure-csv-xml-path" as="xs:string">file:///tmp/cucumber-ffcddcfc-40ef-47c1-b477-10c2fbbe89f1/HO519Y13S001/HO_519/closure_v7.csv.xml</xsl:param>-->
    <xsl:param name="closure-csv-xml-path" as="xs:string" required="yes"/>
    <!-- TODO remove these two params in favour of rejigging the workflow to extract the partId from the incoming SIP XIP XML -->
    <!--<xsl:param name="series" as="xs:string" >HO_519</xsl:param>-->
    <!--<xsl:param name="unit-id" as="xs:string">HO519Y13S001</xsl:param>-->
    <xsl:param name="series" as="xs:string" required="yes"/>
    <xsl:param name="unit-id" as="xs:string" required="yes"/>

    <!-- global stylesheet variables -->
    <xsl:variable name="part-id" as="xs:string" select="concat($unit-id, '/', $series)"/>

    <!-- get csv filename from csv.xml file path -->
    <xsl:variable name="csv-file" select="replace($closure-csv-xml-path, '.*/(.*)\.xml', '$1')"/>
    <xsl:variable name="csv-schema" as="xs:string">
        <xsl:choose>
            <xsl:when test="contains($csv-file, '[0-9]{3}.csv')">
                <xsl:value-of select="replace($csv-file,'[0-9]{3}.csv','000.csvs')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="replace($csv-file, '.csv','.csvs')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="csv" as="document-node(element(root))">
        <xsl:choose>
            <xsl:when test="doc-available($closure-csv-xml-path)">
                <xsl:copy-of select="doc($closure-csv-xml-path)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes" select="concat('Closure CSV ''', $closure-csv-xml-path,''' is not available!')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- keys -->
    <xsl:key name="row-by-identifier" match="root/row"
             use="f:decode-uri(string(elem[@name eq 'identifier']/text()))"/>

    <xsl:variable name="substitution-key">
        <xsl:variable name="identifier" select="$csv/root/row[1]/elem[@name = 'identifier']/text()"/>
        <xsl:value-of select="substring-before($identifier,substring-after($part-id,'/'))"/>
    </xsl:variable>

    <!-- File substitutions -->
    <xsl:variable name="substitution-key-ends-with-slash" select="ends-with($substitution-key,'/')"/>

    <xsl:key name="key-decoded-closure-paths" match="root/row" use="f:decode-uri(elem[@name eq 'identifier']/replace(text(), $substitution-key, ''))" />

    <!-- resolves the correct closure type from the entry in the CSV/XML -->
    <xsl:template name="create-closure-type">
        <xsl:param name="closure" as="node()"/>
        <xsl:variable name="closure-type">
            <xsl:choose>
                <xsl:when test="$closure/elem[@name eq 'retention_type'] ne  ''">
                    <xsl:value-of select="$closure/elem[@name eq 'retention_type']"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$closure/elem[@name eq 'closure_type']"/>
                </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
        <xsl:choose>
            <xsl:when test="$closure-type eq 'closed_review'">C</xsl:when>
            <xsl:when test="$closure-type eq 'retained_until'">D</xsl:when>
            <xsl:when test="$closure-type eq 'closed_for'">F</xsl:when>
            <xsl:when test="$closure-type eq 'normal_closure_before_foi'">N</xsl:when>
            <xsl:when test="$closure-type eq 'retained_under_3.4'">S</xsl:when>
            <xsl:when test="$closure-type eq 'temporarily_retained'">T</xsl:when>
            <xsl:when test="$closure-type eq 'closed_until'">U</xsl:when>
            <xsl:when test="$closure-type eq 'closed_access_reviewed'">V</xsl:when>
            <xsl:when test="$closure-type eq 'reclosed_in'">W</xsl:when>
            <xsl:when test="$closure-type eq 'open_on_transfer'">A</xsl:when>
        </xsl:choose>
    </xsl:template>

    <!-- creates a default closure node (open) -->
    <xsl:template name="default-closure">
        <xsl:param name="uuid" as="xs:string"/>
        <xsl:param name="closure" as="node()*"/>
        <xsl:param name="is-file" as="xs:boolean"/>
        <xsl:element name="c:closure">
            <xsl:choose>
                <xsl:when test="$is-file">
                    <xsl:attribute name="resourceType" select="'File'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="resourceType" select="'DeliverableUnit'"/>
                </xsl:otherwise>
            </xsl:choose>

            <c:uuid>
                <xsl:value-of select="$uuid"/>
            </c:uuid>
            <c:documentClosureStatus>OPEN</c:documentClosureStatus>
            <xsl:if test="exists($closure/elem[@name eq 'description_public'])">
                    <xsl:choose>
                        <xsl:when test="$closure/elem[@name eq 'description_public']/text() eq 'TRUE' or $closure/elem[@name eq 'description_public']/text() eq '1' ">
                            <c:descriptionClosureStatus>OPEN</c:descriptionClosureStatus>
                        </xsl:when>
                        <xslt:otherwise>
                            <c:descriptionClosureStatus>CLOSED</c:descriptionClosureStatus>
                        </xslt:otherwise>
                    </xsl:choose>
            </xsl:if>
            <xsl:if test="exists($closure/elem[@name eq 'title_public'])">
                <xsl:choose>
                    <xsl:when
                            test="$closure/elem[@name eq 'title_public']/text() eq 'TRUE' or $closure/elem[@name eq 'title_public']/text() ='1'">
                        <c:titleClosureStatus>OPEN</c:titleClosureStatus>
                    </xsl:when>
                    <xsl:otherwise>
                        <c:titleClosureStatus>CLOSED</c:titleClosureStatus>
                        <c:titleAlternate>
                            <xsl:value-of select="$closure/elem[@name eq 'title_alternate']"></xsl:value-of>
                        </c:titleAlternate>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xslt:choose>
                <xslt:when test="empty($closure)">
                    <c:closureType>A</c:closureType>
                </xslt:when>
                <xslt:otherwise>
                    <c:closureType>
                        <xsl:call-template name="create-closure-type">
                            <xsl:with-param name="closure" select="$closure"/>
                        </xsl:call-template>
                    </c:closureType>
                </xslt:otherwise>
            </xslt:choose>

            <c:closureCode>0</c:closureCode>
            <c:closurePeriod>0</c:closurePeriod>

            <!-- the opening date must always be stored as UTC -->
            <xsl:choose>
                <xsl:when test="(not(exists($closure/elem[@name eq 'opening_date'])) or ($closure/elem[@name eq 'opening_date'] eq '')) and  ($closure/elem[@name eq 'closure_type'] eq 'normal_closure_before_foi')">
                    <!-- Records before FOI act don't have opening date, ex: MH 12, PRO 23 -->
                </xsl:when>
                <xsl:when test="(not(exists($closure/elem[@name eq 'opening_date'])) or ($closure/elem[@name eq 'opening_date'] eq '')) and  ($closure/elem[@name eq 'closure_type'] eq 'temporarily_retained')">
                    <!-- Records temporarily retained don't have opening date  -->
                </xsl:when>
                <xsl:when test="$closure/elem[@name eq 'opening_date'] ne ''">
                    <c:openingDate>
                        <xsl:value-of select="adjust-dateTime-to-timezone(fntcm:opening-date-to-dateTime($closure/elem[@name eq 'opening_date']), xs:dayTimeDuration('PT0H'))"/>
                    </c:openingDate>
                </xsl:when>
                <xsl:otherwise>
                    <c:openingDate>
                        <xsl:value-of select="adjust-dateTime-to-timezone(current-dateTime(), xs:dayTimeDuration('PT0H'))"/>
                    </c:openingDate>
                </xsl:otherwise>
            </xsl:choose>

        </xsl:element>
    </xsl:template>

    <!-- creates a custom closure node -->
    <xsl:template name="create-closure">
        <xsl:param name="uuid" as="xs:string"/>
        <xsl:param name="closure" as="node()"/>
        <xsl:param name="is-file" as="xs:boolean"/>

        <xsl:variable name="closure-type">
            <xsl:value-of select="$closure/elem[@name eq 'closure_type']"/>
        </xsl:variable>
        <xsl:variable name="isRetained" select="$closure/elem[@name = 'retention_type'] ne ''"/>

        <xslt:variable name="foi-exemption-code">
            <xslt:value-of select="$closure/elem[@name eq 'foi_exemption_code']" />
        </xslt:variable>

        <xsl:variable name="requiedDefaultClosure" as="xs:boolean">
            <xsl:choose>
                <xsl:when test="($closure-type eq 'open_on_transfer')">
                    <xsl:value-of select="true()" />
                </xsl:when>
                <xsl:when test="($closure-type eq 'normal_closure_before_foi') and  ($foi-exemption-code eq 'open')" >
                    <xsl:value-of select="true()" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="false()" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="($requiedDefaultClosure eq true())">
                <xsl:call-template name="default-closure">
                    <xsl:with-param name="uuid" select="$uuid"/>
                    <xsl:with-param name="closure" select="$closure"/>
                    <xsl:with-param name="is-file" select="$is-file"/>
                </xsl:call-template>
            </xsl:when>

            <xsl:otherwise>
                <xsl:variable name="closure_period" as="xs:string" select="$closure/elem[@name eq 'closure_period']"/>
                <xsl:variable name="closure-period-array" as="xs:string*" select="tokenize($closure_period,',')"/>
                <xsl:variable name="max-closure-period" select = "functx:max-determine-type($closure-period-array)"/>
                <!-- The following line creates a duration based on a period of format string. The period can be expressed
                     as P10Y or P70Y etc. however, if the max-closure-period is blank then the format string evaluates to
                     'PY' which causes invalid duration exception, hence we prefix any duration with '0'  to make sure we
                     always end up with a valid duration e.g. P010Y P070Y or P0Y -->
                <xsl:variable name="closure-period-duration" select="xs:yearMonthDuration(concat('P0',$max-closure-period,'Y'))"/>
                <xsl:variable name="day1-duration" select="xs:dayTimeDuration('P1D')"/>
                <xsl:element name="c:closure">
                    <xsl:choose>
                        <xsl:when test="$is-file">
                            <xsl:attribute name="resourceType" select="'File'"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="resourceType" select="'DeliverableUnit'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <c:uuid>
                        <xsl:value-of select="$uuid"/>
                    </c:uuid>
                    <c:documentClosureStatus>CLOSED</c:documentClosureStatus>

                    <xsl:if test="exists($closure/elem[@name eq 'description_public'])">
                        <xsl:choose>
                            <xsl:when test="$closure/elem[@name eq 'description_public']/text() eq 'TRUE' or $closure/elem[@name eq 'description_public']/text() eq '1'">
                                <c:descriptionClosureStatus>OPEN</c:descriptionClosureStatus>
                            </xsl:when>
                            <xsl:otherwise>
                                <c:descriptionClosureStatus>CLOSED</c:descriptionClosureStatus>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>

                    <xsl:if test="exists($closure/elem[@name eq 'title_public'])">
                        <xsl:choose>
                            <xsl:when test="$closure/elem[@name eq 'title_public']/text() eq 'TRUE' or $closure/elem[@name eq 'title_public']/text() = '1'">
                                <c:titleClosureStatus>OPEN</c:titleClosureStatus>
                            </xsl:when>
                            <xsl:otherwise><c:titleClosureStatus>CLOSED</c:titleClosureStatus></xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>

                    <c:closureType>
                        <xsl:call-template name="create-closure-type">
                            <xsl:with-param name="closure" select="$closure"/>
                        </xsl:call-template>
                    </c:closureType>
                    <c:closureCode>
                        <xsl:value-of select="$max-closure-period"/>
                    </c:closureCode>
                    <xsl:choose>
                        <xsl:when test="not($isRetained)">
                            <xsl:variable name="closure-start-date" select="xs:dateTime($closure/elem[@name eq 'closure_start_date'])" />
                            <c:startDate>
                                <xslt:value-of select="adjust-dateTime-to-timezone($closure-start-date, xs:dayTimeDuration('PT0H'))" />
                            </c:startDate>
                            <c:closurePeriod>
                                <xsl:value-of select="$max-closure-period"/>
                            </c:closurePeriod>
                            <c:openingDate>
                                <!-- opening date must always be stored as UTC -->
                                <xsl:choose>
                                    <xsl:when test="$closure/elem[@name eq 'opening_date'] ne ''">
                                        <xsl:value-of select="adjust-dateTime-to-timezone(fntcm:opening-date-to-dateTime($closure/elem[@name eq 'opening_date']), xs:dayTimeDuration('PT0H'))"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="adjust-dateTime-to-timezone($closure-start-date + $closure-period-duration + $day1-duration, xs:dayTimeDuration('PT0H'))"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </c:openingDate>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:if test="exists($closure/elem[@name eq 'retention_justification'])">
                                <xsl:variable name="retentionJustification" select="$closure/elem[@name eq 'retention_justification']"/>
                                <xsl:choose>
                                  <xsl:when test="$retentionJustification eq ''">
                                      <xsl:if test="exists($closure/elem[@name eq 'retention_type']) and $closure/elem[@name eq 'retention_type']/text() ne ''">
                                          <xsl:sequence select="fn:error(fn:QName('Error', 'retention_justification'), concat('retention_justification cannot be empty when retention_type is: ', $closure/elem[@name eq 'retention_type'] , ' for ', $closure/elem[@name eq 'identifier']))"/>
                                      </xsl:if>
                                  </xsl:when>
                                  <xsl:otherwise>
                                      <xsl:choose>
                                          <xsl:when test="$retentionJustification eq '1' or $retentionJustification eq '2' or $retentionJustification eq '4a'
                                          or $retentionJustification eq '4b' or $retentionJustification eq '6' or $retentionJustification eq '8'">
                                              <c:retentionJustification>
                                                  <xsl:value-of select="$retentionJustification"/>
                                              </c:retentionJustification>
                                          </xsl:when>
                                          <xsl:otherwise>
                                              <xsl:sequence select="fn:error(fn:QName('Error', 'retention_justification'), concat('Unknown retention_justification value: ', $retentionJustification, ' for ', $closure/elem[@name eq 'identifier']))"/>
                                          </xsl:otherwise>
                                      </xsl:choose>
                                  </xsl:otherwise>
                              </xsl:choose>
                            </xsl:if>
                                <xsl:if test="exists($closure/elem[@name eq 'retention_reconsider_date'])">
                                    <xsl:choose>
                                        <xsl:when test="$closure/elem[@name eq 'retention_reconsider_date']/text() ne ''">
                                            <xsl:choose>
                                                <xsl:when test="$closure/elem[@name eq 'retention_reconsider_date']/text() castable as xs:dateTime">
                                                    <c:retentionReconsiderDate>
                                                        <xsl:value-of select="$closure/elem[@name eq 'retention_reconsider_date']/text()"/>
                                                    </c:retentionReconsiderDate>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:sequence select="fn:error(fn:QName('Error', 'retention_reconsider_date'), concat('retention_reconsider_date is not in format YYYY-MM-DDTHH:mm:ss for ', $closure/elem[@name eq 'identifier']))"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:when>
                                    </xsl:choose>
                                </xsl:if>
                            <xsl:choose>
                                <xsl:when test="$closure/elem[@name eq 'RI_number'] ne ''">
                                    <xsl:variable name="riNumber" select="$closure/elem[@name eq 'RI_number']" />
                                    <xsl:choose>
                                        <xsl:when test="matches($riNumber, '^\d+$')">
                                            <c:RINumber>
                                                <xsl:value-of select="$riNumber"/>
                                            </c:RINumber>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:sequence select="fn:error(fn:QName('Error', 'RI_Number'), concat('RI_Number format invalid : ', $riNumber , ' for ', $closure/elem[@name eq 'identifier']))"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:if test="$closure/elem[@name eq 'retention_justification']/text() eq '6'">
                                        <xsl:sequence select="fn:error(fn:QName('Error', 'RI_number'), concat('RI_number cannot be empty for ', $closure/elem[@name eq 'identifier']))"/>
                                    </xsl:if>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="exists($closure/elem[@name eq 'RI_signed_date'])">
                                <xsl:variable name="riSignedDate" select="$closure/elem[@name eq 'RI_signed_date']/text()"/>
                                <xsl:if test="$riSignedDate ne ''">
                                    <xsl:choose>
                                        <xsl:when test="$riSignedDate castable as xs:dateTime">
                                            <c:RISignedDate>
                                                <xsl:value-of select="$riSignedDate"/>
                                            </c:RISignedDate>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:sequence select="fn:error(fn:QName('Error', 'RI_Signed_Date'), concat('RI_signed_date is not in format YYYY-MM-DDTHH:mm:ss for ', $closure/elem[@name eq 'identifier']))"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:if>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>

                    <xsl:if test="exists($closure/elem[@name eq 'author'])">
                        <c:author>
                            <xsl:value-of select="$closure/elem[@name eq 'author']"/>
                        </c:author>
                    </xsl:if>
                    <xsl:if test="exists($closure/elem[@name eq 'foi_exemption_code']) and ($closure/elem[@name eq 'foi_exemption_code'] ne '')">
                        <xsl:for-each select="tokenize($closure/elem[@name eq 'foi_exemption_code']/text(), ',')">
                            <c:exemptionCode><xsl:value-of select="f:get-exemption-code-string(functx:trim(.))"/></c:exemptionCode>
                        </xsl:for-each>
                    </xsl:if>
                    <xsl:if test="exists($closure/elem[@name eq 'foi_exemption_asserted']) and ($closure/elem[@name eq 'foi_exemption_asserted'] ne '')">
                        <c:exemptionAsserted>
                            <xsl:value-of select="$closure/elem[@name eq 'foi_exemption_asserted']"/>
                        </c:exemptionAsserted>
                    </xsl:if>
                    <xsl:if test="exists($closure/elem[@name eq 'description_alternate']) and ($closure/elem[@name eq 'description_alternate'] ne '')">
                        <c:descriptionAlternate>
                            <xsl:value-of select="$closure/elem[@name eq 'description_alternate']/text()"/>
                        </c:descriptionAlternate>
                    </xsl:if>
                    <xsl:if test="exists($closure/elem[@name eq 'title_alternate']) and ($closure/elem[@name eq 'title_alternate'] ne '')">
                        <c:titleAlternate>
                            <xsl:value-of select="$closure/elem[@name eq 'title_alternate']/text()"/>
                        </c:titleAlternate>
                    </xsl:if>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <!-- looks in the closure CSV/XML for an ancestor whilst retaining a reference to the actual UUID that closure is required for -->
    <xsl:template name="search-for-ancestor-closure">
        <xsl:param name="deliverable-unit" as="node()*"/>
        <xsl:param name="actual-uuid" as="xs:string"/>
        <xsl:param name="is-file" as="xs:boolean"/>
        <!-- TODOOOOOO - fix the following -->
        <!--<xsl:variable name="type" select="$deliverable-unit/xip:Metadata/tnaxm:metadata/dc:subject[@xsi:type='tnaxmbddc:bornDigitalRecord']/text()"/>-->
        <xsl:choose>
            <xsl:when test="empty($deliverable-unit)">
                <!-- I couldn't find the ancestor in the XIP, should look in catalogue TODOOOOOO-->
                <!-- <xsl:variable name="resource-type" select="folder"></xsl:variable>-->
                <xsl:call-template name="default-closure">
                    <xsl:with-param name="uuid" select="$actual-uuid"/>
                    <xsl:with-param name="is-file" select="$is-file"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="type">
                    <xsl:choose>
                        <xsl:when test="exists($deliverable-unit/xip:Metadata/tna:metadata/rdf:RDF/tna:DigitalFolder)">folder</xsl:when>
                        <xsl:otherwise>file</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="path" select="f:to-csv-path(replace($deliverable-unit/xip:Metadata/tna:metadata/rdf:RDF//tna:digitalFile/tna:DigitalFile/tna:filePathAndName/text(),$substitution-key,''), $substitution-key-ends-with-slash)"/>

                <xsl:variable name="decoded-path" select="f:decode-path($path,$type)"/>

               <xsl:variable name="decoded-substitution-key" select="f:decode-uri($substitution-key)"/>

               <xsl:variable name="closure" select="$csv/key('row-by-identifier', string(concat($decoded-substitution-key, $decoded-path)))" />

                <xsl:variable name="path-exist" select="$csv/key('key-decoded-closure-paths', $decoded-path)" />

                <xsl:choose>
                    <xsl:when test="($path-exist) and ($closure/elem[@name eq 'folder']/string() eq 'folder')">
                        <xsl:call-template name="create-closure">
                            <xsl:with-param name="uuid" select="$actual-uuid"/>
                            <xsl:with-param name="closure" select="$closure"/>
                            <xsl:with-param name="is-file" select="$is-file"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="ancestor-or-default">
                            <xsl:with-param name="deliverable-unit" select="$deliverable-unit"/>
                            <xsl:with-param name="actual-uuid" select="$actual-uuid"/>
                            <xsl:with-param name="is-file" select="$is-file"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- either continues to the next parent or outputs default closure -->
    <xsl:template name="ancestor-or-default">
        <xsl:param name="deliverable-unit" as="node()"/>
        <xsl:param name="actual-uuid" as="xs:string"/>
        <xsl:param name="is-file" as="xs:boolean"/>
        <xsl:variable name="du" select="/xip:XIP/xip:DeliverableUnits/xip:DeliverableUnit[xip:DeliverableUnitRef eq $deliverable-unit/xip:ParentRef]"></xsl:variable>
        <xsl:choose>
            <xsl:when test="exists($deliverable-unit/xip:ParentRef)">
                <xsl:call-template name="search-for-ancestor-closure">
                    <xsl:with-param name="deliverable-unit" select="$du"/>
                    <xsl:with-param name="actual-uuid" select="$actual-uuid"/>
                    <xsl:with-param name="is-file" select="$is-file"/>
                </xsl:call-template>
            </xsl:when>
            <!-- we have exhausted the ancestor search so just output default closure -->
            <xsl:otherwise>
                <xsl:call-template name="default-closure">
                    <xsl:with-param name="uuid" select="$actual-uuid"/>
                    <xsl:with-param name="is-file" select="$is-file"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- looks for the relevant path in the closure CSV/XML and otherwise looks for a parent -->
    <xsl:template name="resolve-closure">
        <xsl:param name="deliverable-unit" as="node()"/>
        <xsl:param name="actual-uuid" as="xs:string"/>
        <xsl:param name="is-file" as="xs:boolean"/>
        <!--<xsl:variable name="type" select="$deliverable-unit/xip:Metadata/tnaxm:metadata/dc:subject[@xsi:type='tnaxmbddc:bornDigitalRecord']/text()"/>-->
        <xsl:variable name="type">
            <xsl:choose>
                <xsl:when test="exists($deliverable-unit/xip:Metadata/tna:metadata/rdf:RDF/tna:DigitalFolder/tna:cataloguing/tna:Cataloguing/tna:subItemIdentifier)">sub_item</xsl:when>
                <xsl:when test="exists($deliverable-unit/xip:Metadata/tna:metadata/rdf:RDF/tna:DigitalFolder)">folder</xsl:when>
                <xsl:otherwise>file</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="path">
            <xsl:choose>
                <xsl:when test="$is-file">
                    <xsl:value-of select="f:to-csv-path(replace(xip:Metadata/tna:metadata/rdf:RDF//tna:digitalFile/tna:DigitalFile/tna:filePathAndName/text(), $substitution-key,''), $substitution-key-ends-with-slash)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="f:to-csv-path(replace($deliverable-unit/xip:Metadata/tna:metadata/rdf:RDF//tna:digitalFile/tna:DigitalFile/tna:filePathAndName/text(), $substitution-key,''), $substitution-key-ends-with-slash)"/>
                </xsl:otherwise>
            </xsl:choose>

        </xsl:variable>
        <xsl:variable name="decoded-path" select="f:decode-path($path,$type)"/>
        <xsl:variable name="decoded-substitution-key" select="f:decode-uri($substitution-key)"/>
        <xsl:variable name="decoded-subs-path" select="concat($decoded-substitution-key, $decoded-path)"/>

        <xsl:variable name="path-exist" select="$csv/key('key-decoded-closure-paths',$decoded-path)" />

        <xsl:choose>
            <!-- when the file is in the list of closures -->

            <xsl:when test="$path-exist">
                <!--<xsl:variable name = "closure" select="$csv/root/row[elem[@name eq 'identifier']/f:decode-uri(text()) eq concat($substitution-key, $decoded-path)]"/>-->
                <xsl:variable name="closure" select="$csv/key('row-by-identifier',$decoded-subs-path)"/>

                <xsl:call-template name="create-closure">
                    <xsl:with-param name="uuid" select="$actual-uuid"/>
                    <xsl:with-param name="closure" select="$closure"/>
                    <xsl:with-param name="is-file" select="$is-file"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="exists($deliverable-unit/xip:ParentRef)">
                        <xsl:variable name="parent-ref" select="$deliverable-unit/xip:ParentRef/text()"/>
                        <xsl:variable name="du" select="/xip:XIP/xip:DeliverableUnits/xip:DeliverableUnit[xip:DeliverableUnitRef eq $parent-ref]"/>
                        <xsl:call-template name="search-for-ancestor-closure">
                            <xsl:with-param name="actual-uuid" select="$actual-uuid"/>
                            <xsl:with-param name="deliverable-unit" select="$du"/>
                            <xsl:with-param name="is-file" select="$is-file"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="default-closure">
                            <xsl:with-param name="uuid" select="$actual-uuid"/>
                            <xsl:with-param name="is-file" select="$is-file"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- put out the closures root element -->
    <xsl:template match="xip:XIP">
        <c:closures>
            <xsl:apply-templates/>
        </c:closures>
    </xsl:template>

    <xsl:template match="xip:DeliverableUnits">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- TODO I am not certain the below is correct, all DU's not in _metadata path should have closure! -->

    <!-- every deliverable unit that is not a metadata file needs to have closure information -->
    <xsl:template match="xip:DeliverableUnit">
        <xsl:choose>
            <!-- we are interested in DUs with metadata (as all DU's apart from those *without* metadata are normal DUs that need closure) -->
            <xsl:when test="exists(xip:Metadata) and @status eq 'new'">
                <xsl:call-template name="resolve-closure">
                    <xsl:with-param name="deliverable-unit" select="."/>
                    <xsl:with-param name="actual-uuid" select="xip:DeliverableUnitRef/text()"/>
                    <xsl:with-param name="is-file" select="false()"/>
                </xsl:call-template>
            </xsl:when>
            <!-- we are also interested in top level DUs that are not the _metadata du  this will never work no closure sent-->
            <!--<xsl:when test="(not(exists(xip:ParentRef))) and (xip:Title ne '_metadata') and @status eq 'new'">-->
            <!--<xsl:call-template name="default-closure">-->
            <!--<xsl:with-param name="uuid" select="xip:DeliverableUnitRef"/>-->
            <!--<xsl:with-param name="resource-type" select="xs:string('DeliverableUnit')"/>-->
            <!--</xsl:call-template>-->
            <!--</xsl:when>-->
            <xsl:otherwise>
                <!-- no closure information required -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="xip:Files">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- every file that is not a metadata file needs to have closure information -->
    <xsl:template match="xip:File">
        <!--
            is there closure information for the file?
            if not is there closure information for the parent du or any of the parent du's ancestors?
            otherwise the file is open
        -->
        <xsl:variable name="file-ref" select="xip:FileRef"/>

        <!-- sometimes XSLT try to evaluate everything even, when first condition is false. We are preparing filepath
         only if element xip:Metadata exist, otherwise, we return placeholder.  -->
        <xsl:variable name="path-for-lookup">
            <xsl:choose>
                <xsl:when test="exists(xip:Metadata)">
                    <xsl:value-of select="f:decode-path(f:to-csv-path(replace(xip:Metadata/tna:metadata/rdf:RDF//tna:digitalFile/tna:DigitalFile/tna:filePathAndName/text(), $substitution-key,''),$substitution-key-ends-with-slash),'File')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'URL_WHICH_NEVER_BE_IN_CSV_CLOSURE_FILE'" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!--
        If closure exists for file use it
        -->
        <xsl:choose>
            <xsl:when test="exists(xip:Metadata) and $csv/key('key-decoded-closure-paths', $path-for-lookup)">
                <xsl:call-template name="resolve-closure">
                    <xsl:with-param name="deliverable-unit" select="."/>
                    <xsl:with-param name="actual-uuid" select="$file-ref"/>
                    <xsl:with-param name="is-file" select="true()"></xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="deliverable-unit-ref" select="/xip:XIP/xip:DeliverableUnits/xip:Manifestation[xip:ManifestationFile/xip:FileRef = $file-ref]/xip:DeliverableUnitRef"/>
                <xsl:variable name="deliverable-unit" select="/xip:XIP/xip:DeliverableUnits/xip:DeliverableUnit[xip:DeliverableUnitRef = $deliverable-unit-ref]"/>
                <xsl:if test="exists($deliverable-unit/xip:Metadata)">
                    <xsl:call-template name="resolve-closure">
                        <xsl:with-param name="deliverable-unit" select="$deliverable-unit"/>
                        <xsl:with-param name="actual-uuid" select="$file-ref"/>
                        <xsl:with-param name="is-file" select="true()"></xsl:with-param>
                    </xsl:call-template>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ignore unmatched nodes -->
    <xsl:template match="node()|@*">
        <xsl:apply-templates select="node()|@*"/>
    </xsl:template>


    <xsl:function name="f:to-csv-path" as="xs:string">
        <xsl:param name="xip-path" as="xs:string"/>
        <xsl:param name="substitute-key-ends-with-slash" as="xs:boolean"/>
        <xsl:choose>
            <!-- WO_95 content 24 2 -->
            <xsl:when test="replace($series, '_', ' ') eq tokenize(f:decode-uri($xip-path), '/')[1]">
                <xsl:variable name="csv-path">
                    <xsl:choose>
                        <xsl:when test="$substitute-key-ends-with-slash">
                            <xsl:value-of select="functx:replace-first(f:decode-uri($xip-path), replace($series, '_', ' '), concat($series, '/content'))"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat('/',functx:replace-first(f:decode-uri($xip-path), replace($series, '_', ' '), concat($series, '/content')))"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="encoded-csv-path" select="string-join(for $p in tokenize($csv-path, '/') return encode-for-uri($p), '/')"/>
                <xsl:value-of select="$encoded-csv-path"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="replace($series, '_', ' ')" />
                <xsl:message select="tokenize(f:decode-uri($xip-path), '/')[1]" />
                <xsl:message select="concat('Do not understand how to process path: ', $xip-path)" terminate="yes"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- TODO - check that this is correct!!! -->
    <xsl:function name="f:get-exemption-code-string">
        <xsl:param name="exemption-code" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$exemption-code eq '23'">section_23</xsl:when>
            <xsl:when test="$exemption-code eq '24'">section_24</xsl:when>
            <xsl:when test="$exemption-code eq '26'">section_26</xsl:when>
            <xsl:when test="$exemption-code eq '27(1)'">section_27_1</xsl:when>
            <xsl:when test="$exemption-code eq '27(2)'">section_27_2</xsl:when>
            <xsl:when test="$exemption-code eq '28'">section_28</xsl:when>
            <xsl:when test="$exemption-code eq '29'">section_29</xsl:when>
            <xsl:when test="$exemption-code eq '30(1)'">section_30_1</xsl:when>
            <xsl:when test="$exemption-code eq '30(2)'">section_30_2</xsl:when>
            <xsl:when test="$exemption-code eq '31'">section_31</xsl:when>
            <xsl:when test="$exemption-code eq '32'">section_32</xsl:when>
            <xsl:when test="$exemption-code eq '33'">section_33</xsl:when>
            <xsl:when test="$exemption-code eq '34'">section_34</xsl:when>
            <xsl:when test="$exemption-code eq '35(1)(a)'">section_35_1_a</xsl:when>
            <xsl:when test="$exemption-code eq '35(1)(b)'">section_35_1_b</xsl:when>
            <xsl:when test="$exemption-code eq '35(1)(c)'">section_35_1_c</xsl:when>
            <xsl:when test="$exemption-code eq '35(1)(d)'">section_35_1_d</xsl:when>
            <xsl:when test="$exemption-code eq '36'">section_36</xsl:when>
            <xsl:when test="$exemption-code eq '37(1)(a)'">section_37_1_a</xsl:when>
            <xsl:when test="$exemption-code eq '37(1)(a)old'">section_37_1_a_old</xsl:when>
            <xsl:when test="$exemption-code eq '37(1)(aa)'">section_37_1_aa</xsl:when>
            <xsl:when test="$exemption-code eq '37(1)(ac)'">section_37_1_ac</xsl:when>
            <xsl:when test="$exemption-code eq '37(1)(ad)'">section_37_1_ad</xsl:when>
            <xsl:when test="$exemption-code eq '37(1)(b)'">section_37_1_b</xsl:when>
            <xsl:when test="$exemption-code eq '38'">section_38</xsl:when>
            <xsl:when test="$exemption-code eq '39'">section_39</xsl:when>
            <xsl:when test="$exemption-code eq '40(2)'">section_40_2</xsl:when>
            <xsl:when test="$exemption-code eq '41'">section_41</xsl:when>
            <xsl:when test="$exemption-code eq '42'">section_42</xsl:when>
            <xsl:when test="$exemption-code eq '43'">section_43</xsl:when>
            <xsl:when test="$exemption-code eq '43(1)'">section_43_1</xsl:when>
            <xsl:when test="$exemption-code eq '43(2)'">section_43_2</xsl:when>
            <xsl:when test="$exemption-code eq '44'">section_44</xsl:when>
            <xsl:otherwise>
                <!-- code not recognised!! -->
                <xsl:message select="concat('FOI Exemption code not recognised: ''', $exemption-code, '''')" terminate="yes"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="functx:trim" as="xs:string">
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:sequence select="replace(replace($arg,'\s+$',''),'^\s+','')"/>
    </xsl:function>

    <xsl:function name="functx:replace-first" as="xs:string"
                  xmlns:functx="http://www.functx.com">
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:param name="pattern" as="xs:string"/>
        <xsl:param name="replacement" as="xs:string"/>
        <xsl:sequence select="replace($arg, concat('(^.*?)', $pattern),
             concat('$1',$replacement)) "/>
    </xsl:function>


    <xsl:function name="functx:max-determine-type" as="xs:anyAtomicType?"
                  xmlns:functx="http://www.functx.com">
        <xsl:param name="seq" as="xs:anyAtomicType*"/>

        <xsl:sequence select="
            if (every $value in $seq satisfies ($value castable as xs:double))
            then max(for $value in $seq return xs:double($value))
            else fn:error(fn:QName('Error', 'myerr:closure_period'), 'Cannot cast closure period value to double', $seq)
            "/>

    </xsl:function>


</xsl:stylesheet>