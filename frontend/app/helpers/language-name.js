import { helper } from '@ember/component/helper';
import ENV from 'carcin/config/environment';

export default helper(function([language]) {
  if (typeof(language) === "string") {
    return ENV.languageNames[language];
  } else {
    return ENV.languageNames[language.id];
  }
});
