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
   * @param {string} commit_tag Referencia del tag
   */
  getTag(commit_tag) {
    console.log(
      `Fetching ${this.baseUrl}/projects/${this.projectId}/repository/tags/${commit_tag}`
    );
    return fetch(
      `${this.baseUrl}/projects/${this.projectId}/repository/tags/${commit_tag}`,
      {
        method: "GET",
        headers: {
          "User-Agent": "request",
          Authorization: `Bearer ${this.token}`,
          "Content-Type": "application/json"
        }
      }
    ).then((response) => {
      if (!response.ok) {
        throw `The server responded with ${response.statusText}`;
      }

      return response.json();
    });
  }

  /**
   */
  getTags() {
    console.log(
      `[INFO] GET ${this.baseUrl}/projects/${this.projectId}/repository/tags`
    );

    return fetch(`${this.baseUrl}/projects/${this.projectId}/repository/tags`, {
      method: "GET",
      headers: {
        "User-Agent": "request",
        Authorization: `Bearer ${this.token}`,
        "Content-Type": "application/json"
      }
    }).then((response) => {
      if (!response.ok) {
        throw `The server responded with ${response.statusText}`;
      }

      return response.json();
    });
  }

  /**
   *
   * @param {string} commit_tag Referencia del tag
   */
  getTagBranchRefs(commitId) {
    console.log(
      `Fetching ${this.baseUrl}/projects/${this.projectId}/repository/commits/${commitId}/refs?type=branch`
    );
    return fetch(
      `${this.baseUrl}/projects/${this.projectId}/repository/commits/${commitId}/refs?type=branch`,
      {
        method: "GET",
        headers: {
          "User-Agent": "request",
          Authorization: `Bearer ${this.token}`,
          "Content-Type": "application/json"
        }
      }
    ).then((response) => {
      if (!response.ok) {
        throw `The server responded with ${response.statusText}`;
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
    console.log(
      `Fetching ${this.baseUrl}/projects/${this.projectId}/repository/tags`
    );
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

  /**
   *
   * @param {BranchRequest} branch
   * @param {string} branch.branch Etiqueta a generar
   * @parma {string} branch.ref Referencia GIT sobre la que generar rama
   */
  createBranch(branch) {
    console.log(
      `Fetching ${this.baseUrl}/projects/${this.projectId}/repository/branches`
    );
    return fetch(
      `${this.baseUrl}/projects/${this.projectId}/repository/branches`,
      {
        method: "POST",
        headers: {
          "User-Agent": "request",
          Authorization: `Bearer ${this.token}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify(branch)
      }
    ).then((response) => {
      if (!response.ok) {
        throw `The server responded with ${response.statusText}`;
      }

      return response.json();
    });
  }

  /**
   *
   * @param {CompareRequest} request
   * @param {string} request.from Etiqueta a generar
   * @parma {string} request.to Referencia GIT sobre la que generar rama
   */
  compare(request) {
    console.log(
      `Fetching ${this.baseUrl}/projects/${this.projectId}/repository/compare?from=${request.from}&to=${request.to}`
    );
    return fetch(
      `${this.baseUrl}/projects/${this.projectId}/repository/compare?from=${request.from}&to=${request.to}`,
      {
        method: "GET",
        headers: {
          "User-Agent": "request",
          Authorization: `Bearer ${this.token}`,
          "Content-Type": "application/json"
        }
      }
    ).then((response) => {
      if (!response.ok) {
        throw `The server responded with ${response.statusText}`;
      }

      return response.json();
    });
  }

  createCommit(commit) {
    console.log(
      `Fetching ${this.baseUrl}/projects/${this.projectId}/repository/commits`
    );
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

  /**
   *
   * @param {MRRequest} mergeRequest
   * @param {string} mergeRequest.title Nombre del R
   * @param {string} mergeRequest.source_branch Rama origen
   * @param {string} mergeRequest.target_branch  Rama destino
   */
  createMergeRequest(mergeRequest) {
    console.log(
      `Fetching ${this.baseUrl}/projects/${this.projectId}/merge_requests`
    );
    return fetch(`${this.baseUrl}/projects/${this.projectId}/merge_requests`, {
      method: "POST",
      headers: {
        "User-Agent": "request",
        Authorization: `Bearer ${this.token}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(mergeRequest)
    }).then((response) => {
      if (!response.ok) {
        throw `The server responded with ${response.statusText}`;
      }

      return response.json();
    });
  }

  /**
   *
   * @param {MROptionsRequest} options
   * @param {Boolean} mergeRequest.squash
   * @param {Boolean} mergeRequest.should_remove_source_branch
   */
  acceptMergeRequest(iid, options) {
    console.log(
      `Fetching ${this.baseUrl}/projects/${this.projectId}/merge_requests/${iid}/merge`
    );
    return fetch(
      `${this.baseUrl}/projects/${this.projectId}/merge_requests/${iid}/merge`,
      {
        method: "PUT",
        headers: {
          "User-Agent": "request",
          Authorization: `Bearer ${this.token}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify(options)
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
