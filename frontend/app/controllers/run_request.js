import Ember from "ember";
import ENV from 'carcin/config/environment';

export default Ember.Controller.extend({
  application: Ember.inject.controller(),
  shortcuts: {
    'ctrl+enter': 'submit'
  },
  actions: {
    submit: function() {
      var _this = this, route = this.get("target");

      route.intermediateTransitionTo("loading");
      this.set('model.id', null);
      this.get('model').save().then(function(response) {
        route.transitionTo('run', response.get('run'));
      }, function() {
        route.intermediateTransitionTo('run_request', _this.get('model')); // TODO: display error
      });
    }
  },
  languageChanged: function() {
    Ember.run.once(this, 'updateTitle');
    Ember.run.once(this, 'updateUrl');
  }.observes('model.language'),
  updateTitle: function() {
    var title = 'Compile & run code in ' + ENV.languageNames[this.get('model.language')];
    this.get('application').set('title', title);
    document.title = title;
  },
  updateUrl: function() {
    if (this.get('application.currentPath') === 'run_request') {
      var location = this.get('target').location;
      this.getLanguageIdFor(this.get('model.language'), function(id) {
        var targetURL = '/' + id;

        if (location.getURL() !== targetURL) {
          location.replaceURL(targetURL);
        }
      });
    }
  },
  getLanguageIdFor: function(nameOrId, cb) {
    this.get('languages').then(function(languages) {
      var language = languages.filter(function(language) {
        return language.get('name') === nameOrId || language.get('id') === nameOrId;
      })[0];

      if (language) {
        cb(language.id);
      }
    });
  }
});
