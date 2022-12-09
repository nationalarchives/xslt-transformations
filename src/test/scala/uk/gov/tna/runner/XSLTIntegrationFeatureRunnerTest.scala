package uk.gov.tna.runner

import cucumber.api.CucumberOptions
import cucumber.api.junit.Cucumber
import org.junit.runner.RunWith

@RunWith(classOf[Cucumber])
@CucumberOptions(
  features = Array("classpath:features/"),
  tags = Array("~@Wip"),
  glue = Array("classpath:uk.gov.tna.steps"),
  plugin = Array("pretty", "html:target/cucumber-html-report", "json:target/cucumber-json-report.json" ))
class XSLTIntegrationFeatureRunnerTest