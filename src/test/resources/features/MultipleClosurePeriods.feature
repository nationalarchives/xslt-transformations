Feature: Multiple Closure Periods
  Multiple closure periods can be provided in the closure_period field. The maximum value is chosen

  Scenario: Collection sample TEST1Y19HS001/TEST_1 has a record with multiple closure periods, After creating closures the maximum period is chosen.
    Given the example collection of type born-digital for collection TEST1Y19HS001/TEST_1:
    And I have registered collection TEST1Y19HS001/TEST_1:
    And I perform transformation convert-csv-to-xml for collection TEST1Y19HS001/TEST_1:
    And I apply XSLT add-born-digital-metadata-to-sip_v2.2.xslt to metadata.xml in collection TEST1Y19HS001/TEST_1 to output meta1.xml with parameters:
      | metadata-csv-xml-path                     | ../metadata_TEST1Y19HS001.csv.xml   |
      | cs-part-schemas-uri                       | ../schemas.xml                      |
      | cs-series-uri                             | ../series.xml                         |
    And I apply XSLT modify-sip-metadata.xslt to meta1.xml in collection TEST1Y19HS001/TEST_1 to output restructuredMetadata.xml with parameters:
      | contentLocation                           | ../ |
    And I apply XSLT create-closure.xslt to restructuredMetadata.xml in collection TEST1Y19HS001/TEST_1 to output closures.xml with parameters:
      | closure-csv-xml-path                      | ../closure.csv.xml                 |
      | series                                    | TEST_1                             |
      | unit-id                                   | TEST1Y19HS001                      |
    Then I want to validate XML closures.xml for collection TEST1Y19HS001/TEST_1:
      | xpath                                     | value                                 |
      | //closure[uuid = '7587be3f-f6f3-4fe1-8481-4abdf8ca6cf7']/closurePeriod | 15       |
      | //closure[uuid = 'bfc5ee2d-a093-492e-a4ad-b1940191ad84']/closurePeriod | 32       |
