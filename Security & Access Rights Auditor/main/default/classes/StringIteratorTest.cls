@isTest
private class StringIteratorTest {

    @isTest
    static void testEmptyList() {
        List<String> emptyList = new List<String>();
        StringIterator iterator = new StringIterator(emptyList);
        
        System.assert(!iterator.hasNext(), 'Iterator should not have next for an empty list.');
    }

    @isTest
    static void testSingleElementList() {
        List<String> singleItemList = new List<String>{'Test1'};
        StringIterator iterator = new StringIterator(singleItemList);
        
        System.assert(iterator.hasNext(), 'Iterator should have next for a single item list.');
        String firstElement = iterator.next();
        System.assertEquals('Test1', firstElement, 'The first element should be \'Test1\'.');
        System.assert(!iterator.hasNext(), 'Iterator should not have next after the only item is retrieved.');
    }

    @isTest
    static void testMultipleElementsList() {
        List<String> multipleItemsList = new List<String>{'Test1', 'Test2', 'Test3'};
        StringIterator iterator = new StringIterator(multipleItemsList);

        // Iterating through each element
        Integer counter = 0;
        while(iterator.hasNext()) {
            String element = iterator.next();
            counter++;
            System.assertEquals('Test' + counter, element, 'Element mismatch at position ' + counter);
        }

        System.assertEquals(3, counter, 'There should be exactly 3 elements in the list.');
        System.assert(!iterator.hasNext(), 'Iterator should not have next after all items are retrieved.');
    }
}