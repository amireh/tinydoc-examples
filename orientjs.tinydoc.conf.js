var path = require('path');
// ugh, seriously?
var logo = {};
logo[path.resolve(__dirname, 'orientdb_logo_2x11.png')] = 'images/orientdb_logo_2x11.png';
var config = {
  title: 'orientjs',
  outputDir: '/srv/http/docs/orientjs',
  assetRoot: path.resolve(__dirname, 'orientjs'),
  tooltipPreviews: false,
  assets: [ logo ],
  stylesheet: path.resolve(__dirname, './orientjs.less'),
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
  require('tinydoc-plugin-js')({
    id: 'api',
    source: 'lib/**/*.js',
    exclude: [ /\.test\.js$/, /vendor/, ],
    alias: {
      'ODatabase': [ 'Db' ]
    },

    namedReturnTags: false,
    namespaceDirMap: {
      'lib/db': 'Database',
      'lib/transport/binary': 'Transports.Binary',
      'lib/transport/rest': 'Transports.Rest',
    }
  }),

  require('tinydoc-plugin-markdown')({
    id: 'articles',
    source: 'README.md'
  }),

  require('tinydoc-theme-qt')({}),
];

module.exports = config;