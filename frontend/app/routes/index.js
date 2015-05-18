import ENV from 'carcin/config/environment';

export default Ember.Route.extend({
  redirect: function() {
    this.replaceWith('run_request', ENV.defaultLanguage);
  }
});
