var path = require('path');

var config = {
  title: 'Bridge LMS',
  assetRoot: path.resolve(__dirname, '../get_smart'),
  outputDir: '/srv/http/docs/get_smart',
  home: '/readme',
  styleOverrides: 'doc/tiny/overrides.less',
  stylesheet: 'doc/tiny/index.less',
  showSettingsLinkInBanner: false,
  metaDescription: 'The Bridge (LMS) devhouse &amp; hax!',
  emitFiles: true,

  assets: [
    'doc/js/js-data-layers.png',
    'doc/js/js-data-layers__ui-interaction.png',
    'doc/rails/owned-by-domain.png',
    'doc/rails/within-domain.png',
  ],

  footer: [
    'Made with &#9829; by the Bridge Team using [megadoc](https://github.com/megadoc/megadoc).',
    '&copy; 2015 [Instructure](http://www.instructure.com/)'
  ].join("\n\n"),

  gitStats: true,
  favicon: 'app/assets/images/favicon-docs.ico',

  hotness: {
    count: 1,
    interval: 'weeks'
  },

  disqus: {
    enabled: false
  },

  layoutOptions: {
    bannerLinks: [
      {
        text: 'API',
        href: '/api'
      },
      {
        text: 'Articles',
        href: '/guides'
      },
      {
        text: 'JavaScripts',
        href: '/js',
        links: [
          {
            text: 'Modules',
            href: '/js'
          },
          {
            text: 'Components',
            href: '/components'
          },
          {
            text: 'Internal Packages',
            href: '/js__packages'
          },
          {
            text: 'React Drill',
            href: '/js__react-drill'
          },
        ]
      }
    ]
  },

};

var gitPlugin = require('megadoc-plugin-git')({
  // routeName: 'stats',
  // superStars: false,
  // recentCommits: {
  //   since: '3 days ago',
  //   ignore: [ /Updated (\w+) translation/ ],
  //   transform: function(commitMsg) {
  //     return commitMsg.replace(/Change-Id: [\s\S]+$/m, '');
  //   }
  // },

  // teams: require('./doc/tiny/git_team_roster')
});

// var yardAPIPlugin = require('megadoc-plugin-yard-api')({
//   url: 'api',
//   source: 'public/doc/api/json/*.json',
//   command: 'bundle exec rake doc:api_json',
//   showEndpointPath: false,
//   readme: 'doc/api/README.md',
//   staticPages: [
//     'doc/api/**/*.md'
//   ],
//   skipScan: process.env.QUICK === '1'
// });

// var markdownPlugin = require('megadoc-plugin-markdown')({
//   id: 'guides',
//   title: 'Articles',
//   source: [
//     'doc/**/*.md',
//     'lib/bridge_cli/*.md',
//     'packages/bridge-async-props/README.md',
//     'packages/cocache/README.md',
//   ],
//   exclude: [
//     'doc/api',
//     'doc/ashes',
//     'doc/refactoring',
//   ],
//   fullFolderTitles: true,
//   discardIdPrefix: /\d+\-{1}/,
//   folders: [
//     { path: '', title: '[Other]' },
//     {
//       path: 'doc/cookbook',
//       title: 'Cookbook',
//       series: false
//     },
//     {
//       path: 'doc/js',
//       title: 'JavaScript',
//       series: true
//     },
//     {
//       path: 'doc/js_testing',
//       title: 'JavaScript Testing',
//       series: true
//     },
//     {
//       path: 'doc/js_conventions',
//       title: 'JavaScript Conventions'
//     },
//     {
//       path: 'doc/ops_deploy',
//       title: 'Operations - Deployment'
//     },
//     {
//       path: 'doc/ops',
//       title: 'Operations'
//     },
//     {
//       path: 'lib/bridge_cli',
//       title: 'BridgeCLI'
//     },
//   ]
// });

