import ENV from 'carcin/config/environment';

export default Ember.Route.extend({
  beforeModel: function() {
    this.transitionTo('run_request', ENV.defaultLanguage);
  }
});
