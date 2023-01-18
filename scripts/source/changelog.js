#!/usr/bin / env node
const fs = require("fs");
const Mustache = require("mustache");
const commitlint = require("@commitlint/lint").default;
const GitLabAPIService = require("./GitLabAPI").default;
const { getLastSemanticTag } = require("./SemanticTag");

const BASE_COMMIT_STRUCTURE = {
  added: [],
  changed: [],
  removed: [],
  fixed: [],
  deprecated: [],
  security: []
};

const COMMIT_HEADING_TYPES = Object.freeze({
  added: "Added",
  changed: "Changed",
  removed: "Removed",
  fixed: "Fixed"
});

const lintCommit = function (message) {
  const config = Object.assign(
    require("@commitlint/config-conventional").rules,
    require(`${process.cwd()}/commitlint.config.js`).rules
  );
  return commitlint(message, config);
};

class FileController {
  constructor(content) {
    if (content && content.length > 0) {
      this.content = content;
      this.iterator = 0;
    } else {
      throw new Error("File must have content");
    }
  }

  peek() {
    return this.content[this.iterator];
  }

  forward() {
    if (this.content.length > this.iterator + 1) {
      return ++this.iterator;
    }
    return null;
  }

  back() {
    if (this.iterator > 0) {
      return --this.iterator;
    }
    return null;
  }

  nextLine() {
    if (this.findNextTextAndMoveIterator("\n") >= 0) {
      this.forward();
    }
  }

  readLine() {
    const index = this.content.indexOf("\n", this.iterator);
    return this.content.slice(this.iterator, index);
  }

  append(text) {
    this.content =
      this.content.slice(0, this.iterator) +
      text +
      this.content.slice(this.iterator, this.content.length);
    this.iterator += text.length;
    return this;
  }

  findTextAndMoveIterator(text) {
    const index = this.content.indexOf(text);
    if (index >= 0) {
      this.iterator = index;
    }
    return index;
  }

  findNextTextAndMoveIterator(text) {
    const index = this.content.indexOf(text, this.iterator);
    if (index >= 0) {
      this.iterator = index;
    }
    return index;
  }

  replaceCurrentLine(text) {
    return (this.content = this.content.replace(this.readLine(), text));
  }
}

class ChangelogGenerator {
  generate(commits) {
    return new Promise((resolve, reject) => {
      fs.readFile(
        `${__dirname}/templates/CHANGELOG.md.mustache`,
        (err, data) => {
          if (err) {
            reject(err);
          } else {
            const changelog = Mustache.render(data.toString(), {
              commits: {
                unreleased:
                  ChangelogGenerator.generateMustacheDataStructure(commits)
              }
            });
            resolve(changelog);
          }
        }
      );
    });
  }

  static generateMustacheDataStructure(commits) {
    const result = {
      commitSize: 0
    };
    for (let key in commits) {
      result[key] = {
        commitSize: commits[key].length,
        commitList: commits[key]
      };
      result.commitSize += result[key].commitSize;
    }
    return result;
  }

  addToUnreleased(changelogFile, commits) {
    const file = new FileController(changelogFile);
    file.findTextAndMoveIterator("## Unreleased");
    if (file.iterator === 0) {
      file.findTextAndMoveIterator("---\n");
      file.nextLine();
      file.nextLine();
      file.append("## Unreleased\n");
      file.findTextAndMoveIterator("## Unreleased");
    }
    return ChangelogGenerator.addCommitsToCurrentHeading(file, commits);
  }

  addToVersion(changelogFile, version, commits) {
    const file = new FileController(changelogFile);
    file.findTextAndMoveIterator(`## ${version} - `);
    if (file.iterator > 0) {
      file.content = ChangelogGenerator.addCommitsToCurrentHeading(
        file,
        commits
      );
    }
    return file.content;
  }

  moveUnreleasedToVersion(changelogFile, version) {
    const currentDate = new Date();
    const file = new FileController(changelogFile);
    file.findTextAndMoveIterator("## Unreleased");
    file.replaceCurrentLine(
      `## ${version} - ${currentDate.getDate()}/${
        currentDate.getMonth() + 1
      }/${currentDate.getFullYear()}`
    );
    return file.content;
  }

  static addCommitsToCurrentHeading(file, commits) {
    for (let heading in COMMIT_HEADING_TYPES) {
      file.findNextTextAndMoveIterator("\n##");
      if (commits[heading] && commits[heading].length) {
        file.nextLine();
        const line = file.readLine();
        if (line !== `### ${COMMIT_HEADING_TYPES[heading]}`) {
          file.append(`### ${COMMIT_HEADING_TYPES[heading]}\n`);
        } else {
          ChangelogGenerator.moveToLastItemInList(file);
        }
        for (const commit of commits[heading]) {
          file.append(`- ${commit.body}\n`);
        }
        file.back();
      } else {
        const currentPos = file.iterator;
        file.nextLine();
        const line = file.readLine();
        if (line === `### ${COMMIT_HEADING_TYPES[heading]}`) {
          ChangelogGenerator.moveToLastItemInList(file);
          file.back();
        } else {
          file.iterator = currentPos;
        }
      }
    }
    return file.content;
  }

