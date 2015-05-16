import ENV from 'carcin/config/environment';
import { LanguageNames } from 'carcin/app';

export default Ember.Route.extend({
  shortcuts: {
    'ctrl+enter': 'submit'
  },
  actions: {
    submit: function() {
      this.controller.send('submit');
    }
  },
  setupController: function(controller, model, transition) {
    var title = 'Compile & run code in ' + LanguageNames[this.get('languageId')];
    this.controllerFor('application').set('title', title);
    document.title = title;

    controller.shortcuts.get('filters').clear();
    controller.set('model', model);
    controller.set('languageId', this.get('languageId'));
    controller.set('languages', this.store.find('language'));
  },
  model: function(params) {
    if (LanguageNames[params.language_id] === undefined) {
      this.transitionTo('run_request', ENV.defaultLanguage);
      return;
    }

    this.set('languageId', params.language_id);
    return this.store.createRecord('run-request');
  },
});
