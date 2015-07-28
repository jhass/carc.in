import DS from "ember-data";
import ENV from 'carcin/config/environment';

var PlaypenMessages = {
  'timeout triggered!': 'Execution timed out.',
  'write: Resource temporarily unavailable': 'Execution timed out or too much output.'
};

export default DS.Model.extend({
  language:   DS.attr('string'),
  version:    DS.attr('string'),
  code:       DS.attr('string'),
  stdout:     DS.attr('string'),
  stderr:     DS.attr('string'),
  exit_code:  DS.attr('number'),
  created_at: DS.attr('date'),

  prettyStderr: function() {
    var foo = this.get('stderr').split("\n").map(function(line) {
      if (line.substr(0, 8) !== 'playpen:') {
        return line;
      }

      for (var message in PlaypenMessages) {
        if (line.substr(9) ===  message) {
          return PlaypenMessages[message];
        }
      }

      return null;
    }).filter(function(line) {
      return line !== null;
    }).join("\n");
    return foo;
  }.property('stderr'),

  languageName: function() {
    return ENV.languageNames[this.get('language')];
  }.property('language')
});
