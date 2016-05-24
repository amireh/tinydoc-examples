var path = require('path');
var beautify = require('js-beautify').js_beautify;

var config = {
  title: 'TinyMCE',
  outputDir: '/srv/http/docs/tinymce',
  assetRoot: path.resolve(__dirname, '../tinymce'),
  tooltipPreviews: false,

  // there are some UID clashes that we still need to solve:
  strict: false,
  stylesheet: path.resolve(__dirname, 'tinymce.less'),
  styleOverrides: {
    'plain-link': '#2276d2',
  },
  layoutOptions: {
    banner: false,
  }
};

var jsPlugin = require('megadoc-plugin-js')({
  id: 'api',

  source: [
    'js/tinymce/classes/**/*.js',
  ],

  strict: false,

  namedReturnTags: false,

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
    'Mixed',
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
    tag.string = '```js\n' + beautify(tag.string, { indent_size: 4 }) + '\n```';
  }

  return tag;
});

config.plugins = [ jsPlugin, require('megadoc-theme-qt')({}) ];

module.exports = config;