import ENV from 'carcin/config/environment';

Array.prototype.flatMap = function(cb) {
    return Array.prototype.concat.apply([], this.map(cb));
};

export default Ember.Component.extend({
  versions: function(key, value) {
    if (arguments.length > 1) {
      return value;
    } else {
      var _this = this;
      this.get('languages').then(function(languages) {
        _this.set('versions', Array.prototype.concat.apply([], languages.filter(function(language) {
          if (window.location.host in ENV.domainLanguageWhitelist) {
            return ENV.domainLanguageWhitelist[window.location.host].indexOf(language.get('name')) != -1;
          } else {
            return true;
          }
        }).map(function(language) {
          return language.get('versions').map(function(version) {
            return {
              "id": language.get('id'),
              "name": language.get('name'),
              "prettyName": ENV.languageNames[language.get('name')],
              "version": version
            };
          });
        })));
      });

      return [];
    }
  }.property('languages'),
  defaultVersion: function() {
    var _this = this,
        version = this.get('versions').filter(function(language) {
          if (_this.get('language') !== undefined && _this.get('version') !== undefined) {
            return language.name === _this.get('language') && language.version === _this.get('version');
          } else {
            return language.id === _this.get('languageId') || language.name === _this.get('languageId');
          }
        })[0];

    if (version) {
      this.sendAction('action', version.name, version.version);
    }

    return version;
  }.property('language', 'version', 'versions', 'languageId'),
  actions: {
    activate: function() {
      var _this = this;
      _this.$(".dropdown-menu").toggleClass("show-menu");
      _this.$(".dropdown-menu > li").click(function() {
        _this.$(".dropdown-menu").removeClass("show-menu");
      });
      _this.$(".dropdown-menu.dropdown-select > li").click(function() {
        _this.$(".dropdown-button").html($(this).html());
        var target = $(this).data('value').split('-'),
            language = target[0],
            version = target[1];
        _this.sendAction('action', language, version);
      });
    }
  }
});
