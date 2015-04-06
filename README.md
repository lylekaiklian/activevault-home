# Project Lost Treasure

## Setup ##
* `lost-treasure/frontend-yo` is an AngularJS-based user-interface, and must run on port 3006.
* `lost-treasure/frontend-rails` is a Rails-based middleware API between the UI and Amazon SQS, and must run on port 3007.
* `lost-treasure/client` is a JRuby-based application that must run on a machine where dongles are plugged to USB ports.

## Desktop Client (`lost-treasure/client`) ##
The desktop client must be installed on the machine where the USB dongles are connected. The desktop client runs on JRuby.

### Prerequisites ###
* Download RXTXcomm.jar and rxtxSerial.dll here: http://jlog.org/rxtx-win.html
* Download AWS-SDK for Java here: http://sdk-for-java.amazonwebservices.com/latest/aws-java-sdk.zip. Extract **aws-java-sdk-1.9.20.1.jar** at the **client** directory.
* See https://gist.github.com/ardeearam/b20a48ab10b0e7458c74 for a complete list of JAR dependencies of the AWS Java SDK

### Running ###
* rake run['file','cases/mycase.in']
* rake port_sweep
* rake delete_all_messages
* rake hog_all_except
* rake dongle:number['COM4']
* rake dongle:balance['COM4']
* rake dongle:send_message['COM4','222','BAL']
* rake dongle:set_number['COM4','+639173292739']
* rake dongle:hog['COM4','COM5','COM6']

## Web Front-end (`lost-treasure/frontend-yo`) ##
The web front-end enables to run the test suite remotey. This runs on AngularJS/Yeoman.

## Middleware API (`lost-treasure/frontend-rails`) ##
This is an API that connects the AngularJS frontend to Amazon SQS. This design was chosen over AngularJS directly connecting
to Amazon SQS, as there is no secure way to hide Amazon credentials in a client-sided code. 
