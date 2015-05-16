import Ember from 'ember';
import config from './config/environment';

var Router = Ember.Router.extend({
  location: config.locationType
});

export default Router.map(function() {
  this.resource('run', {path: '/r/:run_id'}, function() {
    this.route('edit');
  });
  this.route('run_request', {path: '/:language_id'});
});
