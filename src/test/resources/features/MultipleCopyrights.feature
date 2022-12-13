Feature: Multiple Copyrights
  Multiple copyrights are available ided in the closure_period field. The maximum value is chosen

  Scenario: Collection sample TEST1Y19HS001/TEST_1 has multiple closure periods.
    After creating closures the maximum period is chosen.
    Given the example collection of type born-digital for collection TEST1Y19HS001/TEST_1:
    And I have registered collection TEST1Y19HS001/TEST_1:
    And I perform transformation convert-csv-to-xml for collection TEST1Y19HS001/TEST_1:
    And I apply XSLT add-born-digital-metadata-to-sip_v2.2.xslt to metadata.xml in collection TEST1Y19HS001/TEST_1 to output meta1.xml with parameters:
      | metadata-csv-xml-path                     | ../metadata_TEST1Y19HS001.csv.xml     |
      | cs-part-schemas-uri                       | ../schemas.xml                        |
      | cs-series-uri                             | ../series.xml                         |
    Then I want to validate XML meta1.xml for collection TEST1Y19HS001/TEST_1:
      | xpath                                                                                                         | value                                 |
      |count(//DeliverableUnit[DeliverableUnitRef='290edeaa-2e46-4d3c-bb66-92fb69f5ad2b']//rights)                    | 4                                     |
      |count(//DeliverableUnit[DeliverableUnitRef='3c828d01-d16b-4050-8075-a72c85c56595']//rights)                    | 2                                     |
    And I perform schema validation using XIP-full-tna-customised.xsd on meta1.xml in collection TEST1Y19HS001/TEST_1