var jsPlugin = require('megadoc-plugin-js')({
  routeName: 'js',
  title: 'JS',
  gitStats: true,

  source: [
    'jsapp/shared/!(components)/**/*.js',
    'jsapp/shared/components/HybridLink.js',
    'jsapp/ext/paginated_array.js',
    'doc/js/**/*.js',
    'packages/bridge-async-props/src/*.js',
  ],

  exclude: [
    /\.test\.js$/,
    'jsapp/shared/GetSmart',
    'jsapp/shared/handlers',
  ],

  useDirAsNamespace: false,

  inferModuleIdFromFileName: true,
  alias: {
    'Data.Cocache': [ 'Cache', 'Data.Cache' ],
    'DataTransport.ajax': [ 'ajax' ],
  },

  builtInTypes: [
    'React',
    'React.Class',
    'Event',
    'HTMLElement',
    {
      name: 'Ember.Object',
      href: 'http://emberjs.com/api/classes/Ember.Object.html'
    }
  ]
});

var jsPackagesPlugin = require('megadoc-plugin-js')({
  id: 'js__packages',
  title: 'JS Packages',

  source: [
    'packages/cocache/src/**/*.js',
    'packages/cocache-schema/src/**/*.js',
  ],

  exclude: [ /\.test\.js$/, ],

  inferModuleIdFromFileName: true,

  alias: {
    'Cocache': [ 'Cache' ]
  }
});

var jsReactDrillPlugin = require('megadoc-plugin-js')({
  id: 'js__react-drill',
  title: 'React Drill',

  gitStats: false,

  source: [
    'node_modules/react-drill/lib/**/*.js',
  ],

  exclude: [
    /\.test\.js$/,
  ],

  inferModuleIdFromFileName: true,
});

var componentJSPlugin = require('megadoc-plugin-js')({
  id: 'components',
  title: 'Components',

  source: [
    'jsapp/shared/components/*.js',
    'jsapp/shared/components/CSVImporting/Table.js',
  ],

  exclude: [
    'PropResolver*',
    'HybridLink',
  ]
});

// var componentPlugin = require('megadoc-plugin-react')({
//   id: 'components',

//   assets: [
//     { 'public/fonts': '/fonts' },
//     { 'public/fonts': '/assets/public/fonts' },
//   ],

//   styleSheets: [
//     'public/stylesheets/application.css'
//   ],

//   scripts: [
//     'public/javascripts/megadoc-components.js',
//     'doc/tiny/component_example_runner.js',
//   ],

//   compile: require(path.resolve(config.assetRoot, 'doc/tiny/compileComponents'))
// });

config.plugins = [
  // gitPlugin,
  // yardAPIPlugin,
  jsPlugin,
  jsPackagesPlugin,
  jsReactDrillPlugin,
  componentJSPlugin,
  // componentPlugin,
  // markdownPlugin,

  require('megadoc-theme-qt')({
    invertedSidebar: true,
  }),

  // require('megadoc-plugin-static')({
  //   url: '/readme',
  //   title: 'README',
  //   source: 'README.md',
  //   anchorableHeadings: true,
  // }),

  // require('megadoc-plugin-static')({
  //   url: '/js',
  //   tite: 'Getting Started - JavaScripts',
  //   source: 'doc/js/README.md',
  //   outlet: 'CJS::Landing',
  // }),

  // require('megadoc-plugin-static')({
  //   url: '/api',
  //   tite: 'Getting Started - API',
  //   source: 'doc/api/README.md',
  //   outlet: 'yard-api::Landing',
  // }),

  // require('megadoc-plugin-static')({
  //   url: '/js__react-drill',
  //   tite: 'React Drill',
  //   source: 'node_modules/react-drill/README.md',
  //   outlet: 'CJS::Landing',
  // }),

  // require('megadoc-plugin-static')({
  //   url: '/js__packages',
  //   tite: 'Internal Packages',
  //   source: 'packages/README.md',
  //   outlet: 'CJS::Landing',
  // }),

  // require('megadoc-plugin-reference-graph')({
  // }),
];

module.exports = config;
