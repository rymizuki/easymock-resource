"use strict"

expect = require "expect.js"
sinon  = require "sinon"

Q = require "q"

resource = require "../../src/easymock/resource.coffee"

describe "easymock-resource", ->
  describe "init", ->
    constr  = null
    execute = null
    beforeEach ->
      execute = sinon.spy(resource.Resource.prototype, "execute")
    afterEach ->
      execute.restore()

    beforeEach ->
      resource.init({ configFile: "test/fixture/config.cson", variation: "not_exists" })

    it "should be called execute", ->
      expect(execute.calledOnce).to.be.ok()
      expect(execute.args[0][0]).to.be.eql("not_exists")

  describe "Resource", ->
    Resource = null
    beforeEach ->
      Resource = resource.Resource

    describe "defaultOptions", ->
      it "should not have property", ->
        expect(Resource.defaultOptions).to.have.property("configFile", "easymock-resource.config.json")

    describe "initialize", ->
      ensureOptions = null
      beforeEach ->
        ensureOptions = sinon.spy(Resource.prototype, "ensureOptions")
      afterEach ->
        ensureOptions.restore()

      options = null
      beforeEach ->
        options = { configFile: "test.config.json" }
        new Resource(options)

      it "should call 'ensureOptions' method", ->
        expect(ensureOptions.calledOnce).to.be.ok()
        expect(ensureOptions.args[0][0]).to.be.eql options

    describe "ensureOptions", ->
      instance = null
      options  = null
      beforeEach ->
        options = { configFile: "test.config.json" }
        instance = new Resource(options)
      it "should extend defaultOptions", ->
        expect(instance.options).to.be.eql options

    describe "execute", ->
      instance = null
      options  = null
      beforeEach ->
        options = { configFile: "test/fixture/config.cson" }
        instance = new Resource(options)

      loadConfig      = null
      readVariations  = null
      resourceProcess = null
      formatArgs      = null
      beforeEach ->
        loadConfig      = sinon.spy instance, "loadConfig"
        readVariations  = sinon.spy instance, "readVariations"
        resourceProcess = sinon.spy instance, "resourceProcess"
        formatArgs      = sinon.spy instance, "formatArgs"
      afterEach ->
        loadConfig.restore()
        readVariations.restore()
        resourceProcess.restore()
        formatArgs.restore()

      beforeEach ->
        instance.execute()

      it "should call loadConfig", ->
        expect(loadConfig.calledOnce).to.be.ok()
      it "should call readVariations", ->
        expect(readVariations.calledOnce).to.be.ok()
      it "should call resourceProcess", ->
        expect(resourceProcess.calledOnce).to.be.ok()
      it "should call formatArgs", ->
        expect(formatArgs.calledOnce).to.be.ok()

    describe "loadConfig", ->
      describe "configFile", ->
        options  = null
        instance = null
        beforeEach ->
          options = { configFile: "test/fixture/config.cson" }
          instance = new Resource(options)

        promise = null
        beforeEach ->
          promise = instance.loadConfig(instance.options.configFile)

        it "should return promise object", ->
          expect(Q.isPromise promise).to.be.ok()
        it "should have property dest", (done) ->
          promise.then ->
            expect(instance.config).to.have.property("dest", "test/.temp/")
            done()
        it "should have property variations", (done) ->
          promise.then ->
            expect(instance.config).to.have.property("variations")
            expect(instance.config.variations).to.be.eql {
              default:    [ "api/*.default.json"    ]
              not_exists: [ "api/*.not_exists.json" ]
            }
            done()

      describe "config", ->
        options  = null
        instance = null
        beforeEach ->
          options =
            config:
              cwd:  "test/fixture/"
              dest: "test/.temp/"
              variations:
                default:    "api/*.default.json"
                not_exists: "api/*.not_exists.json"

          instance = new Resource(options)

        promise = null
        beforeEach ->
          promise = instance.loadConfig(instance.options.config)
          null

        it "should return promise object", ->
          expect(Q.isPromise promise).to.be.ok()
        it "should have property dest", (done) ->
          promise.then ->
            expect(instance.config).to.have.property("dest", "test/.temp/")
            done()
        it "should have property variations", (done) ->
          promise.then ->
            expect(instance.config).to.have.property("variations")
            expect(instance.config.variations).to.be.eql {
              default:    "api/*.default.json"
              not_exists: "api/*.not_exists.json"
            }
            done()

    describe "readVariations", ->
      options  = null
      instance = null
      beforeEach (done) ->
        options = { configFile: "test/fixture/config.cson" }
        instance = new Resource(options)
        instance.loadConfig(instance.options.configFile)
          .done -> done()

      describe "exists variation", ->
        variation = null
        promise   = null
        beforeEach ->
          variation = "default"
          promise = instance.readVariations(variation)

        it "should be return promise object", ->
          expect(Q.isPromise promise).to.be.ok()
        it "should be resolve with variation files", (done) ->
          promise.done (files) ->
            expect(files).to.be.eql [
                src: [ "test/fixture/api/example.default.json" ]
                dest: "test/.temp/api/example.json"
              ,
            ]
            done()

      describe "not exists variation", ->
        variation = null
        promise   = null
        beforeEach ->
          variation = "xxxxxxx"
          promise = instance.readVariations(variation)
          null

        it "should be return promise object", ->
          expect(Q.isPromise promise).to.be.ok()
        it "should be rejected promise", (done) ->
          promise.fail (err) ->
            expect(err).to.be.eql(new Error "'xxxxxxx' is not exists in variations.")
            done()

    describe "resourceProcess", ->
      rimraf = null
      copy   = null
      mkdir  = null
      beforeEach ->
        copy   = sinon.stub(require("file-utils"), "copy")
        mkdir  = sinon.stub(require("file-utils"), "mkdir")
        rimraf = sinon.stub(require("rimraf"), "sync")
      afterEach ->
        copy.restore()
        mkdir.restore()
        rimraf.restore()

      files    = null
      options  = null
      instance = null
      beforeEach ->
        options = { configFile: "test/fixture/config.cson" }
        instance = new Resource(options)

        files = [
            dest: "test/.temp/"
            src: [ "api/example_1.json" ]
          ,
            dest: "test/.temp/"
            src: [ "api/example_2.json" ]
          ,
            dest: "test/.temp/"
            src: [ "api/example_3.json" ]
          ,
            dest: "test/.temp/"
            src: [ "api/example_4.json" ]
          ,
            dest: "test/.temp/"
            src: [ "api/example_5.json", "api/example_6.json" ]
        ]
        instance.resourceProcess(files)

      it "should be call file-utils.copy", ->
        expect(copy.callCount).to.be.eql 6
      it "should be call rimraf", ->
        expect(rimraf.callCount).to.be files.length
      it "should be call mkdir", ->
        expect(mkdir.callCount).to.be files.length

    describe "formatArgs", ->
      options  = null
      instance = null
      beforeEach ->
        options =
          config:
            dest: "test/.temp"
            routes: [
              "/api/user/:id"
            ]
            variables:
              server: "http://localhost:8080/"
        instance = new Resource(options)
        instance.loadConfig(options.config)

      it "should be return promise", ->
        expect(Q.isPromise instance.formatArgs()).to.be.ok()
      it "should be resolve config has path", (done) ->
        instance.formatArgs().then (args) ->
          expect(args).to.have.property('path', options.config.dest)
          done()
      it "should be resolve config has config", (done) ->
        instance.formatArgs().then (args) ->
          expect(args).to.have.property('config')
          expect(args.config).to.be.eql {
            routes:    options.config.routes
            variables: options.config.variables
          }
          done()

