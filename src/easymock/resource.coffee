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
    when ".json" then JSON.parse(futil.readFile filepath)
    else
      throw new Error("Unsupported extension '#{ ext }'")

class Resource
  @defaultOptions: {}

  constructor: (options={}) ->
    @ensureOptions(options)

  ensureOptions: (options) ->
    @options = _.defaults options, Resource.defaultOptions

  execute: (variation="default") ->
    @loadConfig(@options.configFile)
      .then         => @readVariations(variation)
      .then (files) => @resourceProcess(files)
      .fail (err) => console.log(err)

  loadConfig: (filepath) ->
    Q.fcall =>
      @config = loadFile(filepath)

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

resource = module.exports = {}

resource.Resource = Resource
resource.init = (args) ->
  new Resource({ configFile: args.configFile }).execute(args.variation)

