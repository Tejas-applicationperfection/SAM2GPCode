/*
 * MultiselectController synchronizes the values of the hidden elements to the
 * SelectOption lists.
 */
public with sharing class MultiselectController {
    // SelectOption lists for public consumption
    public SelectOption[] leftOptions { get; set; }
    public SelectOption[] leftOptions1 { get; set; }
    public SelectOption[] rightOptions { get; set; }
    public boolean disableComponent { get; set; }
    // Parse &-separated values and labels from value and 
    // put them in option
    @TestVisible
    private void setOptions(SelectOption[] options, SelectOption[] options1, String value) {
        System.debug('options:::' + options);
        options.clear();
        if (options1 != null) {
        	options1.clear();
        }
        System.debug('value:::' + value);
        String[] parts = value.split('&');
        Integer j = 0;
        for (Integer i=0; i<parts.size()/2; i++) {
        	if (j < 900) {
            	options.add(new SelectOption(EncodingUtil.urlDecode(parts[i*2], 'UTF-8'), 
            							 EncodingUtil.urlDecode(parts[(i*2)+1], 'UTF-8')));
        	} else {
        		options1.add(new SelectOption(EncodingUtil.urlDecode(parts[i*2], 'UTF-8'), 
            							 EncodingUtil.urlDecode(parts[(i*2)+1], 'UTF-8')));
        	}
        	j++;
        }
       
        system.debug('options:::' + options.size());
        system.debug('options1:::' + options1);
        if (options1 != null) {
        	system.debug('options1:::' + options1.size());
        }
    }
    
    // Backing for hidden text field containing the options from the
    // left list
    public String leftOptionsHidden { 
        get; 
        set {
           leftOptionsHidden = value;
           setOptions(leftOptions, leftOptions1, value);
        }
    }
    
    
    // Backing for hidden text field containing the options from the
    // right list
    public String rightOptionsHidden { 
        get; 
        set {
           rightOptionsHidden = value;
           setOptions(rightOptions, null, value);
        }
    }
}