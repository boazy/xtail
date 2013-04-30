require! browserify
rack   = require 'asset-rack'
uglify = require 'uglify-js'

class exports.BrowserifyAsset extends rack.Asset
    mimetype: 'text/javascript'

    create: !({ @filename, @require, @debug or false, @compress or false, @transforms or [], create }) ->
        creator = create or browserify
        agent = creator!
        for transform in @transforms
            agent.transform transform
            
        agent.add @filename
        agent.bundle debug: @debug, (err, bundled) ~>
            throw err if err
            if @compress is true
                @contents = uglify.minify(bundled, from-string: true).code
                @emit 'created'
            else
                @contents = bundled
                @emit 'created'
