import Route from "@ember/routing/route";
import ENV from 'carcin/config/environment';

export default Route.extend({
  redirect() {
    this.replaceWith('run_request', {language_id: ENV.defaultLanguage});
  }
});
