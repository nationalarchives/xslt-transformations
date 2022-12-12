package uk.gov.tna.steps

import com.github.tomakehurst.wiremock.WireMockServer
import com.github.tomakehurst.wiremock.common.ClasspathFileSource
import com.github.tomakehurst.wiremock.core.WireMockConfiguration.wireMockConfig
import com.github.tomakehurst.wiremock.standalone.JsonFileMappingsSource
import cucumber.api.DataTable
import cucumber.api.scala.{EN, ScalaDsl}
import org.scalatest.Matchers
import org.slf4j.LoggerFactory
import scalax.file.Path
import scalax.io.support.FileUtils
import transformations.csv.FilePattern
import transformations.matchers.XPathMatchers._
import transformations.steps.{XSLTIntegrationSteps, XpathQuery}
import transformations.transform._

import java.io._
import scala.collection.JavaConverters._
import scala.io.Source
import scala.util.{Failure, Success}

class StepDefs extends ScalaDsl with EN with Matchers {
  val log = LoggerFactory.getLogger(this.getClass)

  val xsltIntegrationSteps:XSLTIntegrationSteps = new XSLTIntegrationSteps
  var wireMockServer : Option[WireMockServer] = None

  Before { scenario =>
    xsltIntegrationSteps.beforeTest
  }

  After { scenario =>
    wireMockServer match {
      case Some(x:WireMockServer) => x.stop()
        log.info("wire mock stopped")
      case None =>
    }
  xsltIntegrationSteps.afterTest
  }

  And("""^csv fields in file (.*) are updated in collection (.*[\/]{1}.*):""") { (filePath:String,collectionPath:String, dataTable: DataTable) =>
    xsltIntegrationSteps.updateCSVFileInCollection (FilePattern(Some(filePath.r)),collectionPath, dataTable)
  }


  Given("""^the example collection of type (.*) for collection (.*[\/]{1}.*):""") { (collectionType: String, collectionPath: String) =>
    xsltIntegrationSteps.theExampleCollection(collectionType, collectionPath)
  }

  Given("""^I have registered collection (.*[\/]{1}.*):""") { (collection:String) =>  }
  Given("""^I have pre-ingested collection (.*[\/]{1}.*):"""){ (collection:String) =>  }

  When("""^I perform transformation (.*) for collection (.*[\/]{1}.*):""") { (operation: String, collectionPath: String) =>
    xsltIntegrationSteps.iPerformTransformationXForCollectionX(operation, collectionPath)
  }

  Given("""^Xml file (.*):""") { _xmlFile:String =>
  }

  And("""^metadata transcription fields are updated for collection (.*[\/]{1}.*):""") { (collectionPath:String, dataTable: DataTable) =>
    xsltIntegrationSteps.transcriptionFieldsAreXToMetadataForCollectionX(collectionPath, dataTable)
  }

  And("""^I mock catalogue with wiremock mapping on classpath (.*):$""") { classpath : String =>
    wireMockServer match {
      case None => wireMockServer = Some(new WireMockServer(wireMockConfig().port(8089)))
        wireMockServer.get.loadMappingsUsing(new JsonFileMappingsSource(new ClasspathFileSource(classpath)))
        wireMockServer.get.start()
      case Some(_) =>
    }
  }

  Then("""^Apply XSLT (.*) on (.*) and output (.*) and parameters:$""") { (xslt: String, xmlInput: String, xmlOutput: String,  dataTable: DataTable) =>

    val port = wireMockServer.get.getOptions.portNumber().toString

    val xsltParametersMap = dataTable.asMap(classOf[String], classOf[String]).asScala.toMap

    val xsltFile = "src/main/resources" + "/" + xslt

    val transformation = TransformData(xsltFile,
                  Option(Path.fromString(s"src/test/resources/${xmlInput}")),
                  Path.fromString(xmlOutput),
                  xsltParametersMap)

    Transformer.transform(List(transformation))
  }

  Then("""^I apply XSLT (.*) on (.*) and output (.*) and parameters:$""") { (xslt: String, xmlInput: String, xmlOutput: String,  dataTable: DataTable) =>

    val xsltParametersMap = dataTable.asMap(classOf[String], classOf[String]).asScala.toMap

    val xsltFile = if (xslt.startsWith("target/")) xslt else "src/main/resources" + "/" + xslt

    val transformation = TransformData(xsltFile,
      Option(Path.fromString(s"src/test/resources/${xmlInput}")),
      Path.fromString(xmlOutput),
      xsltParametersMap)

    Transformer.transform(List(transformation))
    val transformTry = Transformer.transform(List(transformation))
    transformTry match {
      case Success(_) =>
      case Failure(exception) => println(exception)
    }
    transformTry.isSuccess shouldBe true
  }

  Then("""^I create a test copy of file (.*) and output (.*)""") { (inputFile: String, outputFile: String) =>
    val in = "src/main/resources" + "/" + inputFile
    val path = new FileInputStream(new File(in))
    val dest = new FileOutputStream(new File(outputFile))
    val output = FileUtils.copy(path, dest)
    output
  }

  Then("""^I replace value (.*) with (.*) from file (.*)""") { (initialValue: String, replacement: String, inputFile: String) =>
    val redactedClosure = Source.fromFile(inputFile).getLines().toList

    val replacable = redactedClosure map {
      case line if line.contains(initialValue) => line.replace(initialValue, replacement)
      case line => line
    }

    val file = new File(inputFile)
    val bw = new BufferedWriter(new FileWriter(file))
    for (line <- replacable) {
      bw.write(line)
    }
    bw.close()
  }

