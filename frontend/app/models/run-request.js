import Model, { attr, belongsTo } from '@ember-data/model';
import ENV from 'carcin/config/environment';

export default Model.extend({
  url: '/run_requests',
  language: attr('string'),
  version:  attr('string'),
  code:     attr('string'),
  run:      belongsTo('run'),

  languageName: function() {
    return ENV.languageNames[this.language];
  }
});
