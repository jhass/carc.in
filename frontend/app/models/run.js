import Model, { attr } from '@ember-data/model';
import { computed } from '@ember/object';
import ENV from 'carcin/config/environment';

const PlaypenMessages = {
  'timeout triggered!': 'Execution timed out.',
  'write: Resource temporarily unavailable': 'Execution timed out or too much output.'
};

export default Model.extend({
  language:     attr('string'),
  version:      attr('string'),
  code:         attr('string'),
  stdout:       attr('string'),
  stderr:       attr('string'),
  exit_code:    attr('number'),
  created_at:   attr('date'),
  download_url: attr('string'),

  prettyStderr: computed('stderr', function() {
    return this.stderr.split("\n").map(function(line) {
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
  }),

  languageName: computed('language', function() {
    return ENV.languageNames[this.language];
  })
});
