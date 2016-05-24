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
  // Some of their union type-strings (like in @param {A|B}) are delimited by /
  // which is not correct according the Google Closure Compiler spec; they
  // have to be delimited by |
  //
  // So from: @param {A/B} to @param {A|B}
  //
  if (commentNode.type) {
    commentNode.type = commentNode.type.replace(/(\w)\/(\w)/g, '$1|$2');
  }
});

jsPlugin.on('process-tag', function(tag) {
  var lines;

  // Their examples are not indented to be considered code blocks by Markdown
  // but most of them are just code, so we'll wrap them in a block as such:
  //
  //     ```js
  //     ```
  //
  // and cross our fingers:
  if (tag.type === 'example') {
    tag.string = '```js\n' + beautify(tag.string, { indent_size: 4 }) + '\n```';
  }

  return tag;
});

config.plugins = [ jsPlugin, require('megadoc-theme-qt')({}) ];

module.exports = config;