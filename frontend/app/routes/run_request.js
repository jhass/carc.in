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
    var _this = this;
    transition.then(function() {
      var id = _this.get('router.url').substr(1),
          title = 'Compile & run code in ' + LanguageNames[id];
      controller.set('languageId', id);
      _this.controllerFor('application').set('title', title);
      document.title = title;
    });

    controller.shortcuts.get('filters').clear();
    controller.set('model', model);
    controller.set('languages', this.store.find('language'));
  },
  model: function() {
    return this.store.createRecord('run-request');
  },
});
