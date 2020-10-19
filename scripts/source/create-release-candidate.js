/**
 * Script de versionado de GitLab
 *
 * @author jmartinezpisson
 */
const GitlabAPIService = require("./GitLabAPI").default;
const standardVersion = require("standard-version");
const fs = require("fs");

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
    const packageJson = fs.readFileSync("package.json", { encoding: "utf-8" });

    const gitLabService = new GitlabAPIService({
      baseUrl: process.env["CI_API_V4_URL"],
      projectId: process.env["CI_PROJECT_ID"],
      token: process.env["CI_GITLAB_TOKEN"]
    });

    return gitLabService.createTag({
      tag_name: `${JSON.parse(packageJson).version}-rc`,
      ref: process.env["CI_COMMIT_REF_NAME"]
    });
  })
  .catch((err) => {
    console.error(`Error: Creating Release Candidate: ${err.message || err}`);
  });
