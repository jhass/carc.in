import Controller, { inject as controller } from '@ember/controller';
import { inject as service } from '@ember/service';
import { debug } from '@ember/debug';
import ENV from 'carcin/config/environment';

export default Controller.extend({
  application: controller(),
  router: service(),
  actions: {
    submit() {
      let target = this.get('target');
      target.intermediateTransitionTo('loading');
      this.set('model.request.id', null);
      const model = this.get('model');
      const request = this.get('model.request');
      request.save().then((response) => {
        this.transitionToRoute('run.show', response.get('run'));
      }, (error) => {
        debug(error);
        target.intermediateTransitionTo('run_request', model); // TODO: display error
      });
    },
    updateLanguage() {
      this.updateTitle();
      this.updateUrl();
    }
  },
  updateTitle() {
    let title = 'Compile & run code in ' + ENV.languageNames[this.model.request.language];
    this.set('application.title', title);
    document.title = title;
  },
  updateUrl: function() {
    if (this.get('router.currentRouteName') === 'run_request') {
      let location = this.get('target').location,
        id = this.getLanguageIdFor(this.get('model.request.language')),
        targetURL = '/' + id;

      if (location.getURL() !== targetURL) {
        this.get('target').replaceWith('run_request', id);
      }
    }
  },
  getLanguageIdFor: function(nameOrId) {
    let language = this.get('model.languages').filter(function(language) {
      return language.get('name') === nameOrId || language.get('id') === nameOrId;
    })[0];

    if (language) {
      return language.id;
    }

    return;
  }
})
