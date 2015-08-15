import Ember from "ember";
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
    controller.set('languages', this.store.findAll('language'));
  },
  model: function(params) {
    if (ENV.languageNames[params.language_id] === undefined) {
      this.transitionTo('run_request', ENV.defaultLanguage);
      return;
    }

    return this.store.createRecord('run-request', {language: params.language_id});
  },
});
