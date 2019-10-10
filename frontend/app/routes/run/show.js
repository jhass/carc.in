import Route from "@ember/routing/route";
import { bindKeyboardShortcuts, unbindKeyboardShortcuts } from 'ember-keyboard-shortcuts';
import { inject as service } from '@ember/service';
import ENV from 'carcin/config/environment';

export default Route.extend({
  router: service(),
  keyboardShortcuts: {
    n: 'new',
    e: 'edit',
    'ctrl+n': 'newInNewTab',
    'ctrl+e': 'editInNewTab',
    'command+n': 'newInNewTab',
    'command+e': 'editInNewTab'
  },
  actions: {
    new() {
      this.transitionTo('run_request', this.controller.model.language);
    },
    edit() {
      this.transitionTo('run.edit', this.controller.model.id);
    },
    newInNewTab: function() {
      debugger;
      window.open(this.router.urlFor('run_request', this.controller.model.language));
    },
    editInNewTab: function() {
      window.open(this.router.urlFor('run.edit', this.controller.model.id));
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
  afterModel: function(resolvedModel) {
    let title = "Run #"+resolvedModel.get('id');
    document.title = title + ' | Compile & run code in ' + resolvedModel.get('languageName');
    this.controllerFor('application').set('title', title);
  }
});
