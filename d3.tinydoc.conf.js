var path = require('path');
var config = {
  title: 'd3',
  outputDir: '/srv/http/docs/d3',
  assetRoot: path.resolve(__dirname, 'd3'),
  tooltipPreviews: false,
  layoutOptions: {
    rewrite: {
      '/api/readme.html': '/index.html',
    },
  }
};

config.plugins = [
  require('megadoc-plugin-markdown')({
    id: 'api',
    sanitize: false,
    // normalizeHeadings: false,

    source: [
      'README.md',
      'node_modules/d3-*/**/*.md',
    ],

    exclude: [ /\.test\.js$/ ],
  }),

  require('megadoc-theme-qt')({}),

  {
    run: function(compiler) {
      var Corpus = require('megadoc-corpus').Corpus;
      var b = require('megadoc-corpus').builders;
      var utils = require('megadoc/lib/RendererUtils');
      var fs = require('fs');

      compiler.on('scan', function(done) {
        compiler.corpus.get('api').documents.forEach(function(documentNode) {
          var source = documentNode.properties.source;

          documentNode.meta.corpusContext = documentNode.title;

          var newSource =source.split('\n').map(function(line) {
            if (line.match(/^\<a (href|name)="([^"]+)"/)) {
              var text = utils.htmlToText(line).replace(/^#\s*/, '');
              var name = utils.markdownToText(line).trim().replace(/^#\s*/, '').replace(/[\[\(].+?[\]\)]$/, '');
              var id = utils.normalizeHeading(text);
              var entity = b.documentEntity({
                id: id,
                title: name,
                meta: {
                  anchor: id,
                  indexDisplayName: '        ' + name,
                },
                properties: {
                  id: id,
                  scopedId: id,
                  level: 4,
                  text: name,
                  html: text,
                }
              });

              Corpus.attachNode('entities', documentNode, entity);
              compiler.corpus.add(entity);

              // console.log('attaching "%s" to "%s" as "%s"', entity.uid, documentNode.uid, name);

              return '#### ' + text + '\n';
            }
            else {
              return line;
            }
          }).join('\n');

          documentNode.properties.source = newSource;
        });

        done();
      })
    }
  }
];

module.exports = config;