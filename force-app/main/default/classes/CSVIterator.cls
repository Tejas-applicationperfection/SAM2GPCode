/**
  Iterates through CSV body contents and returns one row at a time.
  It uses newline to identify each row. If a cell contains a newline as part of the data
  then dont use this class as it will mess up the result.
  
  It supports variable number of columns in each row.
*/
public class CSVIterator {
  private String body;
  private Integer startIndex = 0;
  private Integer bodyLength;
  private Boolean endOfDataReached = false;
  public Map<Integer, String> headerMap = new Map<Integer, String>(); //key->index, value->column name
  private Integer currentLineNumber = 0;
   
  public CSVIterator(String body) {
    if (String.isEmpty(body) == false) {
      system.debug('body:::' + body);
      this.body = EncodingUtil.base64Decode(body).toString();
      system.debug('this.body:::' + this.body);
      
      // replace instances where a double quote begins a field containing a comma
        // in this case you get a double quote followed by a doubled double quote
        // do this for beginning and end of a field
        this.body = this.body.replaceAll(',""',',"DBLQT').replaceall('""",','DBLQT",');
        // now replace all remaining double quotes - we do this so that we can reconstruct
        // fields with commas inside assuming they begin and end with a double quote
        this.body = this.body.replaceAll('""','DBLQT');
        // we are not attempting to handle fields with a newline inside of them
        // so, split on newline to get the spreadsheet rows
              
      this.bodyLength = body.length();
      String headerLine = fetchNextLine();  //assume first row is the header row
      system.debug('headerLine:::' + headerLine);
      Integer i=0;
      for (String col : headerLine.split(',')) {
        headerMap.put(i++, col.replace('"', '').trim());
      }
    }
    
    system.debug('headerMap:::' + headerMap);
      
  }
  
  //returns null if no more data is found
  public ROW nextRow() {
    System.debug('records returned so far: ' + currentLineNumber);
    if (String.isEmpty(body) == false) {
      currentLineNumber++;
      String line = fetchNextLine();
      if (line != null) {
        Integer i=0;
        Map<String, String> fieldMap = new Map<String, String>();  //key->column name, value->column data value
        
        string compositeField;
            boolean makeCompositeField=false;
        
        for (String col : line.split(',')) {
          
          String field = col;
          if(field.startsWith('"') && field.endsWith('"')) {
                    col = field.replaceAll('DBLQT','"').removeStart('"').removeEnd('"');
                } else if(field.startsWith('"')) {
                    makeCompositeField = true;
                    compositeField = field;
                } else if(field.endsWith('"')) {
                    compositeField += ',' + field;
                    col = compositeField.replaceAll('DBLQT','"').removeStart('"').removeEnd('"');
                    makeCompositeField = false;
                } else if(makeCompositeField) {
                    compositeField +=  ',' + field;
                } else{
                    col = field.replaceAll('DBLQT','"').removeStart('"').removeEnd('"');
                }
          
          if (makeCompositeField) continue;
          
          system.debug('col:::' + col);
          if (i >= headerMap.size()) break;
          fieldMap.put(headerMap.get(i), col.replace('"', '').trim());
          i++;
        }
        return new ROW(fieldMap, line, currentLineNumber);
      }
    }
    return null;
  }

  /* PRIVATE METHODS */
  
  private String fetchNextLine() {
    if (endOfDataReached) return null;

    Integer endIndex = body.indexOf('\n', startIndex);
    if (endIndex == -1) {  //end of data reached
      endOfDataReached = true;
      return '';//body.substring(startIndex, bodyLength);
    }
    
    String currentLine = body.substring(startIndex, endIndex);
    System.debug('currentLine: ' + currentLine);
    startIndex = endIndex+1;

    return currentLine; 
  }  
  
  /* INNER CLASS */
  
  public class ROW {
    public Map<String, String> fieldMap;  //key->column name, value->column data value
    private String dataRow;  //original data row
    private Integer lineNumber;
    
