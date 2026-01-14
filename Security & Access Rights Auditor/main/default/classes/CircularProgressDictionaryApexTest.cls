@isTest
public class CircularProgressDictionaryApexTest {
    
    @testSetup static void methodName() {
        Opportunity opp = new Opportunity(Name='Circular Progress bar Test',Amount=80,Probability=60,stageName='In Progress',CloseDate=Date.today().addMonths(2));
        insert opp;
    }
    
    /**
* Below test method creates dynamic SOQL on the basis of two field API provided
* */
    @isTest
    static void testUsingFields(){
        Opportunity opp = [SELECT Id, Amount, ExpectedRevenue FROM Opportunity];
        String retVal = CircularProgressControllerDictionaryApex.computePercentage('Opportunity',Opp.id,'Amount','ExpectedRevenue');
        
        CircularProgressControllerDictionaryApex.WrapperJSON retPOJO = (CircularProgressControllerDictionaryApex.WrapperJSON)JSON.deserialize(retVal, CircularProgressControllerDictionaryApex.WrapperJSON.class);
        System.assertEquals(retPOJO.actual, 48) ;
        System.assertEquals(retPOJO.total, 80) ;
        System.assertEquals(retPOJO.val, 60) ;
    }
    
    /**
* Below test method creates dynamic SOQL on the basis of single field considering it as
* percentage type of field
* */
    @isTest
    static void testUsingSingleField(){
        Opportunity opp = [SELECT Id, Amount, ExpectedRevenue FROM Opportunity];
        String retVal = CircularProgressControllerDictionaryApex.computePercentage('Opportunity',Opp.id,'','Amount');
        
        CircularProgressControllerDictionaryApex.WrapperJSON retPOJO = (CircularProgressControllerDictionaryApex.WrapperJSON)JSON.deserialize(retVal, CircularProgressControllerDictionaryApex.WrapperJSON.class);
        System.assertEquals(retPOJO.actual, 80) ;
        System.assertEquals(retPOJO.total, null) ;
        System.assertEquals(retPOJO.val, 80) ;
    }
    
}