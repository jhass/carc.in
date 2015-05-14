export default Ember.Route.extend({
  beforeModel: function() {
    this.transitionTo("run_request");
  }
});
