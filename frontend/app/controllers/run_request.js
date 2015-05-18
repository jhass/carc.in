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
      this.transitionTo('loading').then(function() {
        _this.get('model').save().then(function(request) {
          _this.transitionTo('run', request.get('run'));
        });
      });
    }
  },
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
      this.get('target').location.replaceURL('/' + this.get('languageId'));
    }
  },
  getLanguageIdFor: function(nameOrId) {
    var language = this.get('languages').filter(function(language) {
      return language.get('name') === nameOrId || language.get('id') === nameOrId;
    })[0];
    return language ? language.id : null;
  }
});
