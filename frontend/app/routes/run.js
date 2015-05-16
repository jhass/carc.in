import ENV from 'carcin/config/environment';

export default Ember.Route.extend({
  actions: {
    error: function() {
      this.transitionTo('run_request', ENV.defaultLanguage);
    }
  }
});
