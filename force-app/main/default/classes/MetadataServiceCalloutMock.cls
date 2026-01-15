@IsTest
global class MetadataServiceCalloutMock implements HttpCalloutMock {
    MetadataService.ReadResult readResult;
    
    public MetadataServiceCalloutMock(MetadataService.ReadResult readResult) {
        this.readResult = readResult;
    }

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/xml');
        res.setBody(serializeReadResult(readResult));
        res.setStatusCode(200);
        return res;
    }
    
    private String serializeReadResult(MetadataService.ReadResult result) {
        // Serialize the ReadResult into an XML format that simulates the actual response
        // You can customize this part based on your needs
        return '<?xml version="1.0" encoding="UTF-8"?><ReadResult>...</ReadResult>';
    }
}