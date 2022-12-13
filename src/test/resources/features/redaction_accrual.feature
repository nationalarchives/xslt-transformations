Feature: Redaction accruals.
  When ingesting redaction accruals a SIP has been generated with the redaction as standard DU and file manifestation.
  The manifestation needs to be changed to a manifestation type 100 (redaction) and its manifestation rel ref to a value
  of the number of files for the DU.
  The DU in the XIP needs to be that of the DU to which the redaction is accrued and its metadata to be updated to show it
  has another redacted file
  The updates need to be done at different stages of the workflow, manifestation type first so other manifestation XSLTs will run correctly
  The DU has to be left till later as many of the ingest steps rely on a complete folder structure in the ingest and this in not present
  for the existing DU parent
  The updated existing DU data will have been created in the accrual-data.xml

  Scenario: A redaction accrual workflow is run and the redaction-accrual-manifestation.xslt updates the manifestation but not the XIP DU
    Given the example collection of type born-digital for collection MOCKY22HB001/MOCK_1:
    And I perform transformation convert-csv-to-xml for collection MOCKY22HB001/MOCK_1:
    And I apply XSLT retained-generate-du.xslt to metadata.xml in collection MOCKY22HB001/MOCK_1 to output retained-du-xml with parameters:
      | closure-csv-xml-path  | ../.*closure.*xml                |
      | metadata-csv-xml-path | ../metadata_LEV2Y22HB001.csv.xml |
    When I apply XSLT add-born-digital-metadata-to-sip_v2.2.xslt to retained-du-xml in collection MOCKY22HB001/MOCK_1 to output merged-metadata.xml with parameters:
      | metadata-csv-xml-path | ../metadata_MOCK1Y22HB001.csv.xml |
      | cs-part-schemas-uri   | ../schemas.xml                    |
      | cs-series-uri         | ../series.xml                     |
    Then I want to validate XML merged-metadata.xml for collection MOCKY22HB001/MOCK_1:
      | xpath                                                                                               | value                                |
      | //DeliverableUnit//parentDriRef                                                                     | MOCK 123/C/Z                         |
      | //DeliverableUnit[//parentDriRef/text() = 'MOCK 123/C/Z']/DeliverableUnitRef                        | 37ffd749-2d67-4988-8e18-7ae692d6fb48 |
      | count(//DeliverableUnit[DeliverableUnitRef = 'dd429fc3-d22a-48b4-ba45-c7eaa49c8e9a']//parentDriRef) | 0                                    |
    And I apply XSLT redaction-accrual-manifestation.xslt to merged-metadata.xml in collection MOCKY22HB001/MOCK_1 to output accrual-manifestation.xml with parameters:
      | accrual-data-xml-path | ../accrual-data.xml |
    Then I want to validate XML accrual-manifestation.xml for collection MOCKY22HB001/MOCK_1:
      | xpath                                                                                                 | value         |
      | //DeliverableUnit[DeliverableUnitRef = 'df9cbb9c-d83e-4a79-b26f-dbc151a26f38']//parentDriRef          | MOCK 123/C/Z  |
      | count(//DeliverableUnit[DeliverableUnitRef = 'df9cbb9c-d83e-4a79-b26f-dbc151a26f38']//parentDriRef)   | 1             |
      | count(//DeliverableUnit[DeliverableUnitRef = 'dd429fc3-d22a-48b4-ba45-c7eaa49c8e9a']//parentDriRef)   | 0             |
      | //Manifestation[DeliverableUnitRef = 'df9cbb9c-d83e-4a79-b26f-dbc151a26f38']/ManifestationRelRef      | 3             |
      | count(//Manifestation[DeliverableUnitRef = 'df9cbb9c-d83e-4a79-b26f-dbc151a26f38']/ManifestationFile) | 1             |
   And I perform schema validation using XIP-full-tna-customised.xsd on accrual-manifestation.xml in collection MOCKY22HB001/MOCK_1

  Scenario: A redaction accrual workflow is run and the redaction-accrual-du.xslt updates the XIP DU to be that of the original
    and updates the manifestion deliverableUnitRef to point to the existing DU
    dd429fc3-d22a-48b4-ba45-c7eaa49c8e9a is the DU ref generated in the XIP for the redaction
    df9cbb9c-d83e-4a79-b26f-dbc151a26f38 is the DU ref for the existing record
    DU details will be taken from the accrual-data-xml
    Given the example collection of type born-digital for collection MOCKY22HB001/MOCK_1:
    And I perform transformation convert-csv-to-xml for collection MOCKY22HB001/MOCK_1:
    And I apply XSLT retained-generate-du.xslt to metadata.xml in collection MOCKY22HB001/MOCK_1 to output retained-du-xml with parameters:
      | closure-csv-xml-path  | ../.*closure.*xml                |
      | metadata-csv-xml-path | ../metadata_LEV2Y22HB001.csv.xml |
    When I apply XSLT add-born-digital-metadata-to-sip_v2.2.xslt to retained-du-xml in collection MOCKY22HB001/MOCK_1 to output merged-metadata.xml with parameters:
      | metadata-csv-xml-path | ../metadata_MOCK1Y22HB001.csv.xml |
      | cs-part-schemas-uri   | ../schemas.xml                    |
      | cs-series-uri         | ../series.xml                     |
    And I apply XSLT redaction-accrual-manifestation.xslt to merged-metadata.xml in collection MOCKY22HB001/MOCK_1 to output accrual-manifestation.xml with parameters:
      | accrual-data-xml-path | ../accrual-data.xml |
    Then I want to validate XML accrual-manifestation.xml for collection MOCKY22HB001/MOCK_1:
      | xpath                                                                                                 | value         |
      | //DeliverableUnit[DeliverableUnitRef = 'df9cbb9c-d83e-4a79-b26f-dbc151a26f38']//parentDriRef          | MOCK 123/C/Z  |
      | count(//DeliverableUnit[DeliverableUnitRef = 'df9cbb9c-d83e-4a79-b26f-dbc151a26f38']//parentDriRef)   | 1             |
      | count(//DeliverableUnit[DeliverableUnitRef = 'dd429fc3-d22a-48b4-ba45-c7eaa49c8e9a']//parentDriRef)   | 0             |
      | //Manifestation[DeliverableUnitRef = 'df9cbb9c-d83e-4a79-b26f-dbc151a26f38']/ManifestationRelRef      | 3             |
      | count(//Manifestation[DeliverableUnitRef = 'df9cbb9c-d83e-4a79-b26f-dbc151a26f38']/ManifestationFile) | 1             |
    And I apply XSLT redaction-accrual-du.xslt to accrual-manifestation.xml in collection MOCKY22HB001/MOCK_1 to output hacked.xml with parameters:
      | accrual-data-xml-path | ../accrual-data.xml |
    Then I want to validate XML hacked.xml for collection MOCKY22HB001/MOCK_1:
      | xpath                                                                                                 | value         |
      | count(//DeliverableUnit[DeliverableUnitRef = 'dd429fc3-d22a-48b4-ba45-c7eaa49c8e9a'])                 | 1             |
      | count(//DeliverableUnit[DeliverableUnitRef = 'df9cbb9c-d83e-4a79-b26f-dbc151a26f38'])                 | 0             |
      | //Manifestation[DeliverableUnitRef = 'dd429fc3-d22a-48b4-ba45-c7eaa49c8e9a']/ManifestationRelRef      | 3             |
      | count(//Manifestation[DeliverableUnitRef = 'dd429fc3-d22a-48b4-ba45-c7eaa49c8e9a']/ManifestationFile) | 1             |
      | count(//DeliverableUnit[DeliverableUnitRef = 'dd429fc3-d22a-48b4-ba45-c7eaa49c8e9a']//hasRedactedFile)| 1             |
    And I perform schema validation using XIP-full-tna-customised.xsd on hacked.xml in collection MOCKY22HB001/MOCK_1



