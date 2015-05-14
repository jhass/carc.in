import { LanguageNames } from 'carcin/app';

export default Ember.Handlebars.makeBoundHelper(function(language) {
  if (typeof(language) === "string") {
    return LanguageNames[language];
  } else {
    return LanguageNames[language.id];
  }
});
