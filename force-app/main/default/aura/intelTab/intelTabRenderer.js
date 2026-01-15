({
   /* afterRender: function(component, helper) {
         this.superAfterRender();
        var path = window.location.pathname;
        var pathParts = path.split('/');
        var highlightBox = pathParts[pathParts.length - 1];
        console.log({highlightBox});
                     console.log({path});
        
        console.log(elementToHighlight+'sdfasd');
        elementToHighlight.getElement().style.backgroundColor = "yellow";          
        console.log('hello='+elementToHighlight.getElement());
         
 
    }*/
    checkVisitedFromAnchor: function() {
        // Get the URL of the previous page
        const tabToHighlight = localStorage.getItem('highlightTab');
        console.log({tabToHighlight});
        
        // Get the ID of the anchor tag from the previous page
        var anchorId = 'myAnchor';
        
        // Check if the previous page's URL contains the anchor ID
        if (referrer.indexOf(anchorId) !== -1) {
          // Set the background color of the desired div
          var div = document.getElementById('myDiv');
          div.style.backgroundColor = 'yellow';
        }
    },
    
     afterRender: function(component, helper) {
         this.superAfterRender();
         console.log('test outer');
         // checkVisitedFromAnchor();
         const tabToHighlight = localStorage.getItem('highlightTab');
         const tabToHighlightt = localStorage.getItem('17');
        console.log({tabToHighlight});
                     console.log({tabToHighlightt});
                     
                      for (let i = 0; i < localStorage.length; i++) {
            const key = localStorage.key(i);
                     console.log(typeof key)
            const value = localStorage.getItem(""+key);
            console.log(key, value);
        }
       /*var referrer = document.referrer;
         console.log(referrer.indexOf(anchorId)+'kkk');
       var anchorId = 'url';
   
        if(referrer.indexOf(anchorId) !== -1){
            console.log('testing inside');
            var div = document.getElementById('highlightedText');
            div.style.backgroundColor = 'yellow';
        }
     
        // window.onload = handleLinkClick;
        */
    }
})