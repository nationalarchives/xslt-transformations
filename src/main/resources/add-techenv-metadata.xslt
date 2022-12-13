<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="xs">

    <xsl:output method="xml" omit-xml-declaration="no" byte-order-mark="no" media-type="application/xml" version="1.0" indent="yes" encoding="UTF-8"/>

    <xsl:param name="tech-env-metadata">/home/dev/git/transformations/src/test/resources/mock_techenv.csv.xml</xsl:param>

    <xsl:variable name="identity-element">file_uuid</xsl:variable>

    <xsl:template match="/">
         <xsl:variable name="metadata-to-merge" select="document($tech-env-metadata)/root/row[1]/*"/>
        <xsl:element name="root">
            <xsl:apply-templates>
                <xsl:with-param name="tech-env-metadata" select="$metadata-to-merge"/>
            </xsl:apply-templates>
        </xsl:element>
    </xsl:template>


    <xsl:template match="row">
        <xsl:param name="tech-env-metadata"/>
        <xsl:element name="row">
            <xsl:copy-of select="node()"/>
            <xsl:if test="elem[@name = $identity-element]/text() ">
                <xsl:element name="techenv">
                    <xsl:copy-of select="$tech-env-metadata"/>
                </xsl:element>
            </xsl:if>
        </xsl:element>
    </xsl:template>


</xsl:stylesheet>