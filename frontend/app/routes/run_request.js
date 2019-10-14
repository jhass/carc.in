import Route from "@ember/routing/route";
import { inject as service } from '@ember/service';
import EmberObject from '@ember/object';
import { hash } from 'rsvp';
import ENV from 'carcin/config/environment';

export const PageModel = EmberObject.extend({
  request: null,
  languages: null
});

export default Route.extend({
  store: service(),
  model(params) {
    if (ENV.languageNames[params.language_id] === undefined) {
      this.replaceWith('run_request', ENV.defaultLanguage);
      return;
    }

    const request = this.get('store').createRecord('run-request', {language: params.language_id}),
      languages = this.get('store').findAll('language');

    return hash({languages: languages, request: request}).then(function (data) {
      return PageModel.create(data);
    });
  }
});
