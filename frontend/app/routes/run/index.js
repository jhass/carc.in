export default Ember.Route.extend({
  shortcuts: {
    'n': 'new',
    'e': 'edit'
  },
  actions: {
    new: function() {
      this.transitionTo('run_request');
    },
    edit: function() {
      this.transitionTo('run.edit', this.get('controller.model'));
    },
    error: function() {
      this.transitionTo('run_request');
    }
  },
  afterModel: function(resolvedModel) {
    var title = "Run #"+resolvedModel.get('id');
    document.title = title + ' | Compile & run code in ' + resolvedModel.languageName();
    this.controllerFor('application').set('title', title);
  }
});