  static moveToLastItemInList(file) {
    let findLastCommitLine;
    do {
      file.nextLine();
      findLastCommitLine = file.readLine();
    } while (findLastCommitLine.match(/^- .*/));
  }
}

const transformCommits = async (resultPromise, commit) => {
  const result = await resultPromise;
  const lint = await lintCommit(commit.message);

  if (lint.valid) {
    let matchType = commit.message.match(/^(.*):\s/);

    console.log(matchType);

    if (matchType && matchType[1]) {
      const type = matchType[1].split("(")[0];
      const matchTitle = commit.message.match(/^.*?:\s(.*?)\n/ms);

      console.log(matchTitle);

      if (matchTitle && matchTitle[1]) {
        const newItem = {
          body: matchTitle[1]
        };
        switch (type) {
          case "feat":
            result["added"].push(newItem);
            break;
          case "refactor":
          case "chore":
            result["changed"].push(newItem);
            break;
          case "fix":
            result["fixed"].push(newItem);
            break;
          case "revert":
            result["removed"].push(newItem);
            break;
        }
      }
    }
  }
  return result;
};
async function main() {
  const changelogGenerator = new ChangelogGenerator();
  const gitLabService = new GitLabAPIService({
    baseUrl: process.env["CI_API_V4_URL"],
    projectId: process.env["CI_PROJECT_ID"],
    token: process.env["CI_GITLAB_TOKEN"]
  });

  if (process.argv[2]) {
    const newVersion = process.argv[2];
    console.log(`Generating version ${newVersion}...`);
    if (newVersion.match(/^[0-9]*\.[0-9]*\.[0-9]*$/)) {
      const changelogFile = await gitLabService.getChangelogWikiPage();
      console.log(
        `Moving all changes from Unreleased section to ${newVersion}...`
      );
      const newContent = changelogGenerator.moveUnreleasedToVersion(
        changelogFile.content,
        newVersion
      );
      console.log("Updating CHANGELOG wiki page...");
      const response = await gitLabService.editChangelogWikiPage(newContent);
      console.log(response);
    } else {
      console.error(
        `Error generating version: Version number ${newVersion} is not a valid version number`
      );
    }
  } else {
    console.log("Adding new changes to Unreleased...");
    try {
      console.log(`Getting differences from last tagged version commits...`);
      let lastTag = getLastSemanticTag(
        await gitLabService.getTags(),
        process.env["CI_COMMIT_REF_NAME"] === "dev"
          ? /^\d*\.\d*\.\d*-rc$/
          : /^\d*\.\d*\.\d*-UAT$/
      );
      const comparison = await gitLabService.compare({
        from: lastTag.target,
        to: process.env["CI_COMMIT_REF_NAME"]
      });

      console.log(comparison.commits);

      const commits = await comparison.commits.reduce(
        transformCommits,
        Promise.resolve(Object.assign({}, BASE_COMMIT_STRUCTURE))
      );

      console.log(`${commits.added.length} additions`);
      console.log(`${commits.changed.length} changes`);
      console.log(`${commits.removed.length} removals`);
      console.log(`${commits.fixed.length} fixes`);
      console.log("Getting CHANGELOG wiki page....");

      gitLabService
        .getChangelogWikiPage()
        .then(async (changelogFile) => {
          console.log("CHANGELOG wiki page found.");
          if (changelogFile.content) {
            let newContent;
            const content = changelogFile.content;
            const targetBranch = process.env["CI_COMMIT_REF_NAME"];

            if (targetBranch === "dev") {
              console.log(
                `Target branch is ${targetBranch}, adding changes to Unreleased section...`
              );
              newContent = changelogGenerator.addToUnreleased(content, commits);
            } else if (targetBranch.match(/^release\//)) {
              const version = targetBranch.match(/^release\/(.*)$/)[1];
              console.log(
                `Target branch is a release, adding changes to version ${version} section...`
              );
              newContent = changelogGenerator.addToVersion(
                content,
                version,
                commits
              );
            } else {
              console.error(`Unexpected target branch: ${targetBranch}`);
            }

            if (newContent) {
              console.log("Updating CHANGELOG wiki page with content:");
              console.log("--- NEW CONTENT ---");
              console.log(newContent);
              console.log("--- /NEW CONTENT ---");
              const response = await gitLabService.editChangelogWikiPage(
                newContent
              );
              console.log(response);
            } else {
              console.error("Error generating new content for CHANGELOG");
            }
          } else {
            console.log(
              "CHANGELOG wiki page found but had no content. Generating new wiki page."
            );
            const content = await changelogGenerator.generate(commits);
            const response = await gitLabService.createChangelogWikiPage(
              content
            );
            console.log(response);
          }
        })
        .catch(async (err) => {
          console.error(err);
          console.log(
            "Could not find CHANGELOG wiki page, generating new wiki page"
          );
          const content = await changelogGenerator.generate(commits);
          const response = gitLabService.createChangelogWikiPage(content);
          console.log(response);
        });
    } catch (err) {
      console.error(err);
      process.exit(1);
    }
  }
}

main();
