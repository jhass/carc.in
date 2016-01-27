import Ember from "ember";

var LanguageMap = {
  "gcc": "clike"
};

export default Ember.Component.extend({
  actions: {
    updateRequest: function(language, version) {
      this.set('model.language', language);
      this.set('model.version', version);
    },
    submit: function() {
      if (this.get('isInvalid')) {
        return;
      }

      this.sendAction();
    }
  },
  didInsertElement: function() {
    var cm = this.codeMirror();
    cm.focus();
    cm.setCursor(cm.lineCount());
  },
  codeMirror: function() {
    var candidate, candidates = this.get('childViews');
    for (var i=0; i < candidates.length; i++) {
      candidate = candidates[i].get('codeMirror');
      if (candidate) {
        return candidate;
      }
    }
  },
  editorLanguage: function() {
    return LanguageMap[this.get('model.language')] || this.get('model.language');
  }.property('model.language'),
  isInvalid: function() {
    return Ember.isBlank(this.get('model.code'));
  }.property('model.code')
});
