export default Ember.Route.extend({
  actions: {
    error: function() {
      this.transitionTo('run_request');
    }
  }
});
