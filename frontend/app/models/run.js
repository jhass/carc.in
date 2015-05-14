import { LanguageNames } from 'carcin/app';

export default DS.Model.extend({
  language:   DS.attr('string'),
  version:    DS.attr('string'),
  code:       DS.attr('string'),
  stdout:     DS.attr('string'),
  stderr:     DS.attr('string'),
  exit_code:  DS.attr('number'),
  created_at: DS.attr('date'),

  pretty_stderr: function() {
    return this.get('stderr').split("\n").filter(function(line) {
      return line.substr(0, 8) !== 'playpen:';
    }).join("\n");
  }.property(),

  languageName: function() {
    return LanguageNames[this.get('language')];
  }
});
