import ENV from 'carcin/config/environment';

var LanguageMap = {
  "crystal": "ruby",
  "gcc": "clike"
};

export default Ember.Controller.extend({
  needs: 'application',
  shortcuts: {
    'ctrl+enter': 'submit'
  },
  actions: {
    updateRequest: function(language, version) {
      this.set('languageId', this.getLanguageIdFor(language));
      this.updateUrl();
      this.set('model.language', language);
      this.set('model.version', version);
    },
    submit: function() {
      var _this = this, route = this.get("target");

      if (this.get('isInvalid')) {
        return;
      }

      route.intermediateTransitionTo("loading");
      this.set('model.id', null);
      this.get('model').save().then(function(response) {
        route.transitionTo('run', response.get('run'));
      }, function() {
        route.intermediateTransitionTo('run_request', _this.get('model')); // TODO: display error
      });
    }
  },
  isInvalid: function() {
    return Ember.isBlank(this.get('model.code'));
  }.property('model.code'),
  editorLanguage: function() {
    return LanguageMap[this.get('model.language')] || this.get('model.language');
  }.property('model.language'),
  languageIdChanged: function() {
    Ember.run.once(this, 'updateTitle');
  }.observes('languageId'),
  updateTitle: function() {
    var title = 'Compile & run code in ' + ENV.languageNames[this.get('languageId')];
    this.get('controllers.application').set('title', title);
    document.title = title;
  },
  updateUrl: function() {
    if (this.get('controllers.application.currentPath') === 'run_request') {
      var location = this.get('target').location,
          targetURL = '/' + this.get('languageId');

      if (location.getURL() !== targetURL) {
        location.replaceURL(targetURL);
      }
    }
  },
  getLanguageIdFor: function(nameOrId) {
    var language = this.get('languages').filter(function(language) {
      return language.get('name') === nameOrId || language.get('id') === nameOrId;
    })[0];
    return language ? language.id : null;
  }
});
