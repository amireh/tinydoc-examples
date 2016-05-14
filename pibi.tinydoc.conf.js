var path = require('path');
var config = {
  title: 'Pibi API',
  outputDir: '/srv/http/docs/pibi',
  assetRoot: path.resolve(__dirname, 'pibi'),
  tooltipPreviews: false,
  layoutOptions: {
    bannerLinks: [
      {
        text: 'API',
        href: '/api',
      },
    ]
  }
};

config.plugins = [
  require('tinydoc-plugin-yard-api')({
    routeName: 'api',
    command: 'bundle exec rake doc:api_json',

    source: [
      'public/doc/api/**/*.json',
    ],
  }),

  require('tinydoc-theme-qt')({}),
  require('tinydoc-plugin-git')({
  }),
];

module.exports = config;