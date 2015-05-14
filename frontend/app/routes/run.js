export default Ember.Route.extend({
  shortcuts: {
    'n': 'new'
  },
  actions: {
    new: function() {
      this.transitionTo('run_request');
    },
    error: function(error, transition) {
      this.transitionTo('run_request');
    }
  },
  // setupController: function(controller, model) {
  //   controller.set('model', model);
  //   debugger;
  // },
  afterModel: function(resolvedModel) {
    var title = "Run #"+resolvedModel.get('id');
    document.title = title + ' | Compile & run code in ' + resolvedModel.languageName();
    this.controllerFor('application').set('title', title);
  }
});
