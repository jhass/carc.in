import Component from '@ember/component';
import { once } from '@ember/runloop';
import ENV from 'carcin/config/environment';
import jQuery from 'jquery';

export default Component.extend({
  actions: {
    activate() {
      let action = this.get('action'),
        button = this.$(".dropdown-button"),
        menu = this.$(".dropdown-menu");
      menu.toggleClass("show-menu");
      this.$(".dropdown-menu > li").click(function() {
        menu.removeClass("show-menu");
      });
      this.$(".dropdown-menu.dropdown-select > li").click(function() {
        button.html(jQuery(this).html());
        let target = jQuery  (this).data('value').split('-'),
            language = target[0],
            version = target[1];
        action(language, version);
      });
    }
  },
  didReceiveAttrs() {
    if (this.languages == undefined) {
      return;
    }
    this.updateVersions()
    this.updateDefaultVersion()

    let version = this.defaultVersion;
    once(this, 'action', version.name, version.version);
  },
  updateVersions() {
    this.set('versions', Array.prototype.concat.apply([], this.languages.filter(function(language) {
      if (window.location.host in ENV.domainLanguageWhitelist) {
        return ENV.domainLanguageWhitelist[window.location.host].indexOf(language.name) !== -1;
      } else {
        return true;
      }
    }).map(function(language) {
      return language.versions.map(function(version) {
        return {
          "id": language.id,
          "name": language.get('name'),
          "prettyName": ENV.languageNames[language.name],
          "version": version
        };
      });
    })));
  },
  updateDefaultVersion() {
    this.set('defaultVersion', this.versions.filter((language) => {
      if (this.version !== undefined) {
        return language.name === this.language && language.version === this.version;
      } else {
        return language.id === this.language || language.name === this.language;
      }
    })[0]);
  }
});
