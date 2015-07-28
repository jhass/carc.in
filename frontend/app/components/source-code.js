import Ember from "ember";

var LanguageMap = {
  "crystal": "ruby",
  "gcc": "c++"
};

export default Ember.Component.extend({
  lineNumbers: false,
  highlightLanguage: function() {
    return LanguageMap[this.get('language')] || this.get('language');
  }.property('language'),
  watchForChanges: function() {
    this.rerender();
  }.observes('code'),
  didInsertElement: function() {
    var code = this.$('pre > code')[0];
    code.innerHTML = window.ansi_up.ansi_to_html(code.innerHTML, {use_classes: true});
    window.hljs.highlightBlock(this.$('pre > code')[0]);
    if (this.get('lineNumbers')) {
      window.hljs.lineNumbersBlock(this.$('pre > code')[0]);
    }
  }
});
