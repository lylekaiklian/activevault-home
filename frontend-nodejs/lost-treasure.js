/*
 * Lost Treasure Front-end server
 */

var sys = require("sys"),  
my_http = require("http");  
var AWS = require('aws-sdk'); 

my_http.createServer(function(request,response){  
    //sys.puts("I got kicked");  
    response.writeHeader(200, {"Content-Type": "text/plain"});  
    response.write("I got kicked");  
    response.end();  
}).listen(3007);  
sys.puts("Server Running on 3007"); 