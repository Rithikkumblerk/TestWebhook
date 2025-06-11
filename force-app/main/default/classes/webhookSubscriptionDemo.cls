@RestResource(urlMapping='/api/webhookSubscription/*')
 global with sharing class webhookSubscriptionDemo {
        @HttpPost
        global static void handleNotification() {
            try{
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;

            // Log the incoming request body
            System.debug('Received webhook notification: ' + req.requestBody.toString());


            // Set the response status code
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('Webhook notification received successfully');
        }
        catch(Exception e){
            System.debug('Error processing webhook notification: ' + e.getMessage());
            RestResponse res = RestContext.response;
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Error processing webhook notification: ' + e.getMessage());
        }
    }
}