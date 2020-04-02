import EmberRouter from '@ember/routing/router';
import config from './config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function() {
  this.route('run', {path: '/r'}, function() {
    this.route('show', {path: '/:run_id'});
    this.route('edit', {path: '/:run_id/edit'});
  });
  this.route('run_request', {path: '/:language_id'});
});
