import ENV from 'carcin/config/environment';

export default DS.ActiveModelAdapter.extend({
  host: ENV.apiHost
});