  Then("""^I want to validate XML (.*) with xpath:$""") { (xmlFile: String, dataTable: DataTable) =>
    val data = dataTable.asList(classOf[XpathQuery]).asScala
    val output = Path.fromString(s"${xmlFile}").toURI.toASCIIString
    for (query <- data) {
      output should haveXPath(query.xpath,query.value)
    }
  }

  Then("""^I want to validate XML (.*) for collection (.*[\/]{1}.*):$""") { (xmlFile: String, collectionPath: String, dataTable: DataTable) =>
    xsltIntegrationSteps.iWantToValidateXMLXForCollectionX(xmlFile, collectionPath, dataTable);
  }

  And("""^I perform the (.*) transformation for collection (.*[\/]{1}.*) using:""") { (transformation: String, collectionPath: String, dataTable: DataTable) =>
    xsltIntegrationSteps.iPerformTheXTransformationOnCollectionXUsing(transformation, collectionPath, dataTable)
  }

  Then("""^the result of the transformation (.*) for collection (.*[\/]{1}.*) has:""") { (operation: String, collectionPath: String,  dataTable: DataTable) =>
    xsltIntegrationSteps.theResultOfTheTransformationXForCollectionXHas(operation, collectionPath, dataTable)
  }

  Given("""^the collection (.*[\/]{1}.*) has been ingested using the (.*) workflow"""){ (collectionPath: String, workflow:String) =>
    xsltIntegrationSteps.theCollectionXHasBeenIngestedUsingTheXWorkflow(collectionPath, workflow)
  }

  Then("""^the result of ingest for collection (.*[\/]{1}.*) has:""") { (collectionPath: String, dataTable: DataTable) =>
    xsltIntegrationSteps.theResultOfIngestForCollectionXHas(collectionPath, dataTable)
  }


  Then("""^I apply XSLT (.*) to (.*) in collection (.*) to output (.*) with parameters:$""") {
    (xslt: String, xmlInput: String, collection: String, xmlOutput: String, dataTable: DataTable) =>
      val xsltParametersMap = dataTable.asMap(classOf[String], classOf[String]).asScala.toMap
      xsltIntegrationSteps.applyTransformationForCollection(XSLTTransformData(XsltFile(xslt), InputFile(xmlInput),
        OutputFile(xmlOutput), XsltParameters(xsltParametersMap)), Some(Collection(collection)))
  }

  Then("""^I expect error '(.*)' on applying XSLT (.*) to (.*) in collection (.*) to output (.*) with parameters:$""") {
    (errorMessage:String ,xslt: String, xmlInput: String, collection: String, xmlOutput: String, dataTable: DataTable) =>
      val xsltParametersMap = dataTable.asMap(classOf[String], classOf[String]).asScala.toMap
      val transform = xsltIntegrationSteps.applyTransformationForCollection(XSLTTransformData(XsltFile(xslt), InputFile(xmlInput),
        OutputFile(xmlOutput), XsltParameters(xsltParametersMap)), Some(Collection(collection)))
      transform match {
        case Success(x) => fail("Transform should have had exception")
        case Failure(exception) =>  errorMessage shouldBe exception.getMessage
      }
  }

  Then("""^I expect error on applying XSLT (.*) to (.*) in collection (.*) to output (.*) with parameters:$""") {
    (xslt: String, xmlInput: String, collection: String, xmlOutput: String, dataTable: DataTable) =>
      val xsltParametersMap = dataTable.asMap(classOf[String], classOf[String]).asScala.toMap
      val transform =  xsltIntegrationSteps.applyTransformationForCollection(XSLTTransformData(XsltFile(xslt), InputFile(xmlInput),
        OutputFile(xmlOutput), XsltParameters(xsltParametersMap)), Some(Collection(collection)))
      transform match {
        case Success(x) => fail("Transform should have had exception")
        case Failure(exception) => succeed //we are expecting a failure
      }
  }

  Then("""^I perform schema validation using (.*) on (.*) in collection (.*[\/]{1}.*)""") { (schema:String, file: String, collectionPath:String) =>
      xsltIntegrationSteps.performSchemaValidationForCollection(ValidationFile(file),SchemaFile(schema), Some(Collection(collectionPath)))
  }

  Then("""^I perform schema validation with (.*) on (.*)$""") { (schema:String ,file: String) =>
    xsltIntegrationSteps.performSchemaValidation(ValidationFile(file),SchemaFile(schema), None,None,None)
  }

  Then("""^I transform with schematron XSLT (.*) to (.*) in collection (.*):$""") {
    (xslt: String, xmlInput: String, collection: String) =>
      xsltIntegrationSteps.applySchematronForCollection(XSLTTransformData(XsltFile(xslt), InputFile(xmlInput),
        OutputFile("schematron_output.xml"),  XsltParameters(Map[String,String]())), Some(Collection(collection)))
  }

  Then("""^I apply schematron XSLT (.*) to (.*) data$""") {
    (xslt: String, xmlInput: String) =>

     xsltIntegrationSteps.applySchematron(XSLTTransformData(XsltFile(xslt), InputFile(xmlInput),
        OutputFile("target/schematron_output.xml"), XsltParameters(Map[String,String]())),Some(WorkingDir(".")), None)
  }

  def getOutputFileName(fileName: String): Path = {
    Path.fromString(s"target/${fileName}.transformation-out.xml")
  }
}