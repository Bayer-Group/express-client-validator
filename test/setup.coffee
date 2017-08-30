chai = require 'chai'
global.should = chai.should()
chai.use require('chai-as-promised')
chai.use require('sinon-chai')
global.sinon = require 'sinon'
require 'sinon-as-promised'