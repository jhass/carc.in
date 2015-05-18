import ENV from 'carcin/config/environment';

export default Ember.Route.extend({
  shortcuts: {
    'ctrl+enter': 'submit'
  },
  actions: {
    submit: function() {
      this.controller.send('submit');
    }
  },
  setupController: function(controller, model) {
    controller.shortcuts.get('filters').clear();
    controller.set('model', model);
    controller.set('languages', this.store.find('language'));
    controller.set('languageId', this.get('languageId'));
  },
  model: function(params) {
    if (ENV.languageNames[params.language_id] === undefined) {
      this.transitionTo('run_request', ENV.defaultLanguage);
      return;
    }

    this.set('languageId', params.language_id);
    return this.store.createRecord('run-request');
  },
});
