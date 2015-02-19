# Project Lost Treasure

## Desktop Client ##
The desktop client must be installed on the machine where the USB dongles are connected. The desktop client runs on JRuby.

### Prerequisites ###
* Download RXTXcomm.jar and rxtxSerial.dll here: http://jlog.org/rxtx-win.html
* Download AWS-SDK for Java here: http://sdk-for-java.amazonwebservices.com/latest/aws-java-sdk.zip. Extract **aws-java-sdk-1.9.20.1.jar** at the **client** directory.

### Running ###
rake dev:test_kit	
rake dev:test_kit_sqs

## Web Front-end ##
The web front-end enables to run the test suite remotey. This runs on Rails 4.