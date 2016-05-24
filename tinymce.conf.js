var path = require('path');
var beautify = require('js-beautify').js_beautify;

var config = {
  title: 'TinyMCE',
  outputDir: '/srv/http/docs/tinymce',
  assetRoot: path.resolve(__dirname, '../tinymce'),
  tooltipPreviews: false,
  strict: false,
  // emittedFileExtension: '.htm',
  corpus: {
  },
  stylesheet: path.resolve(__dirname, 'tinymce.less'),
  styleOverrides: {
    'plain-link': '#2276d2',
  },
  layoutOptions: {
    banner: false,
    // rewrite: {
    //   '/api.html': '/index.html',
    // },

    // bannerLinks: [
    //   {
    //     text: 'API',
    //     href: '/api',
    //   },
    // ]
  }
};

var jsPlugin = require('megadoc-plugin-js')({
  id: 'api',
  source: [
    // 'js/tinymce/classes/AddOnManager.js',
    // 'js/tinymce/classes/Compat.js',
    // 'js/tinymce/classes/DragDropOverrides.js',
    // 'js/tinymce/classes/Editor.js',
    // 'js/tinymce/classes/EditorCommands.js',
    // 'js/tinymce/classes/EditorManager.js',
    // 'js/tinymce/classes/EditorObservable.js',
    // 'js/tinymce/classes/EditorUpload.js',
    // 'js/tinymce/classes/EnterKey.js',
    // 'js/tinymce/classes/Env.js',
    // 'js/tinymce/classes/FocusManager.js',
    // 'js/tinymce/classes/ForceBlocks.js',
    // 'js/tinymce/classes/Formatter.js',
    // 'js/tinymce/classes/InsertContent.js',
    // 'js/tinymce/classes/InsertList.js',
    // 'js/tinymce/classes/jquery.tinymce',
    // 'js/tinymce/classes/LegacyInput.js',
    // 'js/tinymce/classes/Mode.js',
    // 'js/tinymce/classes/NodeChange.js',
    // 'js/tinymce/classes/NotificationManager.js',
    // 'js/tinymce/classes/Register.js',
    // 'js/tinymce/classes/SelectionOverrides.js',
    // 'js/tinymce/classes/Shortcuts.js',
    // 'js/tinymce/classes/UndoManager.js',
    // 'js/tinymce/classes/WindowManager.js',
    // 'js/tinymce/classes/html/*.js',
    // 'js/tinymce/classes/*.js',
    'js/tinymce/classes/**/*.js',
  ],
  // source: 'js/tinymce/classes/ui/FloatPanel.js',
  exclude: [ 'tests' ],
  strict: false,

  namedReturnTags: false,
  namespaceDirMap: {
  },

  builtInTypes: [
    'Element',
    'Event',
    'Document',
    'DragEvent',
    'DOMEvent',
    'DOMElement',
    'DOMNode',
    'DOMRange',
    'HTMLElement',
    'Node',
    'RangeObject',
    'Window',
    // 'Integer',
    'Mixed',
    // 'true',
    // 'false'
  ],
});

jsPlugin.on('preprocess-tag', function(commentNode) {
  if (commentNode.type) {
    commentNode.type = commentNode.type.replace(/(\w)\/(\w)/g, '$1|$2');
  }
});

jsPlugin.on('process-tag', function(tag) {
  var lines;

  if (tag.type === 'example') {
    // lines = tag.string.split('\n');

    // tag.typeInfo.name = lines.shift();
    tag.string = '```js\n' + beautify(tag.string, { indent_size: 4 }) + '\n```';
  }

  return tag;
});

config.plugins = [
  jsPlugin,

  // require('megadoc-plugin-markdown')({
  //   id: 'articles',
  //   source: 'README.md'
  // }),

  require('megadoc-theme-qt')({}),
];

module.exports = config;