var path = require('path');
var config = {
  title: 'orientjs',
  outputDir: '/srv/http/docs/orientjs',
  assetRoot: path.resolve(__dirname, 'orientjs'),
  tooltipPreviews: false,
  layoutOptions: {
    rewrite: {
      '/articles/readme.html': '/index.html',
    },

    bannerLinks: [
      {
        text: 'API',
        href: '/api',
      },
    ]
  }
};

config.plugins = [
  require('megadoc-plugin-js')({
    id: 'api',
    source: 'lib/**/*.js',
    exclude: [ /\.test\.js$/, /vendor/, ],
    alias: {
      'ODatabase': [ 'Db', 'ODatabase' ],
      'RecordID': [ 'RID' ],
    },

    namedReturnTags: false,
    namespaceDirMap: {
      'lib/db': 'Database',
      'lib/transport/binary/protocol19': 'Transports.Binary.Protocol-19',
      'lib/transport/binary/protocol26': 'Transports.Binary.Protocol-26',
      'lib/transport/binary/protocol28': 'Transports.Binary.Protocol-28',
      'lib/transport/binary': 'Transports.Binary',
      'lib/transport/rest': 'Transports.Rest',
    },

    builtInTypes: [
      'Integer',
      'Mixed',
      'true',
      'false'
    ]
  }),

  require('megadoc-plugin-markdown')({
    id: 'articles',
    source: 'README.md'
  }),

  require('megadoc-theme-qt')({}),
];

module.exports = config;