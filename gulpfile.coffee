"use strict"

gulp = require "gulp"
coffeelint = require "gulp-coffeelint"
mocha      = require "gulp-mocha"

gulp.task "app", ->
  gulp.src("src/**/*.coffee", {read: false})
    .pipe coffeelint()
    .pipe coffeelint.reporter()

gulp.task "test", ->
  gulp.src("test/**/*.coffee", {read: false})
    .pipe coffeelint()
    .pipe coffeelint.reporter()
    .pipe mocha({ui: "bdd", reporter: "spec"})

gulp.task "default", ->
  gulp.watch ["src/**/*.coffee"], ["app"]
  gulp.watch ["test/**/*.coffee"], ["test"]
