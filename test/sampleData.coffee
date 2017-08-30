module.exports = [
    {
        url : '/'
        methods : ['GET','PUT','POST','DELETE']
        clientIds :  ['CLIENT-2']            
    }
    {
        url : '/route-1/?'
        methods : ['PUT','POST','DELETE']
        clientIds :  ['CLIENT-1']            
    }
    {
        url : '/route-1'
        methods : ['PUT','POST','DELETE']
        clientIds :  ['CLIENT-1']            
    }
    {
        url : '/route-2'
        methods : ['GET']
        clientIds :  ['CLIENT-3']            
    }
    {
        url : '/route-3/?'
        methods : ['PUT','POST','DELETE']
        clientIds :  ['CLIENT-1']            
    }
    {
        url : '/route-3/?'
        methods : ['GET']
        clientIds :  ['CLIENT-1','CLIENT-2']            
    }
    {
        url : '/route-3/?/child-route/?' 
        methods : ['PUT','POST','DELETE']
        clientIds :  ['CLIENT-1']            
    }
    {
        url : '/route-4' 
        methods : ['GET']
        clientIds :  []            
    }

]