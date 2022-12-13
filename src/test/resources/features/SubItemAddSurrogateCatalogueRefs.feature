Feature: The catalogueReference will be composed of {department}/{series}/{piece}/{item}/{sub-item}
 The catalogueReference is created in the workflow using the add-surrogate-catalogue-references.xslt

  Scenario: Add surrogate catalogue references
    Given the example collection of type surrogate for collection ADM158Y17S001/ADM_158:
    And I have registered collection ADM158Y17S001/ADM_158:
    And I perform transformation convert-csv-to-xml for collection ADM158Y17S001/ADM_158:
    And I apply XSLT sub-item-generate-du-manifestations.xslt to metadata.xml in collection ADM158Y17S001/ADM_158 to output sub-du.xml with parameters:
      | transcription-matadata-file                      | transcription_metadata_v1_ADM158Y17S001.csv  |
      | transcription-metadata-csv-xml-path              | ../.*transcription_metadata.*xml             |
     And I apply XSLT sub-item-add-du-manifestations.xslt to metadata.xml in collection ADM158Y17S001/ADM_158 to output sip-with-sub.xml with parameters:
      | generated-sub-item-dus-manifestations-xml-path   | ../sub-du.xml                                |
    And I apply XSLT sub-item-add-transcription-to-techacq.xslt to .*tech_acq.*xml in collection ADM158Y17S001/ADM_158 to output file-metadata.xml with parameters:
      | contentLocation                                  | ../                                          |
      | transcription                                    | ../.*transcription_metadata.*xml             |
    And I apply XSLT add-du-metadata-to-sip-v2.xslt to sip-with-sub.xml in collection ADM158Y17S001/ADM_158 to output sub-sip-with-metadata.xml with parameters:
      | du-metadata-csv-xml-path                         | ../.*transcription_metadata.*xml             |
    And I apply XSLT add-file-metadata-to-sip-v2.xslt to sub-sip-with-metadata.xml in collection ADM158Y17S001/ADM_158 to output sip-with-all-metadata.xml with parameters:
      | file-matadata-csv-schema-name                    | tech_acq_metadata_v1_ADM158Y17S001.csv       |
      | file-metadata-csv-xml-path                       | ../file-metadata.xml                         |
    And I apply XSLT modify-sip-metadata-surrogates.xslt to sip-with-all-metadata.xml in collection ADM158Y17S001/ADM_158 to output modified.xml with parameters:
     | contentLocation            | ../ |
    And I apply XSLT add-paper-manifestations.xslt to modified.xml in collection ADM158Y17S001/ADM_158 to output acc-modified.xml with parameters:
      | blank                     | ../ |
    And I perform schema validation using XIP-full-tna-customised.xsd on acc-modified.xml in collection ADM158Y17S001/ADM_158
    And I apply XSLT add-surrogate-catalogue-references.xslt to acc-modified.xml in collection ADM158Y17S001/ADM_158 to output cat-acc-ref.xml with parameters:
      | blank                     | ../ |
    Then I want to validate XML cat-acc-ref.xml for collection ADM158Y17S001/ADM_158:
      | xpath                                                                             | value    |
      | //DeliverableUnit[CatalogueReference = 'ADM/158/193/1/3']//departmentIdentifier   | ADM      |
      | //DeliverableUnit[CatalogueReference = 'ADM/158/193/1/3']//seriesIdentifier       | 158      |
      | //DeliverableUnit[CatalogueReference = 'ADM/158/193/1/3']//pieceIdentifier        | 193      |
      | //DeliverableUnit[CatalogueReference = 'ADM/158/193/1/3']//itemIdentifier         | 1        |
      | //DeliverableUnit[CatalogueReference = 'ADM/158/193/1/3']//subItemIdentifier      | 3        |


