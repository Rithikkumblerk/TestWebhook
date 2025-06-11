@RestResource(urlMapping='/api/webhookSubscription/*')
 global with sharing class webhookSubscriptionDemo {
        @HttpPost
        global static void handleNotification() {
            try{
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;

            // Log the incoming request body
            System.debug('Received webhook notification: ' + req.requestBody.toString());

            String hashedval =  req.headers.get('X-Hub-Signature-256');
            Blob bB = req.requestBody;
            Blob hmac = Crypto.generateMac('HmacSHA256', bB, Blob.valueOf('webhooktesting'));
            String hmacString = 'sha256=' + EncodingUtil.convertToHex(hmac);
            if(hashedval == hmacString){
                System.debug('HMAC validation successful//////////');

                JSONParser parser = JSON.createParser(req.requestBody.toString());
                pusher ps;
                head_commit hc;
                String repo;
                while(parser.nextToken() != null){
                    if(parser.getText() == 'pusher') {
                        parser.nextToken(); // Move to the next token
                        ps = (pusher)parser.readValueAs(pusher.class);
                    } else if(parser.getText() == 'head_commit') {
                        parser.nextToken(); // Move to the next token
                        hc = (head_commit)parser.readValueAs(head_commit.class);
                    } else if(parser.getText() == 'full_name') {
                        parser.nextToken(); // Move to the next token
                        repo = parser.getText();
                      }
                }
                Github_Details__c githubDetails = new Github_Details__c();
                githubDetails.Committer_Name__c = ps!=null? ps.name:'';
                githubDetails.Committer_Email__c = ps!=null? ps.email:'';
                githubDetails.Commit_Timestamp__c = hc!=null? hc.timestamp:'';
                githubDetails.Committer_URL__c = hc!=null? hc.url:'';
                githubDetails.Repository_Name__c = repo;
                githubDetails.Added_Components__c = hc!=null && hc.added!=null? String.join(hc.added, ','):'';
                githubDetails.Modified_Components__c = hc!=null && hc.modified!=null? String.join(hc.modified, ','):'';
                githubDetails.Removed_Components__c = hc!=null && hc.removed!=null? String.join(hc.removed, ','):'';
                insert githubDetails;
                res.statusCode = 200;
                res.responseBody = Blob.valueOf(JSON.serialize(new SFDCResponse('success', 'Webhook notification processed successfully')));
            } else {
                System.debug('HMAC validation failed');
                res.statusCode = 403;
                res.responseBody = Blob.valueOf(JSON.serialize(new SFDCResponse('error', 'HMAC validation failed')));
            }
        }
        catch(Exception e){
            System.debug('Error processing webhook notification: ' + e.getMessage());
            RestResponse res = RestContext.response;
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Error processing webhook notification: ' + e.getMessage());
         }
    }

    public class pusher {
        public String name;
        public String email;
        public pusher(String name, String email) {
            this.name = name;
            this.email = email;
          }
    }

    public class head_commit {
        public String timestamp;
        public String url;
        public List<String> added;
        public List<String> modified;
        public List<String> removed;

        public head_commit(String timestamp, String url, List<String> added, List<String> modified, List<String> removed) {

            timestamp = timestamp;
            url = url;
            added = added;
            modified = modified;
            removed = removed;
        }
    }
    public class SFDCResponse {
        public String status;
        public String message;

        public SFDCResponse(String status, String message) {
            status = status;
            message = message;
        }
    }

}