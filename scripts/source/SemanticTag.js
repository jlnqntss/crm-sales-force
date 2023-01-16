class SemanticTag {
  constructor(tag) {
    let tagTokens = tag.name.split("-");
    let tagVersionTokens = tagTokens[0].split(".");

    this.suffix = tagTokens[1] || "";
    (this.major = parseInt(tagVersionTokens[0], 0)),
      (this.minor = parseInt(tagVersionTokens[1], 0)),
      (this.patch = parseInt(tagVersionTokens[2], 0));
  }

  toString() {
    let version = `${this.major}.${this.minor}.${this.patch}`;

    if (this.suffix) {
      version += "-" + this.suffix;
    }

    return version;
  }

  bump(commits) {
    if (commits && commits.length) {
      commits.forEach((commit) => {
        if (commit.message && commit.message.includes("BREAKING CHANGE")) {
          this.major++;
          this.minor = 0;
          this.patch = 0;
        } else if (commit.message.startsWith("feat:")) {
          this.minor++;
          this.patch = 0;
        } else if (commit.message.startsWith("fix:")) {
          this.patch++;
        }
      });
    }

    return this;
  }
}

function getLastSemanticTag(tags, format) {
  let orderedTags = tags
    .filter((tag) => {
      return tag.name.match(format);
    })
    .sort((firstTag, secondTag) => {
      let firstTagVersion = new SemanticTag(firstTag);
      let secondTagVersion = new SemanticTag(secondTag);

      if (firstTagVersion.major === secondTagVersion.major) {
        if (firstTagVersion.minor === secondTagVersion.minor) {
          return secondTagVersion.patch - firstTagVersion.patch;
        }

        return secondTagVersion.minor - firstTagVersion.minor;
      }

      return secondTagVersion.major - firstTagVersion.major;
    });

  return orderedTags[0];
}

module.exports = {
  SemanticTag,
  getLastSemanticTag
};
