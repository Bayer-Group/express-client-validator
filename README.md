# Client Validator for Express routes

The purpose of this module is to be plugged in as a middleware when an app needs to validate the requests are coming from allowable clients. 
 

Install the module

    npm install save express-client-validator

## Usage

    RouteClientValidator = require 'express-client-validator'
    {validator} = RouteClientValidator

#### Initialize the restricted routes and pass it to the validator during configuration
```
e.g.
routes = [
    {
        url : '/'
        methods : ['GET','PUT','POST','DELETE']
        clientIds :  ['CLIENT-A']            
    }
    {
        url : '/route-1/?'
        methods : ['GET','PUT','POST','DELETE']
        clientIds :  ['CLIENT-A','CLIENT-C']            
    }
]
```
The middleware takes in a list of restricted routes which means the client is free to choose the store for its route definitions. E.g. it could be stored either in a database, or as part of CF service bindings or maybe a bundled json in the app  
1. Below configuration will use the default `client-id` as the header param to lookup in the request e.g. 
    
    `RouteClientValidator.configure({routes})`

2. If the clientId is stored in a custom header you can pass it as `headerClientKey` during config e.g. 
    
    `RouteClientValidator.configure({headerClientKey:'custom_client_id', routes})`
    
#### Configure the middleware
Given `app` is the express router, the `validator` can be configured as below 

```
app.use '/', validator
```

Fire up the app and now all the routes would be validated as per the restrictions defined during configuration

### Routes are 
The list of routes should contain at least one route definition

| property | validations |
| :------- | :---------- |
| url | has to be non empty string |
| method | should be a string array containing at least one http method e.g. ['GET','PUT'] etc. |
| clientIds | should be a list of client ids that are allowed for the given url. If the endpoint needs to be open for all leave it as empty array [] | 


### How to define routes
| url | method | cliendIds | What does it mean | 
| :-- | :----- | :-------- | :---------------- |
| /route-1 | ['PUT','POST','DELETE'] | ['CLIENT-A'] | Only client CLIENT-A is allowed to call `/route-1` *POST, PUT, DELETE* routes |
| /route-1 | ['GET'] | [ ] | All clients can call the `/route-1` *GET* endpoint |
| / | ['GET','HEAD','PUT','POST','DELETE'] | ['CLIENT-B'] | Only client CLIENT-B is allowed to call `/` *GET, HEAD, POST, PUT, DELETE* routes |  

Note: The restricted routes are evaluated by matching from distinct to partial matches.

e.g. in the above table since client `CLIENT-B` is allowed for `/` means an endpoint like `/route-2` is allowed to `CLIENT-B`
but not any other clients

however `CLIENT-B` will not be allowed to call `/route-1` endpoint since it is restricted to client `CLIENT-A`

If CLIENT-B needs to access `/route-1` as well then it needs to be explicitly defined      

e.g
```
routes = [
    {
        url : '/route-1'
        methods : ['PUT','POST','DELETE']
        clientIds :  ['CLIENT-A','CLIENT-B']            
    }
]
```

URL path params can be specified with a `?` which the validator will replace with this regex `([-A-z0-9@:%$_\+.~#])+` for pattern matching
```
e.g. defining a route url like below 
routes = [
    {
        url : '/route-1/?/child-route'
        ...
    }
]

will match request with urls like

/route-1/xyz/child-route
/route-1/1234/child-route
/route-1/xyz-00$1/child-route

```

Query params are automatically handled by the validator by matching using this regex `([-A-z0-9\/?@:%$_&=\+.~#])*`



