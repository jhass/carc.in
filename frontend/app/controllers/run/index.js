import Ember from "ember";

export default Ember.Controller.extend({
  displayOutput: function() {
    return Ember.isPresent(this.get('model.stdout')) || Ember.isBlank(this.get('model.prettyStderr'));
  }.property('model.stdout', 'model.prettyStderr')
});