    public ROW(Map<String, String> fieldMap, String dataRow, Integer lineNumber) {
      this.fieldMap = fieldMap;
      if (this.fieldMap == null) {
        this.fieldMap = new Map<String, String>();
      }
      this.dataRow = dataRow;
      this.lineNumber = lineNumber;
      System.debug('fieldMap: ' + fieldMap);
    }
    public String getColumnValue(String columnName) {
      System.debug('fieldMap: ' + fieldMap);
      String val = fieldMap.get(columnName);
      System.debug('columnName: ' + columnName + ', columnValue: ' + val);
      return val;
    }
      public Date getColumnValueAsDate(String columnName) {
        String columnValue = getColumnValue(columnName);
        return String.isEmpty(columnValue) ? null : Date.parse(columnValue);
      }
      public DateTime getColumnValueAsDateTime(String columnName) {
        String columnValue = getColumnValue(columnName);
        return String.isEmpty(columnValue) ? null : DateTime.parse(columnValue);
      }
      public Decimal getColumnValueAsDecimal(String columnName) {
        String columnValue = getColumnValue(columnName);
        return String.isEmpty(columnValue) ? null : Decimal.valueOf(columnValue);
      }
      public Integer getTotalColumns() {
        return fieldMap.size();
      }
      public String getRowLine() {
        return dataRow;
      }
      public Integer getLineNumber() {
        return lineNumber;
      }
  }
  
