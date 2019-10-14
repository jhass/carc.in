import Route from "@ember/routing/route";
import ENV from 'carcin/config/environment';

export default Route.extend({
  beforeModel() {
    this.replaceWith('run_request', ENV.defaultLanguage);
  }
});
