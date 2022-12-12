<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fntcm="http://tna.gov.uk/transform/functions/common/metadata"
    xmlns:functx="http://www.functx.com"
    version="2.0">

    <!-- checks a string value to see if it is meant to indicate true or false -->
    <xsl:function name="fntcm:is-true" as="xs:boolean">
        <xsl:param name="str" as="xs:string"/>
        <xsl:value-of select="lower-case($str) = ('y', 'yes', 'true', 't', '1')"/>
    </xsl:function>
    
    <!-- determines if a string value is a valid transcribedDateType (see tna/person.xsd) -->
    <xsl:function name="fntcm:is-transcribedDate" as="xs:boolean">
        <xsl:param name="str" as="xs:string"/>
        <xsl:value-of select="matches($str, '([0-3]?[0-9]/[0-1]?[0-9]/[0-9]{4})|([0-9]{4})|([0-1]?[0-9]/[0-9]{4})|([0-3]?[0-9]/\?{2}/[0-9]{4})|([0-3]?[0-9]/[0-1]?[0-9]/\?{4})|([0-3]?[0-9]/[0-1]?[0-9]/[0-9]{3}\?)|([0-3]?[0-9]/[0-1]?[0-9]/[0-9]{2}\?[0-9])|([0-3]?[0-9]/[0-1]?[0-9]/[0-9]{2}\?{2})')"/>
    </xsl:function>
    
    <!-- determines if a string value is a valid W3CDTF (xs:gYear xs:gYearMonth xs:date xs:dateTime) -->
    <xsl:function name="fntcm:is-w3cdtf" as="xs:boolean">
        <xsl:param name="str" as="xs:string"/>
        
        <xsl:choose>
            <xsl:when test="$str castable as xs:dateTime"><xsl:value-of select="true()"/></xsl:when>
            <xsl:when test="$str castable as xs:date"><xsl:value-of select="true()"/></xsl:when>
            <xsl:when test="$str castable as xs:gYearMonth"><xsl:value-of select="true()"/></xsl:when>
            <xsl:when test="$str castable as xs:gYear"><xsl:value-of select="true()"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="false()"/></xsl:otherwise>
        </xsl:choose>
    </xsl:function>


    <xsl:function name="fntcm:to-date-from-transcription">
        <xsl:param name="transcribed-day"/>
        <xsl:param name="transcribed-month"/>
        <xsl:param name="transcribed-year"/>
        <xsl:copy-of  select="concat($transcribed-year,'-',fntcm:month-to-index($transcribed-month), '-',$transcribed-day)"/>
     </xsl:function>

    <!--
     Valid derived date segments (day, month or year" will be used before transcribed values
    -->
    <xsl:function name="fntcm:to-date-from-transcription-derived">
        <xsl:param name="transcribedDay"/>
        <xsl:param name="transcribedMonth"/>
        <xsl:param name="transcribedYear"/>
        <xsl:param name="derivedDay"/>
        <xsl:param name="derivedMonth"/>
        <xsl:param name="derivedYear"/>

        <xsl:variable name="day">
            <xsl:choose>
                <xsl:when test="$derivedDay castable as xs:integer">
                    <xsl:value-of select="$derivedDay"/>
                </xsl:when>
                <xsl:otherwise >
                    <xsl:value-of select="$transcribedDay"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="month">
            <xsl:choose>
                <xsl:when test="fntcm:month-to-index($derivedMonth) castable as xs:integer">
                    <xsl:value-of select="$derivedMonth"/>
                </xsl:when>
                <xsl:otherwise >
                    <xsl:value-of select="$transcribedMonth"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="year">
            <xsl:choose>
                <xsl:when test="$derivedYear castable as xs:integer">
                    <xsl:value-of select="$derivedYear"/>
                </xsl:when>
                <xsl:otherwise >
                    <xsl:value-of select="$transcribedYear"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:copy-of  select="concat($year,'-',fntcm:month-to-index($month), '-',$day)"/>
    </xsl:function>





    <xsl:function name="fntcm:month-to-index">
        <xsl:param name="mo"/>
        <xsl:variable name="month">
            <xsl:choose>
                <xsl:when test="$mo = 'Jan'">01</xsl:when>
                <xsl:when test="$mo = 'January'">01</xsl:when>
                <xsl:when test="$mo = 'Feb'">02</xsl:when>
                <xsl:when test="$mo = 'February'">02</xsl:when>
                <xsl:when test="$mo = 'Mar'">03</xsl:when>
                <xsl:when test="$mo = 'March'">03</xsl:when>
                <xsl:when test="$mo = 'Apr'">04</xsl:when>
                <xsl:when test="$mo = 'April'">04</xsl:when>
                <xsl:when test="$mo = 'May'">05</xsl:when>
                <xsl:when test="$mo = 'Jun'">06</xsl:when>
                <xsl:when test="$mo = 'June'">06</xsl:when>
                <xsl:when test="$mo = 'Jul'">07</xsl:when>
                <xsl:when test="$mo = 'July'">07</xsl:when>
                <xsl:when test="$mo = 'Aug'">08</xsl:when>
                <xsl:when test="$mo = 'August'">08</xsl:when>
                <xsl:when test="$mo = 'Sept'">09</xsl:when>
                <xsl:when test="$mo = 'September'">09</xsl:when>
                <xsl:when test="$mo = 'Oct'">10</xsl:when>
                <xsl:when test="$mo = 'October'">10</xsl:when>
                <xsl:when test="$mo = 'Nov'">11</xsl:when>
                <xsl:when test="$mo = 'November'">11</xsl:when>
                <xsl:when test="$mo = 'Dec'">12</xsl:when>
                <xsl:when test="$mo = 'December'">12</xsl:when>
                <xsl:otherwise>
                   <xsl:copy-of select="$mo"/>
                </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
        <xsl:value-of select="$month"/>
    </xsl:function>
    
    <xsl:function name="fntcm:two-pad-zero">
        <xsl:param name="str" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="string-length($str) = 1"><xsl:value-of select="concat('0', $str)"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="$str"/></xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- attempts to format a date string as a W3CDTF string and returns its value, if it cannot format it the original string is returned-->
    <xsl:function name="fntcm:to-w3cdtf" as="xs:string">
        <xsl:param name="str" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="fntcm:is-w3cdtf($str)">
                <xsl:value-of select="$str"/>
            </xsl:when>
            
            <!-- match dd-mm-yyyy or d-mm-yyyy or dd-m-yyyy or d-m-yyyy -->
            <xsl:when test="matches($str, '((0?[1-9])|([1-2][0-9])|(3[0-1]))\-((0?[1-9])|(1[0-2]))\-([0-9]{4})')">
                <xsl:variable name="parts" select="tokenize($str, '-')"/>
                <xsl:value-of select="concat($parts[3], '-', fntcm:two-pad-zero($parts[2]), '-', fntcm:two-pad-zero($parts[1]))"/>
            </xsl:when>
            <!-- match dd/mm/yyyy or d/mm/yyyy or dd/m/yyyy or d/m/yyyy -->
            <xsl:when test="matches($str, '((0?[1-9])|([1-2][0-9])|(3[0-1]))/((0?[1-9])|(1[0-2]))/([0-9]{4})')">
                <xsl:variable name="parts" select="tokenize($str, '/')"/>
                <xsl:value-of select="concat($parts[3], '-', fntcm:two-pad-zero($parts[2]), '-', fntcm:two-pad-zero($parts[1]))"/>
            </xsl:when>
            
            <!-- match mm-yyyy or m-yyyy -->
            <xsl:when test="matches($str, '((0?[1-9])|(1[0-2]))\-([0-9]{4})')">
                <xsl:variable name="parts" select="tokenize($str, '-')"/>
                <xsl:value-of select="concat($parts[2], '-', fntcm:two-pad-zero($parts[1]))"/>
            </xsl:when>
            <!-- match mm/yyyy or m/yyyy  -->
            <xsl:when test="matches($str, '((0?[1-9])|(1[0-2]))/([0-9]{4})')">
                <xsl:variable name="parts" select="tokenize($str, '/')"/>
                <xsl:value-of select="concat($parts[2], '-', fntcm:two-pad-zero($parts[1]))"/>
            </xsl:when>
            
            <!-- match yyyy -->
            <xsl:when test="matches($str, '[0-9]{4}')">
                <xsl:value-of select="$str"/>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:value-of select="$str"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    <!-- based on FunctX -->
    <xsl:function name="fntcm:days-in-month" as="xs:integer?">
        <xsl:param name="month" as="xs:integer"/>
        <xsl:param name="year" as="xs:integer"/>
        <xsl:sequence select=" 
            if ($month = 2 and
            fntcm:is-leap-year($year))
            then 29
            else
            (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
            [$month]
            "/>
    </xsl:function>
    
    <!-- based on FunctX -->
    <xsl:function name="fntcm:is-leap-year" as="xs:boolean">
        <xsl:param name="year" as="xs:integer"/> 
        <xsl:sequence select="
            ($year mod 4 = 0 and
            $year mod 100 != 0) or
            $year mod 400 = 0
            "/>
    </xsl:function>

    <xsl:function name="fntcm:opening-date-to-dateTime" as="xs:dateTime">
        <xsl:param name="opening_date" as="xs:string"/>
        <xsl:choose>
             <xsl:when test="contains($opening_date,'/')">
                <xsl:variable name="parts" select="tokenize($opening_date, '/')"/>
                <xsl:variable name="year" select="$parts[3]"/>
                <xsl:variable name="month" select="$parts[2]"/>
                <xsl:variable name="day" select="$parts[1]"/>
                <xsl:variable name = "full_date" as="xs:date">
                    <xsl:value-of select="concat($year, '-', $month, '-', $day)"/>
                </xsl:variable>
                <xsl:value-of select="xs:dateTime(concat(xs:date($full_date),'T',xs:time('00:00:00')))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$opening_date"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


</xsl:stylesheet>