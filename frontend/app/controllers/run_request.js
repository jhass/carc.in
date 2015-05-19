import ENV from 'carcin/config/environment';

export default Ember.Controller.extend({
  needs: 'application',
  shortcuts: {
    'ctrl+enter': 'submit'
  },
  actions: {
    updateRequest: function(language, version) {
      this.set('languageId', this.getLanguageIdFor(language));
      this.set('model.language', language);
      this.set('model.version', version);
    },
    submit: function() {
      var _this = this;

      if (this.get('isInvalid')) {
        return;
      }

      this.transitionToRoute('loading').then(function() {
        _this.get('model').save().then(function(request) {
          _this.replaceRoute('run', request.get('run'));
        });
      });
    }
  },
  isInvalid: function() {
    return Ember.isBlank(this.get('model.code'));
  }.property('model.code'),
  editorLanguage: function() {
    return 'ruby';
  }.property('model.language'),
  languageIdChanged: function() {
    Ember.run.once(this, 'updateUrl');
    Ember.run.once(this, 'updateTitle');
  }.observes('languageId'),
  updateTitle: function() {
    var title = 'Compile & run code in ' + ENV.languageNames[this.get('languageId')];
    this.get('controllers.application').set('title', title);
    document.title = title;
  },
  updateUrl: function() {
    if (this.get('controllers.application.currentPath') == 'run_request') {
      var location = this.get('target').location,
          targetURL = '/' + this.get('languageId');

      if (location.getURL() !== targetURL) {
        this.replaceRoute('run_request', this.get('languageId'));
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
