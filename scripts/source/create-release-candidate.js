/**
 * Script de versionado de GitLab
 *
 * @author jmartinezpisson
 */
const GitlabAPIController = require("./GitLabAPI");
const standardVersion = require("standard-version");

return standardVersion({
  noVerify: true,
  silent: false,
  skip: {
    changelog: false,
    bump: true,
    commit: false,
    tag: false
  }
})
  .then(() => {
    const packageJson = fs.readFileSync("package.json", { encoding: "utf-8" });

    const gitLabService = new GitlabAPIController({
      baseUrl: process.env["CI_API_V4_URL"],
      projectId: process.env["CI_PROJECT_ID"],
      token: process.env["CI_GITLAB_TOKEN"]
    });

    return gitLabService
      .createCommit({
        branch: process.env["CI_BRANCH_NAME"],
        commit_message: "chore: bump version [skip ci]",
        actions: [
          {
            action: "update",
            file_path: "package.json",
            content: packageJson
          }
        ]
      })
      .then((commitDetail) => {
        return gitLabService.createTag({
          tag_name: `${JSON.parse(packageJson).version}-rc`,
          ref: commitDetail.id
        });
      });
  })
  .catch((err) => {
    console.error(`standard-version failed with message: ${err.message}`);
  });
