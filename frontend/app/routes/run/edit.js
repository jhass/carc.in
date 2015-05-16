export default Ember.Route.extend({
  shortcuts: {
    'ctrl+enter': 'submit'
  },
  actions: {
    submit: function() {
      this.controller.send('submit');
    }
  },
  controllerName: 'run_request',
  templateName: 'run_request',
  setupController: function(controller, model) {
    var request = this.store.createRecord('run-request', {
          language: model.get('language'),
          version: model.get('version'),
          code: model.get('code')
        }),
        title = 'Compile & run code in ' + model.languageName();
    controller.shortcuts.get('filters').clear();
    controller.set('model', request);
    controller.set('languages', this.store.find('language'));
    controller.set('languageId', model.get('language'));
    this.controllerFor('application').set('title', title);
    document.title = title;
  }
});
