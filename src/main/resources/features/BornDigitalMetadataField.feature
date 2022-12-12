Feature: Born digital metadata fields
  Born digital collections have metadata in the XXXmetadata.csv
  These fields must be in the merged metadata.xml

  Scenario: Metadata fields maintained in the xml
    Given the example collection of type born-digital for collection TEST1Y19HS001/TEST_1:
    And csv fields in file .*metadata.*csv are updated in collection TEST1Y19HS001/TEST_1:
      | rowId      | column                                | value                               |
      | d1f1       | description                           | test file 1                         |
      | d1f1       | case_summary_1_judgment               | case summary 1 judgment             |
      | d1f1       | case_summary_1_reasons_for_judgment   | case summary 1 reasons for judgment |
      | d1f1       | case_summary_2_judgment               | case summary 2 judgment             |
      | d1f1       | case_summary_2_reasons_for_judgment   | case summary 2 reasons for judgment |
      | d1f1       | case_summary_3_judgment               | case summary 3 judgment             |
      | d1f1       | case_summary_3_reasons_for_judgment   | case summary 3 reasons for judgment |
      | d1f1       | case_summary_4_judgment               | case summary 4 judgment             |
      | d1f1       | case_summary_4_reasons_for_judgment   | case summary 4 reasons for judgment |
      | d1f1       | case_summary_5_judgment               | case summary 5 judgment             |
      | d1f1       | case_summary_5_reasons_for_judgment   | case summary 5 reasons for judgment |
      | d1f1       | category                              | new category                        |
      | d1f1       | classification                        | new classification                  |
      | d1f1       | corporate_body                        | new corporate body                  |
      | d1f1       | curated_date                          | new curated date                    |
      | d1f1       | curated_date_note                     | new curated date note               |
      | d1f1       | date_archivist_note                   | archivist note date                 |
      | d1f1       | archivist_note                        | archivist note                      |
      | d1f1       | internal_department                   | internal department                 |
      | d1f1       | duration_mins                         | new duration mins                   |
      | d1f1       | file_name_language                    | english                             |
      | d1f1       | file_name_translation                 | new file name translation           |
      | d1f1       | file_name_translation_language        | welsh                               |
      | d1f1       | film_maker                            | new film maker                      |
      | d1f1       | film_name                             | new film name                       |
      | d1f1       | hearing_date                          | new hearing date                    |
      | d1f1       | original_identifier                   | new original identifier             |
      | d1f1       | photographer                          | new photographer                    |
      | d1f1       | subject_role_1                        | new subject role 1                  |
      | d1f1       | subject_role_2                        | new subject role 2                  |
      | d1f1       | subject_role_3                        | new subject role 3                  |
      | d1f1       | summary                               | new summary                         |
      | d1f1       | web_archive_url                       | new web archive url                 |
      | d1f1       | witness_list_1                        | new witness list 1                  |
      | d1f1       | witness_list_2                        | new witness list 2                  |
      | d1f1       | witness_list_3                        | new witness list 3                  |
      | d1f1       | iaid                                  | new iaid                            |
      | d1f1       | attachment_former_reference           | attachment former reference         |
      | d1f1       | attachment_link                       | attachment link                     |
      | d1f1       | evidence_provided_by                  | evidence provided by                |
      | d1f1       | Content_management_system_container   | Content management system container |
      | d1f1       | Business_area                         | Business area                       |
      | d1f1       | distressing_content                   | Distressing content                 |
      | d1f1       | date_created                          | Date created                        |
      | d1f1       | separated_material                    | Separated material                  |
      | d1f1       | TDR_consignment_ref                   | TDR consignment ref                 |
      | d1f1       | judgment_court                        | Judgment court                      |
      | d1f1       | judgment_date                         | Judgment date                       |
      | d1f1       | judgment_name                         | Judgment name                       |
      | d1f1       | judgment_neutral_citation             | Judgment neutral citation           |
      | d1f1       | checksum_md5                          | Checksum MD5                        |
      | d1f1       | google_id                             | Google ID                           |
      | d1f1       | google_parent_id                      | Google parent ID                    |
      | d1f1       | other_format_version_identifier       | Other format version identifier     |
      | d1f1       | held_by                               | Another department                  |
      | d1f2       | description                           | test file 2                         |
      | d1f1       | parent_dri_ref                        | ADM 360/4/55                        |

    And I perform transformation convert-csv-to-xml for collection TEST1Y19HS001/TEST_1:
    When I apply XSLT add-born-digital-metadata-to-sip_v2.2.xslt to metadata.xml in collection TEST1Y19HS001/TEST_1 to output merged-metadata.xml with parameters:
      | metadata-csv-xml-path                     | ../metadata_TEST1Y19HS001.csv.xml     |
      | cs-part-schemas-uri                       | ../schemas.xml                        |
      | cs-series-uri                             | ../series.xml                         |
    Then I want to validate XML merged-metadata.xml for collection TEST1Y19HS001/TEST_1:
      | xpath                                                                                    | value                               |
      | //Cataloguing[description = 'test file 1']/hearing_date                                  | new hearing date                    |
      | //Cataloguing[description = 'test file 1']/subject_role_1                                | new subject role 1                  |
      | //Cataloguing[description = 'test file 1']/subject_role_2                                | new subject role 2                  |
      | //Cataloguing[description = 'test file 1']/subject_role_3                                | new subject role 3                  |
      | //Cataloguing[description = 'test file 1']/webArchiveUrl                                 | new web archive url                 |
      | //Cataloguing[description = 'test file 1']/witness_list_1                                | new witness list 1                  |
      | //Cataloguing[description = 'test file 1']/witness_list_2                                | new witness list 2                  |
      | //Cataloguing[description = 'test file 1']/witness_list_3                                | new witness list 3                  |
      | //Cataloguing[description = 'test file 1']/case_summary_1_judgment                       | case summary 1 judgment             |
      | //Cataloguing[description = 'test file 1']/case_summary_1_reasons_for_judgment           | case summary 1 reasons for judgment |
      | //Cataloguing[description = 'test file 1']/case_summary_2_judgment                       | case summary 2 judgment             |
      | //Cataloguing[description = 'test file 1']/case_summary_2_reasons_for_judgment           | case summary 2 reasons for judgment |
      | //Cataloguing[description = 'test file 1']/case_summary_3_judgment                       | case summary 3 judgment             |
      | //Cataloguing[description = 'test file 1']/case_summary_3_reasons_for_judgment           | case summary 3 reasons for judgment |
      | //Cataloguing[description = 'test file 1']/case_summary_4_judgment                       | case summary 4 judgment             |
      | //Cataloguing[description = 'test file 1']/case_summary_4_reasons_for_judgment           | case summary 4 reasons for judgment |
      | //Cataloguing[description = 'test file 1']/case_summary_5_judgment                       | case summary 5 judgment             |
      | //Cataloguing[description = 'test file 1']/case_summary_5_reasons_for_judgment           | case summary 5 reasons for judgment |
      | //Cataloguing[description = 'test file 1']/category                                      | new category                        |
      | //Cataloguing[description = 'test file 1']/classification                                | new classification                  |
      | //Cataloguing[description = 'test file 1']/corporateBody                                 | new corporate body                  |
      | //Cataloguing[description = 'test file 1']/curatedDate                                   | new curated date                    |
      | //Cataloguing[description = 'test file 1']/curatedDateNote                               | new curated date note               |
      | //Cataloguing[description = 'test file 1']/internalDepartment                            | internal department                 |
      | //Cataloguing[description = 'test file 1']/archivistNote/ArchivistNote/archivistNoteInfo | archivist note                      |
      | //Cataloguing[description = 'test file 1']/archivistNote/ArchivistNote/archivistNoteDate | archivist note date                 |
      | //Cataloguing[description = 'test file 1']/durationMins                                  | new duration mins                   |
      | //Cataloguing[description = 'test file 1']/title[@lang = 'english']                      | d1f1.tif                            |
      | //Cataloguing[description = 'test file 1']/title[@lang = 'welsh']                        | new file name translation           |
      | //Cataloguing[description = 'test file 1']/filmMaker                                     | new film maker                      |
      | //Cataloguing[description = 'test file 1']/filmName                                      | new film name                       |
      | //Cataloguing[description = 'test file 1']/originalIdentifier                            | new original identifier             |
      | //Cataloguing[description = 'test file 1']/photographer                                  | new photographer                    |
      | //Cataloguing[description = 'test file 1']/summary                                       | new summary                         |
      | //Cataloguing[description = 'test file 1']/iaid                                          | new iaid                            |
      | //Cataloguing[description = 'test file 1']/attachmentFormerReference                     | attachment former reference         |
      | //Cataloguing[description = 'test file 1']/attachmentLink                                | attachment link                     |
      | //Cataloguing[description = 'test file 1']/evidenceProvidedBy                            | evidence provided by                |
      | //Cataloguing[description = 'test file 1']/contentManagementSystemContainer              | Content management system container |
      | //Cataloguing[description = 'test file 1']/businessArea                                  | Business area                       |
      | //Cataloguing[description = 'test file 1']/dateCreated                                   | Date created                        |
      | //Cataloguing[description = 'test file 1']/separatedMaterial                             | Separated material                  |
      | //Cataloguing[description = 'test file 1']/tdrConsignmentRef                             | TDR consignment ref                 |
      | //Cataloguing[description = 'test file 1']/judgmentCourt                                 | Judgment court                      |
      | //Cataloguing[description = 'test file 1']/judgmentDate                                  | Judgment date                       |
      | //Cataloguing[description = 'test file 1']/judgmentName                                  | Judgment name                       |
      | //Cataloguing[description = 'test file 1']/judgmentNeutralCitation                       | Judgment neutral citation           |
      | //Cataloguing[description = 'test file 1']/checksumMd5                                   | Checksum MD5                        |
      | //Cataloguing[description = 'test file 1']/googleId                                      | Google ID                           |
      | //Cataloguing[description = 'test file 1']/googleParentId                                | Google parent ID                    |
      | //Cataloguing[description = 'test file 1']/otherFormatVersionIdentifier                  | Other format version identifier     |
      | //Cataloguing[description = 'test file 1']/heldBy                                        | Another department                  |
      | //Cataloguing[description = 'test file 2']/heldBy                                        | The National Archives, Kew          |
      | //Cataloguing[description = 'test file 1']/parentDriRef                                  | ADM 360/4/55                        |
    And I perform schema validation using XIP-full-tna-customised.xsd on merged-metadata.xml in collection TEST1Y19HS001/TEST_1
