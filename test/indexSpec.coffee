RouteClientValidator = require "../src/index"
_ = require('underscore')

describe "route client validator",->
    {sandbox, req, res, next} = {}
    beforeEach ->
        sandbox = sinon.sandbox.create()
        res = 
            status : sandbox.stub()
            send : sandbox.stub()
        next = sandbox.stub()

    afterEach -> 
        sandbox.restore()

    describe "route setup",->
        {route} = {}
        beforeEach ->
            route = 
                url : "/route-3/?"
                methods : ["PUT","POST","DELETE"]
                clientIds :  ["CLIENT-1"]                    

        setupAndRunTest = (routes, errorMessage)->
            RouteClientValidator.configure({headerClientKey:'client_id', routes})
            .then (msg)->
                should.fail(errorMessage)
            .catch (error)->    
                error.message.should.eql(errorMessage)

        describe "throws error", ->

            it "when no routes are configured", ->
                setupAndRunTest(undefined,"restricted routes list need to be provided")

            it "when empty routes are configured", ->
                setupAndRunTest([],"should NOT have less than 1 items")

            it "when route has a missing url property", ->
                delete route.url
                setupAndRunTest([route],"/0 should have required property 'url'")

            it "when route has a missing methods property", ->
                delete route.methods
                setupAndRunTest([route],"/0 should have required property 'methods'")

            it "when route has a missing clientIds property", ->
                delete route.clientIds
                setupAndRunTest([route],"/0 should have required property 'clientIds'")

            it "when route url property is empty", ->
                route.url = ''
                setupAndRunTest([route],"/0/url should NOT be shorter than 1 characters")

            it "when route methods property is emtpy", ->
                route.methods = []
                setupAndRunTest([route],"/0/methods should NOT have less than 1 items")

            it "when route method property is not strings", ->
                route.methods = [0]
                setupAndRunTest([route],"/0/methods/0 should be string")

            it "when route clientIds property is not strings", ->
                route.clientIds = [0]
                setupAndRunTest([route],"/0/clientIds/0 should be string")

        describe 'success', ->
            setupAndRunSuccessTest = (routes)->
                RouteClientValidator.configure({headerClientKey:'client_id', routes})
                .then (msg)->
                    msg.should.eql('routes configured')
                .catch (error)->
                    should.fail(error.message)    

            it 'to have empty client ids', ->
                route.clientIds = []
                setupAndRunSuccessTest([route],"/0/clientIds/0 should be string")            

    describe "route validation",->
        {validator,req,routes} = {}
        
        beforeEach ->
            routes = require "./sampleData"

        configure = (clientId, appRoutes = routes)->
            RouteClientValidator.configure({headerClientKey:clientId, routes: appRoutes})
            {validator} = RouteClientValidator
            clientKey = if clientId then clientId else 'client-id'
            req = 
                originalUrl : "/route-3/AVENGERS"
                method : "PUT"    
                headers : {}
            
            req.headers[clientKey] = "CLIENT-1"    

        success = (res,next)->
            res.status.should.not.have.been.called
            res.send.should.not.have.been.called
            next.should.have.been.called   

        failure = (res,next)->
            res.status.should.have.been.calledWithExactly 403
            res.send.should.have.been.calledWithExactly "Invalid Client"
            next.should.not.have.been.called

        setupAndAssert=(req,assert)->

            validator(req,res,next)
            assert(res,next)     

        describe "using default client header" , ->    
            beforeEach ->
                configure()

            describe "success when client is valid and route", ->
                it 'matches exactly', ->
                    req.originalUrl = "/route-3/AVENGERS/child-route/123"
                    setupAndAssert(req,success)

                it 'matches exactly with special characters', ->
                    req.originalUrl = "/route-3/AVENGERS$1/child-route/123"
                    setupAndAssert(req,success)

                it 'matches partially', ->
                    req.originalUrl = "/route-3/AVENGERS/user"
                    setupAndAssert(req,success)
                
                it 'matches till root', ->
                    req.originalUrl = "/app/AVENGERS/user"
                    req.headers['client-id'] =  "CLIENT-2"  
                    setupAndAssert(req,success)

                it 'no route matched till the root',->
                    newRoutes = _(routes).clone()
                    newRoutes.shift()
                    configure(null, newRoutes)
                    req.originalUrl = "/app/AVENGERS/user"
                    req.headers['client-id'] =  "CLIENT-2"
                    setupAndAssert(req,success)

            describe "success when client is not provided and", ->
                it 'the route is open to all',->
                    req.originalUrl = "/route-4"
                    req.method = 'GET'
                    req.headers['client-id'] =  undefined
                    setupAndAssert(req,success)  

            describe "success different client and route", ->
                beforeEach ->
                    req.method = 'GET'
                    req.headers['client-id'] =  'CLIENT-3'
                    
                it 'matches exactly', ->
                    req.originalUrl = "/route-2"
                    setupAndAssert(req,success)
                it 'matches exactly with route ending with /', ->
                    req.originalUrl = "/route-2/"
                    setupAndAssert(req,success)
                it 'matches exactly with route ending with query params', ->
                    req.originalUrl = "/route-2?a=123&b=456"
                    setupAndAssert(req,success)
                it 'matches exactly with route ending / and query params', ->
                    req.originalUrl = "/route-2/?a=123&b=456"
                    setupAndAssert(req,success)


            describe 'forbidden when client is invalid and route',->
                beforeEach ->
                    req.headers["client-id"] = "BAD-CLIENT"

                it "matches exactly",->   
                    setupAndAssert(req,failure)

                it 'matches partially', ->
                    req.originalUrl = "/route-3/AVENGERS/user"
                    setupAndAssert(req,failure)
                
                it 'matches till root', ->
                    req.originalUrl = "/random-route/AVENGERS/random-child-route"
                    setupAndAssert(req,failure)

        describe "using custom client header" , ->    
            beforeEach ->
                configure("my_client_header")

            describe "success when client is valid and route", ->
                it 'matches exactly', ->
                    setupAndAssert(req,success)

                it 'matches partially', ->
                    req.originalUrl = "/route-3/AVENGERS/random-child-route"
                    setupAndAssert(req,success)

                it 'matches till root', ->
                    req.originalUrl = "/app/AVENGERS/random-child-route"
                    req.headers['my_client_header'] =  "CLIENT-2"
                    setupAndAssert(req,success)

                it 'no route matched till the root',->
                    newRoutes = _(routes).clone()
                    newRoutes.shift()
                    configure("my_client_header", newRoutes)
                    req.originalUrl = "/app/AVENGERS/random-child-route"
                    setupAndAssert(req,success)

            describe 'forbidden when client is invalid and route',->
                beforeEach ->
                    req.headers["my_client_header"] = "BAD-CLIENT"

                it "matches exactly",->   
                    setupAndAssert(req,failure)

                it 'matches partially', ->
                    req.originalUrl = "/route-3/AVENGERS/random-child-route"
                    setupAndAssert(req,failure)
                
                it 'matches till root', ->
                    req.originalUrl = "/app/AVENGERS/random-child-route"
                    setupAndAssert(req,failure)

