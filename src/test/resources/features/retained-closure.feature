Feature: Retained record deliverable unit (DU) generation
  Departments are able to transfer born digital collections to TNA and retain
  files associated with the collection. The transfer will include the csvs for closure
  and metadata that include information about the retained files.
  The SIP generator will create a Preservica XIP that includes DUs for all physical files
  but knows nothing about retained records.
  New DeliverableUnit/Manifestation/File elements are created and added to the XIP for each
  retained file, once added closures can be created
  row_id for tests
  ret_4971.doc
  ret_3242.doc
  ret_8285.doc
  ret_2229.doc
  ret_2230.doc

  Scenario: Once DUs are created for retained records closure information can
  be created from the closure csv file.
  The sample collection contains 2 temporarily_retained record (will covert to closure type T)
  For each file there will also be a matching deliverable unit closure
  The closure should have retention information
    Given the example collection of type born-digital for collection FCO37Y21HB010/FCO_37:
#   The csv values can be updated to allow check for specific combinations
#    And csv fields in file .*closure.*csv are updated in collection FCO37Y21HB010/FCO_37:
#      | rowId        | column                                   | value                              |
#      | ret_2230.doc | retention_type                           | retained_under_3.4                 |
#      | ret_2230.doc | retention_reconsider_date                | 1999-121-22T23:00:00               |
#      | ret_2230.doc | RI_number                                | 106                                |
#      | ret_2230.doc | RI_signed_date                           | 1999-121-22T23:00:00               |
#      | ret_2230.doc | retention_justification                  | 6                                  |
    And I perform transformation convert-csv-to-xml for collection FCO37Y21HB010/FCO_37:
    And I apply XSLT retained-generate-du.xslt to metadata.xml in collection FCO37Y21HB010/FCO_37 to output retained-du-xml with parameters:
      | closure-csv-xml-path                                     | ../.*closure.*xml                     |
      | metadata-csv-xml-path                                    | ../metadata_v43_FCO37Y21HB002.csv.xml |
    When I apply XSLT add-born-digital-metadata-to-sip_v2.2.xslt to retained-du-xml in collection FCO37Y21HB010/FCO_37 to output merged-metadata.xml with parameters:
      | metadata-csv-xml-path                     | ../metadata_v43_FCO37Y21HB002.csv.xml |
      | cs-part-schemas-uri                       | ../schemas.xml                        |
      | cs-series-uri                             | ../series.xml                         |
    And I apply XSLT modify-sip-metadata.xslt to merged-metadata.xml in collection FCO37Y21HB010/FCO_37 to output restructuredMetadata.xml with parameters:
      | contentLocation            | ../ |
    And I apply XSLT create-closure.xslt to restructuredMetadata.xml in collection FCO37Y21HB010/FCO_37 to output closures.xml with parameters:
      | closure-csv-xml-path                      | ../closure.csv.xml                 |
      | series                                    | FCO_37                             |
      | unit-id                                   | FCO37Y21HB010                      |
    #  two temporarily_retained records  closure type T
    #  no retentionReconsiderDate
    #  no RINumber
    Then I want to validate XML closures.xml for collection FCO37Y21HB010/FCO_37:
      | xpath                                                                                | value    |
      | //closures/closure[closureType = 'T'][1]/retentionJustification                      | 2        |
      | count(//closures/closure[closureType = 'T'])                                         | 4        |
      | count(//closures/closure[closureType = 'T' and @resourceType = 'DeliverableUnit'])   | 2        |
      | count(//closures/closure[closureType = 'T' and @resourceType = 'File'])              | 2        |
      | count(//closures/closure[closureType = 'T'][1]/retentionReconsiderDate)              | 0        |
      | count(//closures/closure[closureType = 'T'][1]/RINumber)                             | 0        |

     #  three retained under retained_under_3.4 so closure type S
     #  RI_number 106
     #  have retention_reconsider_date
     #  1 file has a RISignedDate
    Then I want to validate XML closures.xml for collection FCO37Y21HB010/FCO_37:
      | xpath                                                                                | value    |
      | //closures/closure[closureType = 'S'][1]/retentionJustification                      | 6        |
      | count(//closures/closure[closureType = 'S'])                                         | 6        |
      | count(//closures/closure[closureType = 'S' and @resourceType = 'DeliverableUnit'])   | 3        |
      | count(//closures/closure[closureType = 'S' and @resourceType = 'File'])              | 3        |
      | //closures/closure[closureType = 'S'][1]/retentionReconsiderDate                     | 2031-12-31T00:00:00  |
      | //closures/closure[closureType = 'S'][1]/RINumber                                    | 106      |
      | count(//closures/closure[closureType = 'S'])                                         | 6        |
      | //closures/closure[closureType = 'S']/RISignedDate[not(. = '')][1]                   | 2031-12-21T00:00:00  |


  Scenario: A retention justification value is invalid, the transformation should produce error
    Given the example collection of type born-digital for collection FCO37Y21HB010/FCO_37:
    And csv fields in file .*closure.*csv are updated in collection FCO37Y21HB010/FCO_37:
      | rowId        | column                                   | value                              |
      | ret_2230.doc | retention_justification                  | 9                                  |
    And I perform transformation convert-csv-to-xml for collection FCO37Y21HB010/FCO_37:
    And I apply XSLT retained-generate-du.xslt to metadata.xml in collection FCO37Y21HB010/FCO_37 to output retained-du-xml with parameters:
      | closure-csv-xml-path                                     | ../.*closure.*xml                     |
      | metadata-csv-xml-path                                    | ../metadata_v43_FCO37Y21HB002.csv.xml |
    When I apply XSLT add-born-digital-metadata-to-sip_v2.2.xslt to retained-du-xml in collection FCO37Y21HB010/FCO_37 to output merged-metadata.xml with parameters:
      | metadata-csv-xml-path                     | ../metadata_v43_FCO37Y21HB002.csv.xml |
      | cs-part-schemas-uri                       | ../schemas.xml                        |
      | cs-series-uri                             | ../series.xml                         |
    And I apply XSLT modify-sip-metadata.xslt to merged-metadata.xml in collection FCO37Y21HB010/FCO_37 to output restructuredMetadata.xml with parameters:
      | contentLocation            | ../ |
    And I expect error 'Unknown retention_justification value: 9 for file:/FCO_37/content/FS/92/B/014/2230.doc' on applying XSLT create-closure.xslt to restructuredMetadata.xml in collection FCO37Y21HB010/FCO_37 to output closures.xml with parameters:
      | closure-csv-xml-path                      | ../closure.csv.xml                 |
      | series                                    | FCO_37                             |
      | unit-id                                   | FCO37Y21HB010                      |

  Scenario: A retention justification value should not be empty if retention_type is not empty
    Given the example collection of type born-digital for collection FCO37Y21HB010/FCO_37:
    And csv fields in file .*closure.*csv are updated in collection FCO37Y21HB010/FCO_37:
      | rowId        | column                                   | value                              |
      | ret_2230.doc | retention_justification                  |                                    |
    And I perform transformation convert-csv-to-xml for collection FCO37Y21HB010/FCO_37:
    And I apply XSLT retained-generate-du.xslt to metadata.xml in collection FCO37Y21HB010/FCO_37 to output retained-du-xml with parameters:
      | closure-csv-xml-path                                     | ../.*closure.*xml                     |
      | metadata-csv-xml-path                                    | ../metadata_v43_FCO37Y21HB002.csv.xml |
    When I apply XSLT add-born-digital-metadata-to-sip_v2.2.xslt to retained-du-xml in collection FCO37Y21HB010/FCO_37 to output merged-metadata.xml with parameters:
      | metadata-csv-xml-path                     | ../metadata_v43_FCO37Y21HB002.csv.xml |
      | cs-part-schemas-uri                       | ../schemas.xml                        |
      | cs-series-uri                             | ../series.xml                         |
    And I apply XSLT modify-sip-metadata.xslt to merged-metadata.xml in collection FCO37Y21HB010/FCO_37 to output restructuredMetadata.xml with parameters:
      | contentLocation            | ../ |
    And I expect error 'retention_justification cannot be empty when retention_type is: temporarily_retained for file:/FCO_37/content/FS/92/B/014/2230.doc' on applying XSLT create-closure.xslt to restructuredMetadata.xml in collection FCO37Y21HB010/FCO_37 to output closures.xml with parameters:
      | closure-csv-xml-path                      | ../closure.csv.xml                 |
      | series                                    | FCO_37                             |
      | unit-id                                   | FCO37Y21HB010                      |

  Scenario: RI number field should only have numeric values
    Given the example collection of type born-digital for collection FCO37Y21HB010/FCO_37:
    And csv fields in file .*closure.*csv are updated in collection FCO37Y21HB010/FCO_37:
      | rowId        | column                                   | value                              |
      | ret_2230.doc | RI_number                                | A12                                |
    And I perform transformation convert-csv-to-xml for collection FCO37Y21HB010/FCO_37:
    And I apply XSLT retained-generate-du.xslt to metadata.xml in collection FCO37Y21HB010/FCO_37 to output retained-du-xml with parameters:
      | closure-csv-xml-path                                     | ../.*closure.*xml                     |
      | metadata-csv-xml-path                                    | ../metadata_v43_FCO37Y21HB002.csv.xml |
    When I apply XSLT add-born-digital-metadata-to-sip_v2.2.xslt to retained-du-xml in collection FCO37Y21HB010/FCO_37 to output merged-metadata.xml with parameters:
      | metadata-csv-xml-path                     | ../metadata_v43_FCO37Y21HB002.csv.xml |
      | cs-part-schemas-uri                       | ../schemas.xml                        |
      | cs-series-uri                             | ../series.xml                         |
    And I apply XSLT modify-sip-metadata.xslt to merged-metadata.xml in collection FCO37Y21HB010/FCO_37 to output restructuredMetadata.xml with parameters:
      | contentLocation            | ../ |
    And I expect error 'RI_Number format invalid : A12 for file:/FCO_37/content/FS/92/B/014/2230.doc' on applying XSLT create-closure.xslt to restructuredMetadata.xml in collection FCO37Y21HB010/FCO_37 to output closures.xml with parameters:
      | closure-csv-xml-path                      | ../closure.csv.xml                 |
      | series                                    | FCO_37                             |
      | unit-id                                   | FCO37Y21HB010                      |

  Scenario: RI number field should only have numeric values
    Given the example collection of type born-digital for collection FCO37Y21HB010/FCO_37:
    And csv fields in file .*closure.*csv are updated in collection FCO37Y21HB010/FCO_37:
      | rowId        | column                                   | value                              |
      | ret_2230.doc | RI_signed_date                           | 2012                               |
    And I perform transformation convert-csv-to-xml for collection FCO37Y21HB010/FCO_37:
    And I apply XSLT retained-generate-du.xslt to metadata.xml in collection FCO37Y21HB010/FCO_37 to output retained-du-xml with parameters:
      | closure-csv-xml-path                                     | ../.*closure.*xml                     |
      | metadata-csv-xml-path                                    | ../metadata_v43_FCO37Y21HB002.csv.xml |
    When I apply XSLT add-born-digital-metadata-to-sip_v2.2.xslt to retained-du-xml in collection FCO37Y21HB010/FCO_37 to output merged-metadata.xml with parameters:
      | metadata-csv-xml-path                     | ../metadata_v43_FCO37Y21HB002.csv.xml |
      | cs-part-schemas-uri                       | ../schemas.xml                        |
      | cs-series-uri                             | ../series.xml                         |
    And I apply XSLT modify-sip-metadata.xslt to merged-metadata.xml in collection FCO37Y21HB010/FCO_37 to output restructuredMetadata.xml with parameters:
      | contentLocation            | ../ |
    And I expect error 'RI_signed_date is not in format YYYY-MM-DDTHH:mm:ss for file:/FCO_37/content/FS/92/B/014/2230.doc' on applying XSLT create-closure.xslt to restructuredMetadata.xml in collection FCO37Y21HB010/FCO_37 to output closures.xml with parameters:
      | closure-csv-xml-path                      | ../closure.csv.xml                 |
      | series                                    | FCO_37                             |
      | unit-id                                   | FCO37Y21HB010                      |

  Scenario: retention reconsider date when provided should be in a valid datetime format
    Given the example collection of type born-digital for collection FCO37Y21HB010/FCO_37:
    And csv fields in file .*closure.*csv are updated in collection FCO37Y21HB010/FCO_37:
      | rowId        | column                                   | value                              |
      | ret_8285.doc | retention_reconsider_date                | 2012                               |
    And I perform transformation convert-csv-to-xml for collection FCO37Y21HB010/FCO_37:
    And I apply XSLT retained-generate-du.xslt to metadata.xml in collection FCO37Y21HB010/FCO_37 to output retained-du-xml with parameters:
      | closure-csv-xml-path                                     | ../.*closure.*xml                     |
      | metadata-csv-xml-path                                    | ../metadata_v43_FCO37Y21HB002.csv.xml |
    When I apply XSLT add-born-digital-metadata-to-sip_v2.2.xslt to retained-du-xml in collection FCO37Y21HB010/FCO_37 to output merged-metadata.xml with parameters:
      | metadata-csv-xml-path                     | ../metadata_v43_FCO37Y21HB002.csv.xml |
      | cs-part-schemas-uri                       | ../schemas.xml                        |
      | cs-series-uri                             | ../series.xml                         |
    And I apply XSLT modify-sip-metadata.xslt to merged-metadata.xml in collection FCO37Y21HB010/FCO_37 to output restructuredMetadata.xml with parameters:
      | contentLocation            | ../ |
    And I expect error 'retention_reconsider_date is not in format YYYY-MM-DDTHH:mm:ss for file:/FCO_37/content/FS/92/A/014/8285.doc' on applying XSLT create-closure.xslt to restructuredMetadata.xml in collection FCO37Y21HB010/FCO_37 to output closures.xml with parameters:
      | closure-csv-xml-path                      | ../closure.csv.xml                 |
      | series                                    | FCO_37                             |
      | unit-id                                   | FCO37Y21HB010                      |

  Scenario: If retention_justification has a value of 6, ri_number cannot be blank
    Given the example collection of type born-digital for collection FCO37Y21HB010/FCO_37:
    And csv fields in file .*closure.*csv are updated in collection FCO37Y21HB010/FCO_37:
      | rowId        | column                                   | value                              |
      | ret_2230.doc | retention_justification                  | 6                                  |
    And I perform transformation convert-csv-to-xml for collection FCO37Y21HB010/FCO_37:
    And I apply XSLT retained-generate-du.xslt to metadata.xml in collection FCO37Y21HB010/FCO_37 to output retained-du-xml with parameters:
      | closure-csv-xml-path                                     | ../.*closure.*xml                     |
      | metadata-csv-xml-path                                    | ../metadata_v43_FCO37Y21HB002.csv.xml |
    When I apply XSLT add-born-digital-metadata-to-sip_v2.2.xslt to retained-du-xml in collection FCO37Y21HB010/FCO_37 to output merged-metadata.xml with parameters:
      | metadata-csv-xml-path                     | ../metadata_v43_FCO37Y21HB002.csv.xml |
      | cs-part-schemas-uri                       | ../schemas.xml                        |
      | cs-series-uri                             | ../series.xml                         |
    And I apply XSLT modify-sip-metadata.xslt to merged-metadata.xml in collection FCO37Y21HB010/FCO_37 to output restructuredMetadata.xml with parameters:
      | contentLocation            | ../ |
    And I expect error 'RI_number cannot be empty for file:/FCO_37/content/FS/92/B/014/2230.doc' on applying XSLT create-closure.xslt to restructuredMetadata.xml in collection FCO37Y21HB010/FCO_37 to output closures.xml with parameters:
      | closure-csv-xml-path                      | ../closure.csv.xml                 |
      | series                                    | FCO_37                             |
      | unit-id                                   | FCO37Y21HB010                      |
