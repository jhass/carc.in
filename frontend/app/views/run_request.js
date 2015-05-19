export default Ember.View.extend({
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
  }
});
