Feature: Workflow for sub item Digitised Surrogates
  Collections can have multiple transcriptions for a single image, such as many people on one census page
  Each transcription row (person) is a sub-item and should be stored as a DeliverableUnit
  The Preservica SIP generator will create a single DU for the image folder.
  New DUs must be generated for each sub-item and these DUs will each have a manifestation

  Scenario: Sub item digitised surrogates workflow
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
    And I transform with schematron XSLT digitised-surrogates-sub-items-xip-validation-v1.xslt to acc-modified.xml in collection ADM158Y17S001/ADM_158:
    And I perform schema validation using XIP-full-tna-customised.xsd on acc-modified.xml in collection ADM158Y17S001/ADM_158
    And I apply XSLT add-surrogate-catalogue-references.xslt to acc-modified.xml in collection ADM158Y17S001/ADM_158 to output cat-acc-ref.xml with parameters:
      | blank                     | ../ |
    And I apply XSLT create-closure.xslt to cat-acc-ref.xml in collection ADM158Y17S001/ADM_158 to output closure.xml with parameters:
      | closure-csv-xml-path                             | ../closure_v9.csv.xml                        |
      | transcription-metadata-csv-xml-path              | ../.*transcription_metadata.*xml             |
      | series                                           | ADM_158                                      |
      | unit-id                                          | ADM158Y17S001                                |


