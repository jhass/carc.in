export default Ember.Controller.extend({
  shortcuts: {
    'ctrl+enter': 'submit'
  },
  actions: {
    updateRequest: function(language, version) {
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
  }.property('model.language')
});
