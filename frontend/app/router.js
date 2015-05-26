import Ember from 'ember';
import config from './config/environment';
import Piwik from 'ember-cli-piwik/mixins/page-view-tracker';

var Router = Ember.Router.extend({
  location: config.locationType
});

export default Router.extend(Piwik).map(function() {
  this.resource('run', {path: '/r/:run_id'}, function() {
    this.route('edit');
  });
  this.route('run_request', {path: '/:language_id'});
});
