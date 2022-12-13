Feature: CJ_4 Is a redacted series that has end_date in the csv metadata
  It will use add-born-digital-metadata-to-sip_v2.2.xslt to add the metadata
  There is no start_date so the coverage startDate and endDate is csv end_date

  Scenario: Collection sample MUPT2Y17S001/MUPT_2 is a redacted series with only end_date in csv
    startDate and endDate are the csv end_date
    Given the example collection of type born-digital for collection MUPT2Y17S001/MUPT_2:
    And I have registered collection MUPT2Y17S001/MUPT_2:
    And csv fields in file .*metadata.*csv are updated in collection MUPT2Y17S001/MUPT_2:
       | rowId      | column                      | value                                      |
       | file1      | end_date                    | 1994-10-26T00:00:00                        |
    And I perform transformation convert-csv-to-xml for collection MUPT2Y17S001/MUPT_2:
    And I apply XSLT add-born-digital-metadata-to-sip_v2.2.xslt to metadata.xml in collection MUPT2Y17S001/MUPT_2 to output xip-with-metadata.xml with parameters:
      | metadata-csv-xml-path                     | ../metadata_v9_MUPT2Y17HS001.csv.xml        |
      | cs-part-schemas-uri                       | ../schemas.xml                              |
      | cs-series-uri                             | ../series.xml                               |
    Then I want to validate XML xip-with-metadata.xml for collection MUPT2Y17S001/MUPT_2:
      | xpath                                                             | value               |
      | //DeliverableUnit[Title = 'FOZZIE.pdf']//CoveringDates/startDate  | 1994-10-26T00:00:00 |
      | //DeliverableUnit[Title = 'FOZZIE.pdf']//CoveringDates/endDate    | 1994-10-26T00:00:00 |

  Scenario: Collection sample MUPT2Y17S001/MUPT_2 is a redacted series with start and end_date in csv
    startDate is the csv start_date and endDate is the csv end_date
    Given the example collection of type born-digital for collection MUPT2Y17S001/MUPT_2:
    And I have registered collection MUPT2Y17S001/MUPT_2:
    And csv fields in file .*metadata.*csv are updated in collection MUPT2Y17S001/MUPT_2:
      | rowId      | column                       | value                                        |
      | file1      | end_date                     | 1994-10-26T00:00:00                          |
      | file1      | start_date                   | 1980-10-26T00:00:00                          |
    And I perform transformation convert-csv-to-xml for collection MUPT2Y17S001/MUPT_2:
    And I apply XSLT add-born-digital-metadata-to-sip_v2.2.xslt to metadata.xml in collection MUPT2Y17S001/MUPT_2 to output xip-with-metadata.xml with parameters:
      | metadata-csv-xml-path                     | ../metadata_v9_MUPT2Y17HS001.csv.xml         |
      | cs-part-schemas-uri                       | ../schemas.xml                               |
      | cs-series-uri                             | ../series.xml                                |
    Then I want to validate XML xip-with-metadata.xml for collection MUPT2Y17S001/MUPT_2:
      | xpath                                     | value                                        |
      | //DeliverableUnit[Title = 'FOZZIE.pdf']//CoveringDates/startDate   | 1980-10-26T00:00:00 |
      | //DeliverableUnit[Title = 'FOZZIE.pdf']//CoveringDates/endDate     | 1994-10-26T00:00:00 |

  Scenario: Collection sample MUPT2Y17S001/MUPT_2 is a redacted series with no start and end_date in csv
    There will be no CoveringDates
    Given the example collection of type born-digital for collection MUPT2Y17S001/MUPT_2:
    And I have registered collection MUPT2Y17S001/MUPT_2:
    And I perform transformation convert-csv-to-xml for collection MUPT2Y17S001/MUPT_2:
    And I apply XSLT add-born-digital-metadata-to-sip_v2.2.xslt to metadata.xml in collection MUPT2Y17S001/MUPT_2 to output xip-with-metadata.xml with parameters:
      | metadata-csv-xml-path                     | ../metadata_v9_MUPT2Y17HS001.csv.xml         |
      | cs-part-schemas-uri                       | ../schemas.xml                               |
      | cs-series-uri                             | ../series.xml                                |
    Then I want to validate XML xip-with-metadata.xml for collection MUPT2Y17S001/MUPT_2:
      | xpath                                     | value                                        |
      | count(//DeliverableUnit[Title = 'FOZZIE.pdf']//CoveringDates)       |      0             |
