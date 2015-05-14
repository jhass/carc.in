import { LanguageNames } from 'carcin/app';

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
        _this.set('versions', Array.prototype.concat.apply([], languages.map(function(language) {
          return language.get('versions').map(function(version) {
            return {
              "id": language.get('id'),
              "name": language.get('name'),
              "prettyName": LanguageNames[language.get('name')],
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
          return language.id == _this.get('languageId');
        })[0];

    if (version) {
      this.sendAction('action', version.name, version.version);
    }

    return version;
  }.property('versions', 'languageId'),
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
