import ENV from 'carcin/config/environment';

export default Ember.Handlebars.makeBoundHelper(function(language) {
  if (typeof(language) === "string") {
    return ENV.languageNames[language];
  } else {
    return ENV.languageNames[language.id];
  }
});
