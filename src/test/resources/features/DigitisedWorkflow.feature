Feature: Digitised workflow
  Digitised collections have four metadata files: closure, tech-acq, transcription and tech env.
  These csv files are converted to xml.
  The transcription is merged to the tech-acq and then the tech env is merged
  <row>
    <... tech_acq eleemts>
    <transcription>
      <... transcription elements>
    </transcription>
    <techenv>
      <..techenv elements>
  This file is then merged to sip metadata.xml

  Scenario: Digitised workflow
    Given the example collection of type digitised for collection DD1S001/DDD_1:
    And I have registered collection DD1S001/DDD_1:
    And I perform transformation convert-csv-to-xml for collection DD1S001/DDD_1:
    And I apply XSLT merge-transcription.xslt to tech_acq_metadata_v2_DD1S001.csv.xml in collection DD1S001/DDD_1 to output mergeTrans.xml with parameters:
      | transcription                                    | ../.*transcription_metadata.*xml        |
    And I apply XSLT add-techenv-metadata.xslt to mergeTrans.xml in collection DD1S001/DDD_1 to output mergeTransEnv.xml with parameters:
      | tech-env-metadata                                | ../.*tech_env_metadata.*xml             |
    And I apply XSLT add-digitised-record-metadata-to-sip-v2.xslt to metadata.xml in collection DD1S001/DDD_1 to output merged.xml with parameters:
      | metadata-csv-xml-path                            | ../.*mergeTransEnv.xml                  |
      | tech-acq-matadata-file                           | tech_acq_metadata_v2_DD1S001.csv        |
    And I apply XSLT modify-sip-metadata-surrogates.xslt to merged.xml in collection DD1S001/DDD_1 to output restructuredMetadata.xml with parameters:
     | contentLocation            | ../ |
#    And I transform with schematron XSLT digitised-xip-validation-v1.xslt to restructuredMetadata.xml in collection DD1S001/DDD_1:
    And I apply XSLT add-surrogate-catalogue-references.xslt to restructuredMetadata in collection DD1S001/DDD_1 to output cat-acc-ref.xml with parameters:
      | blank                     | ../ |
#    And I perform schema validation using XIP-full-tna-customised.xsd on cat-acc-ref.xml in collection DD1S001/DDD_1

