import { LanguageNames } from 'carcin/app';

export default DS.Model.extend({
  url: '/run_requests',
  language: DS.attr('string'),
  version:  DS.attr('string'),
  code:     DS.attr('string'),
  run:      DS.belongsTo('run'),

  languageName: function() {
    return LanguageNames[this.get('language')];
  }
});
