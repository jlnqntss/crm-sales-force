const fetch = require("node-fetch");

class GitlabAPIService {
  constructor(args) {
    this.baseUrl = args.baseUrl || process.env["CI_API_V4_URL"];
    this.projectId = args.projectId || process.env["CI_PROJECT_ID"];
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
    }).then((response) => {
      if (!response.ok) {
        throw `The server responded with ${response.status}: ${response.statusText}`;
      }

      return response.json();
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
    }).then((response) => {
      if (!response.ok) {
        throw `The server responded with ${response.status}: ${response.statusText}`;
      }

      return response.json();
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
    }).then((response) => {
      if (!response.ok) {
        throw `The server responded with ${response.status}: ${response.statusText}`;
      }

      return response.json();
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
    }).then((response) => {
      if (!response.ok) {
        throw `The server responded with ${response.statusText}`;
      }

      return response.json();
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
    ).then((response) => {
      if (!response.ok) {
        throw `The server responded with ${response.statusText}`;
      }

      return response.json();
    });
  }
}

module.exports.default = GitlabAPIService;
