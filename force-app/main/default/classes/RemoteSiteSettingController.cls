/** 
 * This class is not in used anywhere in the org , earlier we were using this class for remotesite settings.thats why we haev commented this code..
 * 
 * 
 * 
 * 
 * The MIT License (MIT)
 * 
 * Copyright (c) 2014 bigass.force.com
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
/*public class RemoteSiteSettingController {
    
  
    static public Boolean isRssPresent {
        get {
            if (isRssPresent == null) {
                //memoize
                HttpRequest request = new HttpRequest();
                request.setEndpoint(protocolAndHost);
                request.setMethod('GET');
                
                try {
                    new Http().send(request);
                    isRssPresent = true;
                } catch (CalloutException e) {
                    //probably 'Unauthorized endpoint'
                    system.debug('CalloutException::' + e);
                    if(e.getMessage().contains('Unauthorized endpoint, please check Setup->Security->Remote site settings')) {
                    	isRssPresent = false;
                    }
                }
            }
            
            return isRssPresent;
        }
    }
    
    
    static public String protocolAndHost {
        get {
            if (protocolAndHost == null) {
                //memoize
                String orgId = UserInfo.getOrganizationId();
                String userId = UserInfo.getUserId();
                String sessionId = UserInfo.getSessionId();
                
                //use getSalesforceBaseUrl within batches and schedules (not Visualforce), and fix inconsistent protocol
                if (sessionId == null) return Url.getSalesforceBaseUrl().toExternalForm().replace('http:', 'https:');
                
                PageReference pr = new PageReference('/id/' + orgId + '/' + userId);
                pr.getParameters().put('oauth_token', sessionId);
                pr.getParameters().put('format', 'json');
                
                //within test context use url class, else derive from identity api
                system.debug('aaa:::' +  ApexPages.currentPage().getParameters().get('retPage') );
                String retPage = ApexPages.currentPage().getParameters().get('retPage');
                String data = '';
                if(retPage != null && retPage.containsIgnoreCase('Intel')) {
                    data = URL.getSalesforceBaseUrl().toExternalForm();
                } else {
                    data = Test.isRunningTest() ? '{"urls": {"rest": "' + Url.getSalesforceBaseUrl().toExternalForm() + '"}}' : pr.getContent().toString();
                }
                system.debug('data:::' +  data);
                Map<String,Object> result = (Map<String,Object>)Json.deserializeUntyped(data);
                Map<String,Object> urls = (Map<String,Object>)result.get('urls');
                Url rest = new Url((String)urls.get('rest'));
                protocolAndHost = rest.getProtocol() + '://' + rest.getHost();
            }
            
            return protocolAndHost;
        }
    }
    
    public String getDeployXml() {
        return ''
            + '<?xml version="1.0" encoding="utf-8"?>'
            + '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
            + '<env:Header>'
            + '<urn:SessionHeader xmlns:urn="http://soap.sforce.com/2006/04/metadata">'
            + '<urn:sessionId>' + UserInfo.getSessionId() + '</urn:sessionId>'
            + '</urn:SessionHeader>'
            + '</env:Header>'
            + '<env:Body>'
            + '<createMetadata xmlns="http://soap.sforce.com/2006/04/metadata">'
            + '<metadata xsi:type="RemoteSiteSetting">'
            + '<fullName>Salesforce_API_' + String.valueOf(DateTime.now().getTime()).right(4) + '</fullName>'
            + '<description>Salesforce API</description>'
            + '<disableProtocolSecurity>false</disableProtocolSecurity>'
            + '<isActive>true</isActive>'
            + '<url>' + protocolAndHost + '</url>'
            + '</metadata>'
            + '</createMetadata>'
            + '</env:Body>'
            + '</env:Envelope>'
        ;
    }
}*/
public class RemoteSiteSettingController {
    // Declare static variables
  /*   @TestVisible
    static Boolean isRssPresent { get; private set; }

    @TestVisible
    static String protocolAndHost { get; private set; }

    static {
        isRssPresent = null;
        protocolAndHost = null;
    }
     
    public static Boolean getIsRssPresent() {
        if (isRssPresent == null) {
            // Memoize
            HttpRequest request = new HttpRequest();
            request.setEndpoint(getProtocolAndHost());
            request.setMethod('GET');

            try {
                new Http().send(request);
                isRssPresent = true;
            } catch (CalloutException e) {
                // Handle 'Unauthorized endpoint'
                System.debug('CalloutException::' + e);
                if (e.getMessage().contains('Unauthorized endpoint, please check Setup->Security->Remote site settings')) {
                    isRssPresent = false;
                }
            }
        }
        return isRssPresent;
    }

     
    public static String getProtocolAndHost() {
        if (protocolAndHost == null) {
            // Memoize
            String orgId = UserInfo.getOrganizationId();
            String userId = UserInfo.getUserId();
            String sessionId = UserInfo.getSessionId();

            // Use getSalesforceBaseUrl within batches and schedules
            if (sessionId == null) {
                return Url.getSalesforceBaseUrl().toExternalForm().replace('http:', 'https:');
            }

            PageReference pr = new PageReference('/id/' + orgId + '/' + userId);
            pr.getParameters().put('oauth_token', sessionId);
            pr.getParameters().put('format', 'json');

            String data = Test.isRunningTest()
                ? '{"urls": {"rest": "' + Url.getSalesforceBaseUrl().toExternalForm() + '"}}'
                : pr.getContent().toString();

            System.debug('Data:::' + data);
            Map<String, Object> result = (Map<String, Object>)Json.deserializeUntyped(data);
            Map<String, Object> urls = (Map<String, Object>)result.get('urls');
            Url rest = new Url((String)urls.get('rest'));
            protocolAndHost = rest.getProtocol() + '://' + rest.getHost();
        }
        return protocolAndHost;
    }

     
    public String getDeployXml() {
        return ''
            + '<?xml version="1.0" encoding="utf-8"?>'
            + '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
            + '<env:Header>'
            + '<urn:SessionHeader xmlns:urn="http://soap.sforce.com/2006/04/metadata">'
            + '<urn:sessionId>' + UserInfo.getSessionId() + '</urn:sessionId>'
            + '</urn:SessionHeader>'
            + '</env:Header>'
            + '<env:Body>'
            + '<createMetadata xmlns="http://soap.sforce.com/2006/04/metadata">'
            + '<metadata xsi:type="RemoteSiteSetting">'
            + '<fullName>Salesforce_API_' + String.valueOf(DateTime.now().getTime()).right(4) + '</fullName>'
            + '<description>Salesforce API</description>'
            + '<disableProtocolSecurity>false</disableProtocolSecurity>'
            + '<isActive>true</isActive>'
            + '<url>' + getProtocolAndHost() + '</url>'
            + '</metadata>'
            + '</createMetadata>'
            + '</env:Body>'
            + '</env:Envelope>';
    }*/
}