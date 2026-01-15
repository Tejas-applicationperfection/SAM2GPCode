public class StringIterator implements Iterable<String>, Iterator<String> { 
    public List<String> lstString;
    Integer i {get; set;} 
    
    public StringIterator(List<String> lstString) {
         this.lstString = lstString;
        i = 0; 
    } 
    
    public Boolean hasNext() 
    { 
        return (i >= lstString.size()) ? false : true; 
    } 

    public String next()
    { 
        if(i < lstString.size())
        {
            i = i+1;
            return lstString[i-1]; 
        }
        return null;
    } 
    public Iterator<String> iterator() 
    { 
        return this; 
    } 
}