_ = require('underscore')
schema = require './schema'
Ajv = require 'ajv'
appRoutes = []
clientKey = undefined
defaultClientKey = 'client-id'
queryParamPattern = '([-A-z0-9\/?@:%$_&=\+.~#])*'
matchPattern = '([-A-z0-9@:%$_\+.~#])+'


findMatchingRoute = (url, method)->
    matchedRoute = appRoutes.find (route)->
        pattern = route.url.replace(/\?/g,matchPattern) + queryParamPattern
        new RegExp(pattern).test(url) and method in route.methods

    if not matchedRoute
        matchUrl = if url.lastIndexOf('/') > 0 then url.slice(0,url.lastIndexOf('/')) else "/"
        if url isnt matchUrl then findMatchingRoute(matchUrl, method) else matchedRoute
    else
        matchedRoute

clientIdHasAccess = (clientId, originalUrl, method = 'POST') ->
    route = findMatchingRoute(originalUrl, method)
    not route or route.clientIds.length is 0 or clientId in route.clientIds

validator = (req,res,next)->
    if clientIdHasAccess(req.headers[clientKey], req.originalUrl, req.method)
        next()
    else
        res.status(403)
        res.send("Invalid Client")

validateSchema = (restrictedRoutes)->
    if not restrictedRoutes
        throw new Error('restricted routes list need to be provided')

    ajv = Ajv({allErrors: true, jsonPointers: true, missingRefs: false })
    validate = ajv.compile(schema)
    data = validate(restrictedRoutes)
    if validate.errors
        messages = validate.errors.map (error)->"#{error.dataPath} #{error.message}".trim()
        throw new Error(messages)

configure = ({headerClientKey,routes})->
    clientKey = if headerClientKey then headerClientKey else defaultClientKey
    try
        validateSchema(routes)
        appRoutes = _(routes).sortBy('url').reverse()
        Promise.resolve("routes configured")
    catch errors
        Promise.reject(errors)

module.exports = {validator,configure,clientIdHasAccess,findMatchingRoute}



