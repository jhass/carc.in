import Route from "@ember/routing/route";
import Promise from 'rsvp';
import { bindKeyboardShortcuts, unbindKeyboardShortcuts } from 'ember-keyboard-shortcuts';
import PageModel from 'carcin/routes/run_request';
import ENV from 'carcin/config/environment';

export default Route.extend({
  controllerName: 'run_request',
  templateName: 'run_request',
  keyboardShortcuts: {
    esc: 'returnToRun'
  },
  actions: {
    returnToRun() {
      this.replaceWith('run.show', this.run_id);
    },
    error() {
      this.replaceWith('run_request', ENV.defaultLanguage); // TODO display error message
    }
  },
  activate() {
    bindKeyboardShortcuts(this);
  },
  deactivate() {
    unbindKeyboardShortcuts(this);
  },
  model(params) {
    this.set('run_id', params.run_id);
    return Promise.all([this.store.findRecord('run', params.run_id), this.store.findAll('language')]).then((results) => {
      let run = results[0], languages = results[1];
      let request = this.store.createRecord('run-request', {
          language: run.language,
          version: run.version,
          code: run.code
        });

      return PageModel.create({
        request: request,
        languages: languages
      })
    });
  }
});
