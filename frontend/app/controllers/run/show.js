import Controller from '@ember/controller';
import { computed } from '@ember/object';
import { isBlank, isPresent } from '@ember/utils';

export default Controller.extend({
  displayOutput: computed('model.{stdout,prettyStderr}', function() {
    return isPresent(this.get('model.stdout')) || isBlank(this.get('model.prettyStderr'));
  })
});
