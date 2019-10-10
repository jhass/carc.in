import Route from "@ember/routing/route";
import { inject as service } from '@ember/service';
import EmberObject from '@ember/object';
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

    const request = this.get('store').createRecord('run-request', {language: params.language_id})

    return this.get('store').findAll('language').then(function (languages) {
      return PageModel.create({
        request: request,
        languages: languages
      });
    });
  }
});
