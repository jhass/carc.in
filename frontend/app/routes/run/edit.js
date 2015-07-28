import Ember from "ember";

export default Ember.Route.extend({
  controllerName: 'run_request',
  templateName: 'run_request',
  viewName: 'run_request',
  shortcuts: {
    'ctrl+enter': 'submit',
    'esc': 'showRun'
  },
  actions: {
    submit: function() {
      this.controller.send('submit');
    },
    showRun: function() {
      this.transitionTo('run', this.get('run'));
    }
  },
  setupController: function(controller, model) {
    var request = this.store.createRecord('run-request', {
          language: model.get('language'),
          version: model.get('version'),
          code: model.get('code')
        });
    this.set('run', model);
    controller.shortcuts.get('filters').clear();
    controller.set('model', request);
    controller.set('languages', this.store.findAll('language'));
  }
});
