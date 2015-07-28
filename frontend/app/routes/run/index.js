import Ember from "ember";

export default Ember.Route.extend({
  shortcuts: {
    'n': 'new',
    'e': 'edit',
    'ctrl+n': 'newInNewTab',
    'ctrl+e': 'editInNewTab'
  },
  actions: {
    new: function(event) {
      if (event) {
        event.preventDefault();
      }

      this.transitionTo('run_request', this.get('controller.model.language'));
    },
    edit: function(event) {
      if (event) {
        event.preventDefault();
      }

      this.transitionTo('run.edit', this.get('controller.model'));
    },
    newInNewTab: function(event) {
      if (event) {
        event.preventDefault();
      }

      window.open(this.router.generate('run_request', this.get('controller.model.language')));
    },
    editInNewTab: function(event) {
      if (event) {
        event.preventDefault();
      }

      window.open(this.router.generate('run.edit', this.get('controller.model')));
    }
  },
  afterModel: function(resolvedModel) {
    var title = "Run #"+resolvedModel.get('id');
    document.title = title + ' | Compile & run code in ' + resolvedModel.get('languageName');
    this.controllerFor('application').set('title', title);
  }
});
