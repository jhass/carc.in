import Ember from "ember";
import _ from "lodash";

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
    this.highlight();
  }.observes('code'),
  didInsertElement: function() {
    this.highlight();
  },
  highlight: function() {
    var pre = this.$('pre')[0], code = this.$('pre > code')[0];
    code.innerHTML = window.ansi_up.ansi_to_html(_.escape(this.get('code')), {use_classes: true});
    pre.innerHTML = code.outerHTML;
    window.hljs.highlightBlock(this.$('pre > code')[0]);
    if (this.get('lineNumbers')) {
      window.hljs.lineNumbersBlock(this.$('pre > code')[0]);
    }
  }
});
