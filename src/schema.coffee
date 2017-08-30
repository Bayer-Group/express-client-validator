module.exports =
    type: 'array'
    minItems : 1
    items:
        type : 'object'
        required: ["url", "methods","clientIds"]
        properties:
            url:
                description: 'the url pattern to restrict'
                type: 'string'
                minLength : 1
            methods:
                description: 'a list of methods that are supported. e.g. GET, PUT'
                type: 'array'
                items:
                    type: 'string'
                minItems: 1    
            clientIds:
                description: 'a list of client ids that are supported.'
                type: 'array'
                items:
                    type: 'string'
