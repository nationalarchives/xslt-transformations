Feature: Workflow for sub item Digitised Surrogates
  Add paper manifestions - add empty manifestions for non sub-item du
  In the sample data collection ADM158Y17S001/ADM_158 there are
  four non-metadata dus ADM_158 ADM_158/193 ADM_158/193/1 ADM_158/193/2 + sub-items (30)


  Scenario: Add paper manifestations only to non-meta data du's that are not sub-items. After transformation
    there should be four extra manifestations. Also validate with schematron
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
    Then I want to validate XML modified.xml for collection ADM158Y17S001/ADM_158:
      | xpath                                   | value   |
      | count(//DeliverableUnit)                | 46      |
      | count(//Manifestation)                  | 46      |
    And I apply XSLT add-paper-manifestations.xslt to modified.xml in collection ADM158Y17S001/ADM_158 to output acc-modified.xml with parameters:
      | blank                     | ../ |
    And I want to validate XML acc-modified.xml for collection ADM158Y17S001/ADM_158:
      | xpath                                   | value   |
      | count(//DeliverableUnit)                | 46      |
      | count(//Manifestation)                  | 50      |
    Then I transform with schematron XSLT digitised-surrogates-sub-items-xip-validation-v1.xslt to acc-modified.xml in collection ADM158Y17S001/ADM_158:


  Scenario: Paper manifestations for all sub-item deliverable units should have Originality of false and ManifestationRelRef of 2
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
    And I want to validate XML modified.xml for collection ADM158Y17S001/ADM_158:
      | xpath                                   | value   |
      | count(//DeliverableUnit)                | 46      |
      | count(//Manifestation)                  | 46      |
      | count(//DeliverableUnits/Manifestation/ManifestationRelRef[text() = 1])   | 46     |
    And I apply XSLT add-paper-manifestations.xslt to modified.xml in collection ADM158Y17S001/ADM_158 to output acc-modified.xml with parameters:
      | blank                     | ../ |
    Then I transform with schematron XSLT digitised-surrogates-sub-items-xip-validation-v1.xslt to acc-modified.xml in collection ADM158Y17S001/ADM_158:
    And I want to validate XML acc-modified.xml for collection ADM158Y17S001/ADM_158:
      | xpath                                   | value   |
      | count(//DeliverableUnits/Manifestation/ManifestationRelRef[text() = 2])   | 34      |
      | count(//DeliverableUnits/Manifestation/ManifestationRelRef[text() = 1])   | 16      |
      | count(//Manifestation)                  | 50      |


