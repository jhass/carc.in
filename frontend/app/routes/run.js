import Ember from "ember";
import ENV from 'carcin/config/environment';

export default Ember.Route.extend({
  actions: {
    error: function() {
      this.replaceWith('run_request', ENV.defaultLanguage);
    }
  }
});
