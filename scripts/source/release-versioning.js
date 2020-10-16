/**
 * Script de versionado de GitLab
 *
 * @author jmartinezpisson
 */
const standardVersion = require("standard-version");

return standardVersion({
  noVerify: true,
  silent: false,
  skip: {
    changelog: true,
    bump: false,
    commit: true,
    tag: true
  }
})
  .then(() => {
    // standard-version is done
  })
  .catch((err) => {
    console.error(`standard-version failed with message: ${err.message}`);
  });
