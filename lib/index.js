// Generated by CoffeeScript 2.5.1
(function() {
  var Ajv, _, appRoutes, clientIdHasAccess, clientKey, configure, defaultClientKey, findMatchingRoute, matchPattern, queryParamPattern, schema, validateSchema, validator,
    indexOf = [].indexOf;

  _ = require('underscore');

  schema = require('./schema');

  Ajv = require('ajv');

  appRoutes = [];

  clientKey = void 0;

  defaultClientKey = 'client-id';

  queryParamPattern = '([-A-z0-9\/?@:%$_&=\+.~#])*';

  matchPattern = '([-A-z0-9@:%$_\+.~#])+';

  findMatchingRoute = function(url, method) {
    var matchUrl, matchedRoute;
    matchedRoute = appRoutes.find(function(route) {
      var pattern;
      pattern = route.url.replace(/\?/g, matchPattern) + queryParamPattern;
      return new RegExp(pattern).test(url) && indexOf.call(route.methods, method) >= 0;
    });
    if (!matchedRoute) {
      matchUrl = url.lastIndexOf('/') > 0 ? url.slice(0, url.lastIndexOf('/')) : "/";
      if (url !== matchUrl) {
        return findMatchingRoute(matchUrl, method);
      } else {
        return matchedRoute;
      }
    } else {
      return matchedRoute;
    }
  };

  clientIdHasAccess = function(clientId, originalUrl, method = 'POST') {
    var route;
    route = findMatchingRoute(originalUrl, method);
    return !route || route.clientIds.length === 0 || indexOf.call(route.clientIds, clientId) >= 0;
  };

  validator = function(req, res, next) {
    if (clientIdHasAccess(req.headers[clientKey], req.originalUrl, req.method)) {
      return next();
    } else {
      res.status(403);
      return res.send("Invalid Client");
    }
  };

  validateSchema = function(restrictedRoutes) {
    var ajv, data, messages, validate;
    if (!restrictedRoutes) {
      throw new Error('restricted routes list need to be provided');
    }
    ajv = Ajv({
      allErrors: true,
      jsonPointers: true,
      missingRefs: false
    });
    validate = ajv.compile(schema);
    data = validate(restrictedRoutes);
    if (validate.errors) {
      messages = validate.errors.map(function(error) {
        return `${error.dataPath} ${error.message}`.trim();
      });
      throw new Error(messages);
    }
  };

  configure = function({headerClientKey, routes}) {
    var errors;
    clientKey = headerClientKey ? headerClientKey : defaultClientKey;
    try {
      validateSchema(routes);
      appRoutes = _(routes).sortBy('url').reverse();
      return Promise.resolve("routes configured");
    } catch (error1) {
      errors = error1;
      return Promise.reject(errors);
    }
  };

  module.exports = {validator, configure, clientIdHasAccess, findMatchingRoute};

}).call(this);
