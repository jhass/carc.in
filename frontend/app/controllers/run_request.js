export default Ember.Controller.extend({
  actions: {
    updateRequest: function(language, version) {
      this.set('model.language', language);
      this.set('model.version', version);
    },
    submit: function() {
      var _this = this;
      this.get('model').save().then(function(request) {
        _this.transitionTo('run', request.get('run'));
      });
    }
  }
});
