/* global require, module */
var EmberApp = require('ember-cli/lib/broccoli/ember-app');

module.exports = function(defaults) {
  var app = new EmberApp(defaults, {
    codemirror: {
      modes: ['ruby', 'clike'],
      themes: ['neat']
    }
  });

  // Use `app.import` to add additional libraries to the generated
  // output files.
  //
  // If you need to use different assets in different
  // environments, specify an object as the first parameter. That
  // object's keys should be the environment name and the values
  // should be the asset to use in that environment.
  //
  // If the library that you are including contains AMD or ES6
  // modules that you would like to import into your application
  // please specify an object with the list of modules as keys
  // along with the exports of each module as its value.

  app.import('bower_components/ember-shortcuts/ember-shortcuts.js');

  app.import('bower_components/highlightjs/highlight.pack.js');
  app.import('bower_components/highlightjs/styles/github.css');
  app.import('bower_components/highlightjs-line-numbers.js/dist/highlightjs-line-numbers.min.js');

  app.import('bower_components/ansi_up/ansi_up.js');


  return app.toTree();
};
