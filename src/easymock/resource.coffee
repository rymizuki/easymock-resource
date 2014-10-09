"use strict"

Q = require "q"
_ = require "lodash"

path   = require "path"
rimraf = require "rimraf"
futil  = require "file-utils"
CSON   = require "cson"

loadFile = (filepath, ext) ->
  ext || ext = path.extname(filepath)
  unless futil.exists(filepath)
    throw new Error("File not exists '#{ filepath }'.")
  switch ext
    when ".cson" then CSON.parseFileSync(filepath)
    when ".json" then JSON.parse(futil.read filepath)
    else
      throw new Error("Unsupported extension '#{ ext }'")

class Resource
  @defaultOptions:
    configFile: "easymock-resource.config.json"

  constructor: (options={}) ->
    @ensureOptions(options)

  ensureOptions: (options) ->
    @options = _.defaults options, Resource.defaultOptions

  execute: (variation="default") ->
    @loadConfig(if @options.config then @options.config else @options.configFile)
      .then         => @readVariations(variation)
      .then (files) => @resourceProcess(files)
      .then         => @formatArgs()
      .fail (err) => console.log(err)

  loadConfig: (config) ->
    self = @
    Q.fcall =>
      self.config = if _.isString(config) then loadFile(config) else config

  readVariations: (variation) ->
    deferred = Q.defer()

    variationMap = @config.variations
    if variationMap[variation]
      src = variationMap[variation]
      src.unshift(variationMap.default) unless variation is "default"

      files = futil.expandMapping src, @config.dest,
        cwd: @config.cwd || "."
        ext: ".json"
      deferred.resolve(files)
    else
      deferred.reject(new Error "'#{ variation }' is not exists in variations.")

    deferred.promise

  resourceProcess: (files) ->
    files.forEach (file) ->
      dest = file.dest
      rimraf.sync(dest)
      futil.mkdir(path.dirname dest)
      file.src.forEach (source) ->
        futil.copy(source, dest)

  formatArgs: ->
    self = @
    Q.fcall ->
      config = self.config
      dest = config.dest

      delete config.cwd
      delete config.dest
      delete config.variations

      return {
        path:   dest
        config: config
      }

resource = module.exports = {}

resource.Resource = Resource
resource.init = (args) ->
  new Resource({ configFile: args.configFile }).execute(args.variation)

