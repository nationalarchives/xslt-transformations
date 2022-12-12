<xsl:stylesheet xmlns="http://www.tessella.com/XIP/v4"
                xmlns:csf="http://catalogue/service/functions"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:tna="http://nationalarchives.gov.uk/metadata/tna#"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fntcm="http://tna.gov.uk/transform/functions/common/metadata"
                xmlns:tnatrans="http://nationalarchives.gov.uk/dri/transcription"
                exclude-result-prefixes="csf fntcm tnatrans"
                version="2.0">

    <xsl:import href="common-metadata-functions.xslt"/>
    <xsl:template name="create-transcription">
        <xsl:param name="csv-row" as="node()"/>
        <xsl:variable name="transcription-row" as="node()">
            <xsl:choose>
                <xsl:when test="boolean($csv-row/transcription)">
                    <xsl:copy-of select="$csv-row/transcription"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$csv-row"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <tna:transcription>
            <tnatrans:Transcription>
                <xsl:if test="$transcription-row/elem[@name eq 'official_number'] ne''">
                    <tnatrans:officialNumber rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'official_number']"/>
                    </tnatrans:officialNumber>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'other_official_number'] ne''">
                    <tnatrans:otherOfficialNumber rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'other_official_number']"/>
                    </tnatrans:otherOfficialNumber>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'surname'] ne''">
                    <tnatrans:surname rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'surname']"/>
                    </tnatrans:surname>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'surname_other'] ne''">
                    <tnatrans:surnameOther rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'surname_other']"/>
                    </tnatrans:surnameOther>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'forenames'] ne''">
                    <tnatrans:forenames rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'forenames']"/>
                    </tnatrans:forenames>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'forenames_other'] ne''">
                    <tnatrans:forenamesOther rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'forenames_other']"/>
                    </tnatrans:forenamesOther>
                </xsl:if>

                <xsl:variable name="day" select="normalize-space($transcription-row/elem[@name eq 'birth_date_day'])"/>
                <xsl:variable name="month" select="normalize-space($transcription-row/elem[@name eq 'birth_date_month'])"/>
                <xsl:variable name="year" select="normalize-space($transcription-row/elem[@name eq 'birth_date_year'])"/>
                <xsl:variable name="derivedDay" select="normalize-space($transcription-row/elem[@name eq 'derived_birth_date_day'])"/>
                <xsl:variable name="derivedMonth" select="normalize-space($transcription-row/elem[@name eq 'derived_birth_date_month'])"/>
                <xsl:variable name="derivedYear" select="normalize-space($transcription-row/elem[@name eq 'derived_birth_date_year'])"/>

                <xsl:variable name="birthDate" select="fntcm:to-date-from-transcription($day,$month,$year)"/>
                <xsl:variable name="derivedBirthDate" select="fntcm:to-date-from-transcription-derived($day,$month,$year, $derivedDay,$derivedMonth,$derivedYear)"/>
                <xsl:if test="$birthDate ne '' and $birthDate ne '--' and $derivedBirthDate ne ''">
                    <tnatrans:birthDate>
                        <xsl:choose>
                            <xsl:when test="fntcm:is-w3cdtf($birthDate)">
                                <tnatrans:date>
                                    <xsl:value-of select="$birthDate"/>
                                </tnatrans:date>
                            </xsl:when>
                            <xsl:when test="fntcm:is-w3cdtf($derivedBirthDate)">
                                <tnatrans:derivedDate>
                                    <xsl:value-of select="$derivedBirthDate"/>
                                </tnatrans:derivedDate>
                            </xsl:when>
                            <xsl:otherwise>
                                <tnatrans:transcribedDateString>
                                    <xsl:value-of select="$birthDate"/>
                                </tnatrans:transcribedDateString>
                            </xsl:otherwise>
                        </xsl:choose>
                    </tnatrans:birthDate>
                </xsl:if>

                <xsl:if test="$day ne ''">
                    <tnatrans:birthDateDay rdf:datatype="xs:string">
                        <xsl:value-of select="$day"/>
                    </tnatrans:birthDateDay>
                </xsl:if>
                <xsl:if test="$month ne ''">
                    <tnatrans:birthDateMonth rdf:datatype="xs:string">
                        <xsl:value-of select="$month"/>
                    </tnatrans:birthDateMonth>
                </xsl:if>
                <xsl:if test="$year ne ''">
                    <tnatrans:birthDateYear rdf:datatype="xs:string">
                        <xsl:value-of select="$year"/>
                    </tnatrans:birthDateYear>
                </xsl:if>
                <xsl:if test="$derivedDay ne ''">
                    <tnatrans:derivedBirthDateDay rdf:datatype="xs:string">
                        <xsl:value-of select="$derivedDay"/>
                    </tnatrans:derivedBirthDateDay>
                </xsl:if>
                <xsl:if test="$derivedMonth ne ''">
                    <tnatrans:derivedBirthDateMonth rdf:datatype="xs:string">
                        <xsl:value-of select="$derivedMonth"/>
                    </tnatrans:derivedBirthDateMonth>
                </xsl:if>
                <xsl:if test="$derivedYear ne ''">
                    <tnatrans:derivedBirthDateYear rdf:datatype="xs:string">
                        <xsl:value-of select="$derivedYear"/>
                    </tnatrans:derivedBirthDateYear>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'age_years'] ne''">
                    <tnatrans:ageYears rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'age_years']"/>
                    </tnatrans:ageYears>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'age_months'] ne''">
                    <tnatrans:ageMonths rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'age_months']"/>
                    </tnatrans:ageMonths>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'place_of_birth'] ne''">
                    <tnatrans:placeOfBirth rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'place_of_birth']"/>
                    </tnatrans:placeOfBirth>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'pob_parish'] ne''">
                    <tnatrans:placeOfBirthParish rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'pob_parish']"/>
                    </tnatrans:placeOfBirthParish>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'pob_town'] ne''">
                    <tnatrans:placeOfBirthTown rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'pob_town']"/>
                    </tnatrans:placeOfBirthTown>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'pob_county'] ne''">
                    <tnatrans:placeOfBirthCounty rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'pob_county']"/>
                    </tnatrans:placeOfBirthCounty>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'pob_country'] ne''">
                    <tnatrans:placeOfBirthCountry rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'pob_country']"/>
                    </tnatrans:placeOfBirthCountry>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'comments'] ne''">
                    <tnatrans:comments rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'comments']"/>
                    </tnatrans:comments>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'face'] ne''">
                    <tnatrans:face rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'face']"/>
                    </tnatrans:face>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'Type_of_seal'] ne''">
                    <tnatrans:typeOfSeal rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'Type_of_seal']"/>
                    </tnatrans:typeOfSeal>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'Seal_owner'] ne''">
                    <tnatrans:sealOwner rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'Seal_owner']"/>
                    </tnatrans:sealOwner>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'Date_of_original_seal'] ne''">
                    <tnatrans:dateOfOriginalSeal rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'Date_of_original_seal']"/>
                    </tnatrans:dateOfOriginalSeal>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'Colour_of_original_seal'] ne''">
                    <tnatrans:colourOfOriginalSeal rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'Colour_of_original_seal']"/>
                    </tnatrans:colourOfOriginalSeal>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'Dimensions'] ne''">
                    <tnatrans:dimensions rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'Dimensions']"/>
                    </tnatrans:dimensions>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'Physical_format'] ne''">
                    <tnatrans:physicalFormat rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'Physical_format']"/>
                    </tnatrans:physicalFormat>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'Additional_information'] ne''">
                    <tnatrans:additionalInformation rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'Additional_information']"/>
                    </tnatrans:additionalInformation>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'Related_material'] ne''">
                    <tnatrans:relatedMaterial rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'Related_material']"/>
                    </tnatrans:relatedMaterial>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'Paper_Number'] ne''">
                    <tnatrans:paperNumber rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'Paper_Number']"/>
                    </tnatrans:paperNumber>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'Poor_Law_Union_Number'] ne''">
                    <tnatrans:poorLawUnionNumber rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'Poor_Law_Union_Number']"/>
                    </tnatrans:poorLawUnionNumber>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'Counties'] ne''">
                    <tnatrans:counties rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'Counties']"/>
                    </tnatrans:counties>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'start_image_number'] ne''">
                    <tnatrans:startImageNumber rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'start_image_number']"/>
                    </tnatrans:startImageNumber>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'end_image_number'] ne''">
                    <tnatrans:endImageNumber rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'end_image_number']"/>
                    </tnatrans:endImageNumber>
                </xsl:if>
                <xsl:if test="$transcription-row/elem[@name eq 'division_description'] ne''">
                    <tnatrans:divisionDescription rdf:datatype="xs:string">
                        <xsl:value-of select="$transcription-row/elem[@name eq 'division_description']"/>
                    </tnatrans:divisionDescription>
                </xsl:if>
            </tnatrans:Transcription>
        </tna:transcription>
    </xsl:template>

</xsl:stylesheet>