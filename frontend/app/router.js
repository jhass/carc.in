import Ember from 'ember';
import config from './config/environment';

var Router = Ember.Router.extend({
  location: config.locationType
});

export default Router.map(function() {
  this.route('run_request', {path: '/crystal'});
  this.route('run_request', {path: '/cr'});
  this.route('run', {path: '/r/:run_id'});
});
