import Component from "@ember/component";
import { computed } from '@ember/object';
import hljs from 'highlight';

let LanguageMap = {
  "gcc": "c++"
};

export default Component.extend({
  highlightCode: computed('language', function() {
    return this.language != 'nohighlight'
  }),
  lineNumbers: false,
  ansiCodes: false,
  classNames: 'source',
  highlightLanguage: computed('language', function() {
    return LanguageMap[this.language] || this.language;
  }),
  didRender() {
    if (this.ansiCodes) {
      let ansiUp = new window.AnsiUp;
      let pre = this.$('pre')[0], code = this.$('pre > code')[0];
      code.innerHTML = ansiUp.ansi_to_html(this.code, {use_classes: true});
      pre.innerHTML = code.outerHTML;
    }

    if (this.highlightCode) {
      let code = this.$('pre > code')[0];
      hljs.highlightBlock(code);
    }

    if (this.lineNumbers) {
      hljs.lineNumbersBlock(this.$('pre > code')[0], {singleLine: true});
    }
  }
});