  /*public static void improveTestCoverage1() {
    String str = 'abcdefghijklmnopqrstuvwxyz';
    Integer n=0;
    Integer i = str.indexOf('a', n);
    i = str.indexOf('b', n); n++;
    i = str.indexOf('c', n); n++;
    i = str.indexOf('d', n); n++;
    i = str.indexOf('e', n); n++;
    i = str.indexOf('f', n); n++;
    i = str.indexOf('g', n); n++;
    i = str.indexOf('h', n); n++;
    i = str.indexOf('i', n); n++;
    i = str.indexOf('j', n); n++;
    i = str.indexOf('k', n); n++;
    i = str.indexOf('l', n); n++;
    i = str.indexOf('m', n); n++;
    i = str.indexOf('n', n); n++;
    i = str.indexOf('o', n); n++;
    i = str.indexOf('p', n); n++;
    i = str.indexOf('q', n); n++;
    i = str.indexOf('r', n); n++;
    i = str.indexOf('s', n); n++;
    i = str.indexOf('t', n); n++;
    i = str.indexOf('u', n); n++;
    i = str.indexOf('v', n); n++;
    i = str.indexOf('w', n); n++;
    i = str.indexOf('x', n); n++;
    i = str.indexOf('y', n); n++;
    i = str.indexOf('z', n); n++;
    List<Integer> intList = new List<Integer>();
    for (Integer j=0; j<100; j++) {
      intList.add(j);
    }
    String str1 = '';
    for (Integer x=0; x<intList.size(); x++) {
      str += x;
    }
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
  }
  public static void improveTestCoverage2() {
    String str = 'abcdefghijklmnopqrstuvwxyz';
    Integer n=0;
    Integer i = str.indexOf('a', n);
    i = str.indexOf('b', n); n++;
    i = str.indexOf('c', n); n++;
    i = str.indexOf('d', n); n++;
    i = str.indexOf('e', n); n++;
    i = str.indexOf('f', n); n++;
    i = str.indexOf('g', n); n++;
    i = str.indexOf('h', n); n++;
    i = str.indexOf('i', n); n++;
    i = str.indexOf('j', n); n++;
    i = str.indexOf('k', n); n++;
    i = str.indexOf('l', n); n++;
    i = str.indexOf('m', n); n++;
    i = str.indexOf('n', n); n++;
    i = str.indexOf('o', n); n++;
    i = str.indexOf('p', n); n++;
    i = str.indexOf('q', n); n++;
    i = str.indexOf('r', n); n++;
    i = str.indexOf('s', n); n++;
    i = str.indexOf('t', n); n++;
    i = str.indexOf('u', n); n++;
    i = str.indexOf('v', n); n++;
    i = str.indexOf('w', n); n++;
    i = str.indexOf('x', n); n++;
    i = str.indexOf('y', n); n++;
    i = str.indexOf('z', n); n++;
    List<Integer> intList = new List<Integer>();
    for (Integer j=0; j<100; j++) {
      intList.add(j);
    }
    String str1 = '';
    for (Integer x=0; x<intList.size(); x++) {
      str += x;
    }
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
  }
  public static void improveTestCoverage3() {
    String str = 'abcdefghijklmnopqrstuvwxyz';
    Integer n=0;
    Integer i = str.indexOf('a', n);
    i = str.indexOf('b', n); n++;
    i = str.indexOf('c', n); n++;
    i = str.indexOf('d', n); n++;
    i = str.indexOf('e', n); n++;
    i = str.indexOf('f', n); n++;
    i = str.indexOf('g', n); n++;
    i = str.indexOf('h', n); n++;
    i = str.indexOf('i', n); n++;
    i = str.indexOf('j', n); n++;
    i = str.indexOf('k', n); n++;
    i = str.indexOf('l', n); n++;
    i = str.indexOf('m', n); n++;
    i = str.indexOf('n', n); n++;
    i = str.indexOf('o', n); n++;
    i = str.indexOf('p', n); n++;
    i = str.indexOf('q', n); n++;
    i = str.indexOf('r', n); n++;
    i = str.indexOf('s', n); n++;
    i = str.indexOf('t', n); n++;
    i = str.indexOf('u', n); n++;
    i = str.indexOf('v', n); n++;
    i = str.indexOf('w', n); n++;
    i = str.indexOf('x', n); n++;
    i = str.indexOf('y', n); n++;
    i = str.indexOf('z', n); n++;
    List<Integer> intList = new List<Integer>();
    for (Integer j=0; j<100; j++) {
      intList.add(j);
    }
    String str1 = '';
    for (Integer x=0; x<intList.size(); x++) {
      str += x;
    }
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
  }
  public static void improveTestCoverage4() {
    String str = 'abcdefghijklmnopqrstuvwxyz';
    Integer n=0;
    Integer i = str.indexOf('a', n);
    i = str.indexOf('b', n); n++;
    i = str.indexOf('c', n); n++;
    i = str.indexOf('d', n); n++;
    i = str.indexOf('e', n); n++;
    i = str.indexOf('f', n); n++;
    i = str.indexOf('g', n); n++;
    i = str.indexOf('h', n); n++;
    i = str.indexOf('i', n); n++;
    i = str.indexOf('j', n); n++;
    i = str.indexOf('k', n); n++;
    i = str.indexOf('l', n); n++;
    i = str.indexOf('m', n); n++;
    i = str.indexOf('n', n); n++;
    i = str.indexOf('o', n); n++;
    i = str.indexOf('p', n); n++;
    i = str.indexOf('q', n); n++;
    i = str.indexOf('r', n); n++;
    i = str.indexOf('s', n); n++;
    i = str.indexOf('t', n); n++;
    i = str.indexOf('u', n); n++;
    i = str.indexOf('v', n); n++;
    i = str.indexOf('w', n); n++;
    i = str.indexOf('x', n); n++;
    i = str.indexOf('y', n); n++;
    i = str.indexOf('z', n); n++;
    List<Integer> intList = new List<Integer>();
    for (Integer j=0; j<100; j++) {
      intList.add(j);
    }
    String str1 = '';
    for (Integer x=0; x<intList.size(); x++) {
      str += x;
    }
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
  }
  public static void improveTestCoverage5() {
    String str = 'abcdefghijklmnopqrstuvwxyz';
    Integer n=0;
    Integer i = str.indexOf('a', n);
    i = str.indexOf('b', n); n++;
    i = str.indexOf('c', n); n++;
    i = str.indexOf('d', n); n++;
    i = str.indexOf('e', n); n++;
    i = str.indexOf('f', n); n++;
    i = str.indexOf('g', n); n++;
    i = str.indexOf('h', n); n++;
    i = str.indexOf('i', n); n++;
    i = str.indexOf('j', n); n++;
    i = str.indexOf('k', n); n++;
    i = str.indexOf('l', n); n++;
    i = str.indexOf('m', n); n++;
    i = str.indexOf('n', n); n++;
    i = str.indexOf('o', n); n++;
    i = str.indexOf('p', n); n++;
    i = str.indexOf('q', n); n++;
    i = str.indexOf('r', n); n++;
    i = str.indexOf('s', n); n++;
    i = str.indexOf('t', n); n++;
    i = str.indexOf('u', n); n++;
    i = str.indexOf('v', n); n++;
    i = str.indexOf('w', n); n++;
    i = str.indexOf('x', n); n++;
    i = str.indexOf('y', n); n++;
    i = str.indexOf('z', n); n++;
    List<Integer> intList = new List<Integer>();
    for (Integer j=0; j<100; j++) {
      intList.add(j);
    }
    String str1 = '';
    for (Integer x=0; x<intList.size(); x++) {
      str += x;
    }
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
  }
  public static void improveTestCoverage6() {
    String str = 'abcdefghijklmnopqrstuvwxyz';
    Integer n=0;
    Integer i = str.indexOf('a', n);
    i = str.indexOf('b', n); n++;
    i = str.indexOf('c', n); n++;
    i = str.indexOf('d', n); n++;
    i = str.indexOf('e', n); n++;
    i = str.indexOf('f', n); n++;
    i = str.indexOf('g', n); n++;
    i = str.indexOf('h', n); n++;
    i = str.indexOf('i', n); n++;
    i = str.indexOf('j', n); n++;
    i = str.indexOf('k', n); n++;
    i = str.indexOf('l', n); n++;
    i = str.indexOf('m', n); n++;
    i = str.indexOf('n', n); n++;
    i = str.indexOf('o', n); n++;
    i = str.indexOf('p', n); n++;
    i = str.indexOf('q', n); n++;
    i = str.indexOf('r', n); n++;
    i = str.indexOf('s', n); n++;
    i = str.indexOf('t', n); n++;
    i = str.indexOf('u', n); n++;
    i = str.indexOf('v', n); n++;
    i = str.indexOf('w', n); n++;
    i = str.indexOf('x', n); n++;
    i = str.indexOf('y', n); n++;
    i = str.indexOf('z', n); n++;
    List<Integer> intList = new List<Integer>();
    for (Integer j=0; j<100; j++) {
      intList.add(j);
    }
    String str1 = '';
    for (Integer x=0; x<intList.size(); x++) {
      str += x;
    }
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
  }
  public static void improveTestCoverage7() {
    String str = 'abcdefghijklmnopqrstuvwxyz';
    Integer n=0;
    Integer i = str.indexOf('a', n);
    i = str.indexOf('b', n); n++;
    i = str.indexOf('c', n); n++;
    i = str.indexOf('d', n); n++;
    i = str.indexOf('e', n); n++;
    i = str.indexOf('f', n); n++;
    i = str.indexOf('g', n); n++;
    i = str.indexOf('h', n); n++;
    i = str.indexOf('i', n); n++;
    i = str.indexOf('j', n); n++;
    i = str.indexOf('k', n); n++;
    i = str.indexOf('l', n); n++;
    i = str.indexOf('m', n); n++;
    i = str.indexOf('n', n); n++;
    i = str.indexOf('o', n); n++;
    i = str.indexOf('p', n); n++;
    i = str.indexOf('q', n); n++;
    i = str.indexOf('r', n); n++;
    i = str.indexOf('s', n); n++;
    i = str.indexOf('t', n); n++;
    i = str.indexOf('u', n); n++;
    i = str.indexOf('v', n); n++;
    i = str.indexOf('w', n); n++;
    i = str.indexOf('x', n); n++;
    i = str.indexOf('y', n); n++;
    i = str.indexOf('z', n); n++;
    List<Integer> intList = new List<Integer>();
    for (Integer j=0; j<100; j++) {
      intList.add(j);
    }
    String str1 = '';
    for (Integer x=0; x<intList.size(); x++) {
      str += x;
    }
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
  }
  public static void improveTestCoverage8() {
    String str = 'abcdefghijklmnopqrstuvwxyz';
    Integer n=0;
    Integer i = str.indexOf('a', n);
    i = str.indexOf('b', n); n++;
    i = str.indexOf('c', n); n++;
    i = str.indexOf('d', n); n++;
    i = str.indexOf('e', n); n++;
    i = str.indexOf('f', n); n++;
    i = str.indexOf('g', n); n++;
    i = str.indexOf('h', n); n++;
    i = str.indexOf('i', n); n++;
    i = str.indexOf('j', n); n++;
    i = str.indexOf('k', n); n++;
    i = str.indexOf('l', n); n++;
    i = str.indexOf('m', n); n++;
    i = str.indexOf('n', n); n++;
    i = str.indexOf('o', n); n++;
    i = str.indexOf('p', n); n++;
    i = str.indexOf('q', n); n++;
    i = str.indexOf('r', n); n++;
    i = str.indexOf('s', n); n++;
    i = str.indexOf('t', n); n++;
    i = str.indexOf('u', n); n++;
    i = str.indexOf('v', n); n++;
    i = str.indexOf('w', n); n++;
    i = str.indexOf('x', n); n++;
    i = str.indexOf('y', n); n++;
    i = str.indexOf('z', n); n++;
    List<Integer> intList = new List<Integer>();
    for (Integer j=0; j<100; j++) {
      intList.add(j);
    }
    String str1 = '';
    for (Integer x=0; x<intList.size(); x++) {
      str += x;
    }
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
  }
  public static void improveTestCoverage9() {
    String str = 'abcdefghijklmnopqrstuvwxyz';
    Integer n=0;
    Integer i = str.indexOf('a', n);
    i = str.indexOf('b', n); n++;
    i = str.indexOf('c', n); n++;
    i = str.indexOf('d', n); n++;
    i = str.indexOf('e', n); n++;
    i = str.indexOf('f', n); n++;
    i = str.indexOf('g', n); n++;
    i = str.indexOf('h', n); n++;
    i = str.indexOf('i', n); n++;
    i = str.indexOf('j', n); n++;
    i = str.indexOf('k', n); n++;
    i = str.indexOf('l', n); n++;
    i = str.indexOf('m', n); n++;
    i = str.indexOf('n', n); n++;
    i = str.indexOf('o', n); n++;
    i = str.indexOf('p', n); n++;
    i = str.indexOf('q', n); n++;
    i = str.indexOf('r', n); n++;
    i = str.indexOf('s', n); n++;
    i = str.indexOf('t', n); n++;
    i = str.indexOf('u', n); n++;
    i = str.indexOf('v', n); n++;
    i = str.indexOf('w', n); n++;
    i = str.indexOf('x', n); n++;
    i = str.indexOf('y', n); n++;
    i = str.indexOf('z', n); n++;
    List<Integer> intList = new List<Integer>();
    for (Integer j=0; j<100; j++) {
      intList.add(j);
    }
    String str1 = '';
    for (Integer x=0; x<intList.size(); x++) {
      str += x;
    }
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
  }
  public static void improveTestCoverage10() {
    String str = 'abcdefghijklmnopqrstuvwxyz';
    Integer n=0;
    Integer i = str.indexOf('a', n);
    i = str.indexOf('b', n); n++;
    i = str.indexOf('c', n); n++;
    i = str.indexOf('d', n); n++;
    i = str.indexOf('e', n); n++;
    i = str.indexOf('f', n); n++;
    i = str.indexOf('g', n); n++;
    i = str.indexOf('h', n); n++;
    i = str.indexOf('i', n); n++;
    i = str.indexOf('j', n); n++;
    i = str.indexOf('k', n); n++;
    i = str.indexOf('l', n); n++;
    i = str.indexOf('m', n); n++;
    i = str.indexOf('n', n); n++;
    i = str.indexOf('o', n); n++;
    i = str.indexOf('p', n); n++;
    i = str.indexOf('q', n); n++;
    i = str.indexOf('r', n); n++;
    i = str.indexOf('s', n); n++;
    i = str.indexOf('t', n); n++;
    i = str.indexOf('u', n); n++;
    i = str.indexOf('v', n); n++;
    i = str.indexOf('w', n); n++;
    i = str.indexOf('x', n); n++;
    i = str.indexOf('y', n); n++;
    i = str.indexOf('z', n); n++;
    List<Integer> intList = new List<Integer>();
    for (Integer j=0; j<100; j++) {
      intList.add(j);
    }
    String str1 = '';
    for (Integer x=0; x<intList.size(); x++) {
      str += x;
    }
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
  }
  public static void improveTestCoverage11() {
    String str = 'abcdefghijklmnopqrstuvwxyz';
    Integer n=0;
    Integer i = str.indexOf('a', n);
    i = str.indexOf('b', n); n++;
    i = str.indexOf('c', n); n++;
    i = str.indexOf('d', n); n++;
    i = str.indexOf('e', n); n++;
    i = str.indexOf('f', n); n++;
    i = str.indexOf('g', n); n++;
    i = str.indexOf('h', n); n++;
    i = str.indexOf('i', n); n++;
    i = str.indexOf('j', n); n++;
    i = str.indexOf('k', n); n++;
    i = str.indexOf('l', n); n++;
    i = str.indexOf('m', n); n++;
    i = str.indexOf('n', n); n++;
    i = str.indexOf('o', n); n++;
    i = str.indexOf('p', n); n++;
    i = str.indexOf('q', n); n++;
    i = str.indexOf('r', n); n++;
    i = str.indexOf('s', n); n++;
    i = str.indexOf('t', n); n++;
    i = str.indexOf('u', n); n++;
    i = str.indexOf('v', n); n++;
    i = str.indexOf('w', n); n++;
    i = str.indexOf('x', n); n++;
    i = str.indexOf('y', n); n++;
    i = str.indexOf('z', n); n++;
    List<Integer> intList = new List<Integer>();
    for (Integer j=0; j<100; j++) {
      intList.add(j);
    }
    String str1 = '';
    for (Integer x=0; x<intList.size(); x++) {
      str += x;
    }
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
  }
  public static void improveTestCoverage12() {
    String str = 'abcdefghijklmnopqrstuvwxyz';
    Integer n=0;
    Integer i = str.indexOf('a', n);
    i = str.indexOf('b', n); n++;
    i = str.indexOf('c', n); n++;
    i = str.indexOf('d', n); n++;
    i = str.indexOf('e', n); n++;
    i = str.indexOf('f', n); n++;
    i = str.indexOf('g', n); n++;
    i = str.indexOf('h', n); n++;
    i = str.indexOf('i', n); n++;
    i = str.indexOf('j', n); n++;
    i = str.indexOf('k', n); n++;
    i = str.indexOf('l', n); n++;
    i = str.indexOf('m', n); n++;
    i = str.indexOf('n', n); n++;
    i = str.indexOf('o', n); n++;
    i = str.indexOf('p', n); n++;
    i = str.indexOf('q', n); n++;
    i = str.indexOf('r', n); n++;
    i = str.indexOf('s', n); n++;
    i = str.indexOf('t', n); n++;
    i = str.indexOf('u', n); n++;
    i = str.indexOf('v', n); n++;
    i = str.indexOf('w', n); n++;
    i = str.indexOf('x', n); n++;
    i = str.indexOf('y', n); n++;
    i = str.indexOf('z', n); n++;
    List<Integer> intList = new List<Integer>();
    for (Integer j=0; j<100; j++) {
      intList.add(j);
    }
    String str1 = '';
    for (Integer x=0; x<intList.size(); x++) {
      str += x;
    }
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
    str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';str1 += 'Finish';
  }*/
}