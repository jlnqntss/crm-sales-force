export default class GitlabAPIController {
  constructor(args) {
    (this.baseUrl = args.baseUrl || process.env["CI_API_V4_URL"]),
      (this.projectId = args.projectId || process.env["CI_PROJECT_ID"]);
    this.token = args.token || process.env["CI_GITLAB_TOKEN"];
  }

  getChangelogWikiPage() {
    return fetch(`${this.baseUrl}/projects/${this.projectId}/wikis/CHANGELOG`, {
      method: "GET",
      headers: {
        "User-Agent": "request",
        Authorization: `Bearer ${this.token}`,
        "Content-Type": "application/json"
      }
    });
  }

  createChangelogWikiPage(content) {
    return fetch(`${this.baseUrl}/projects/${this.projectId}/wikis`, {
      method: "POST",
      headers: {
        "User-Agent": "request",
        Authorization: `Bearer ${this.token}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        title: "CHANGELOG",
        content,
        format: "markdown"
      })
    });
  }

  editChangelogWikiPage(content) {
    return fetch(`${this.baseUrl}/projects/${this.projectId}/wikis/CHANGELOG`, {
      method: "PUT",
      headers: {
        "User-Agent": "request",
        Authorization: `Bearer ${this.token}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        title: "CHANGELOG",
        content
      })
    });
  }

  getMergeRequestCommits(mergeRequestIid) {
    return new Promise((resolve, reject) => {
      const requestOptions = {
        url: `${this.baseUrl}/projects/${this.projectId}/merge_requests/${mergeRequestIid}/commits`,
        headers: {
          "User-Agent": "request",
          Authorization: `Bearer ${this.token}`
        }
      };
      request(requestOptions, (err, response, body) => {
        if (err) {
          reject(err);
        } else {
          resolve(JSON.parse(body));
        }
      });
    });
  }

  /**
   *
   * @param {TagRequest} tag
   * @param {string} tag,tagName Etiqueta a generar
   * @parma {string} ref Referencia GIT a atiquetar
   */
  createTag(tag) {
    return fetch(`${this.baseUrl}/projects/${this.projectId}/repository/tags`, {
      method: "POST",
      headers: {
        "User-Agent": "request",
        Authorization: `Bearer ${this.token}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(tag)
    });
  }

  createCommit(commit) {
    return fetch(
      `${this.baseUrl}/projects/${this.projectId}/repository/commits`,
      {
        method: "POST",
        headers: {
          "User-Agent": "request",
          Authorization: `Bearer ${this.token}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify(commit)
      }
    );
  }
}
