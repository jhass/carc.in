import { once } from '@ember/runloop';
import IvyCodemirror from 'ivy-codemirror/components/ivy-codemirror';

export default IvyCodemirror.extend({
  didInsertElement() {
    this._super(...arguments);

    this._codeMirror.focus();
    once(this, 'moveCursorToEnd');
  },
  moveCursorToEnd() {
    this._codeMirror.setCursor(this._codeMirror.lineCount());
  }
});
