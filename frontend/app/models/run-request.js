import DS from "ember-data";
import ENV from 'carcin/config/environment';

export default DS.Model.extend({
  url: '/run_requests',
  language: DS.attr('string'),
  version:  DS.attr('string'),
  code:     DS.attr('string'),
  run:      DS.belongsTo('run'),

  languageName: function() {
    return ENV.languageNames[this.get('language')];
  }
});
