export default Ember.Route.extend({
  shortcuts: {
    'n': 'new',
    'e': 'edit'
  },
  actions: {
    new: function() {
      this.transitionTo('run_request', this.get('controller.model.language'));
    },
    edit: function() {
      this.transitionTo('run.edit', this.get('controller.model'));
    }
  },
  afterModel: function(resolvedModel) {
    var title = "Run #"+resolvedModel.get('id');
    document.title = title + ' | Compile & run code in ' + resolvedModel.get('languageName');
    this.controllerFor('application').set('title', title);
  }
});
