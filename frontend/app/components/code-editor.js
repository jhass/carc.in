import Component from '@ember/component';
import { computed } from '@ember/object';
import { inject as service } from '@ember/service';
import { isBlank } from '@ember/utils';
import { bindKeyboardShortcuts, unbindKeyboardShortcuts } from 'ember-keyboard-shortcuts';

const LanguageMap = {
  "gcc": "clike"
};

export default Component.extend({
  keyboardShortcuts: {
    'ctrl+enter': 'submit',
    'command+enter': 'submit'
  },
  actions: {
    updatedCode(code) {
      this.set('model.code', code);
    },
    updateRequest(language, version) {
      this.set('model.language', language);
      this.set('model.version', version);
      this.onLanguageChange();
    },
    submit() {
      if (this.isInvalid) {
        return;
      }

      this.onSubmit();
    }
  },
  didInsertElement() {
    bindKeyboardShortcuts(this);
  },
  willDestroyElement() {
    unbindKeyboardShortcuts(this);
  },
  editorLanguage: computed('model.language', function() {
    return LanguageMap[this.get('model.language')] || this.get('model.language');
  }),
  isInvalid: computed('model.code', function() {
    return isBlank(this.get('model.code'));
  })
});
