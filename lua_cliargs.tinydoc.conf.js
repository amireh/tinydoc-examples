var path = require('path');

exports.assetRoot = path.resolve(__dirname, 'lua_cliargs');
exports.outputDir = '/srv/http/docs/lua_cliargs';
exports.title = 'lua_cliargs';
exports.scrollSpying = true;
exports.resizableSidebar = false;
exports.collapsibleSidebar = true;
exports.layoutOptions = {
  banner: false,
  bannerLinks: null,
  singlePageMode: true,

  customLayouts: [
    {
      match: { by: 'url', on: '*' },
      regions: [
        {
          name: 'Layout::Content',
          options: { framed: true },
          outlets: [
            {
              name: 'Markdown::Document',
              using: 'markdown/readme',
            },
            {
              name: 'Lua::AllModules',
              using: 'lua',
            },
          ]
        },

        {
          name: 'Layout::Sidebar',
          options: { framed: true },
          outlets: [
            {
              name: 'Layout::SidebarHeader',
              options: { text: 'lua_cliargs' }
            },

            {
              name: 'Markdown::DocumentTOC',
              using: 'markdown/readme'
            },

            {
              name: 'Layout::SidebarHeader',
              options: { text: 'API' }
            },

            {
              name: 'Lua::Browser',
              using: 'lua',
            }
          ]
        }
      ]
    }
  ]
};

exports.plugins = [
  require('megadoc-plugin-lua')({
    source: 'src/**/*.lua'
  }),

  require('megadoc-plugin-markdown')({
    id: 'markdown',
    source: 'README.md'
  }),

  require('megadoc-theme-gitbooks')()
];
