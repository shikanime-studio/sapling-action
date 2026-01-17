# Actions

This repository provides a set of GitHub Actions that let you land, rebase,
close, backport, and update pull requests using Sapling, ghstack, and jujutsu
directly from the GitHub Pull Request web interface. Each command is triggered
from PR comments and handled by a dedicated action.

## Required Permissions

For the action to work properly when used via a GitHub App, the App must be
configured with at least the following repository permissions:

- `contents: write` – to push changes when landing the PR
- `pull-requests: write` – to update and merge pull requests

Configure these permissions in the GitHub App settings.

## Workflow Configuration

Add a workflow like the following to `.github/workflows/commands.yaml` to wire
all comment-driven commands to their corresponding actions:

```yaml
name: sapling
on:
  issue_comment:
    types: [created]
permissions:
  contents: write
  pull-requests: write
jobs:
  sapling:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: shikanime-studio/setup-nix-action@v1
      - uses: shikanime-studio/actions/land@v7
        with:
          gpg-passphrase: ${{ secrets.GPG_PASSPHRASE }}
          gpg-private-key: ${{ secrets.GPG_PRIVATE_KEY }}
          sign-commits: true
      - uses: shikanime-studio/actions/rebase@v7
        with:
          gpg-passphrase: ${{ secrets.GPG_PASSPHRASE }}
          gpg-private-key: ${{ secrets.GPG_PRIVATE_KEY }}
          sign-commits: true
      - uses: shikanime-studio/actions/close@v7
      - uses: shikanime-studio/actions/backport@v7
        with:
          gpg-passphrase: ${{ secrets.GPG_PASSPHRASE }}
          gpg-private-key: ${{ secrets.GPG_PRIVATE_KEY }}
          sign-commits: true
```

Or, when using a GitHub App:

```yaml
name: sapling
on:
  issue_comment:
    types: [created]
jobs:
  sapling:
    runs-on: ubuntu-latest
    steps:
      - id: createGithubAppToken
        uses: actions/create-github-app-token@v1
        with:
          app-id: ${{ vars.APP_ID }}
          private-key: ${{ secrets.PRIVATE_KEY }}
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          github-token: ${{ steps.createGithubAppToken.outputs.token }}
      - uses: shikanime-studio/setup-nix-action@v1
        with:
          github-token: ${{ steps.createGithubAppToken.outputs.token }}
      - uses: shikanime-studio/actions/land@v7
        with:
          github-token: ${{ steps.createGithubAppToken.outputs.token }}
          gpg-passphrase: ${{ secrets.GPG_PASSPHRASE }}
          gpg-private-key: ${{ secrets.GPG_PRIVATE_KEY }}
          sign-commits: true
      - uses: shikanime-studio/actions/rebase@v7
        with:
          github-token: ${{ steps.createGithubAppToken.outputs.token }}
          gpg-passphrase: ${{ secrets.GPG_PASSPHRASE }}
          gpg-private-key: ${{ secrets.GPG_PRIVATE_KEY }}
          sign-commits: true
      - uses: shikanime-studio/actions/close@v7
        with:
          github-token: ${{ steps.createGithubAppToken.outputs.token }}
      - uses: shikanime-studio/actions/backport@v7
        with:
          github-token: ${{ steps.createGithubAppToken.outputs.token }}
          gpg-passphrase: ${{ secrets.GPG_PASSPHRASE }}
          gpg-private-key: ${{ secrets.GPG_PRIVATE_KEY }}
          sign-commits: true
```

These examples configure the actions to run whenever a comment is added to a
pull request.

## Usage

### Land

To land a ghstack pull request, comment on the PR with:

```
.land | ghstack
```

For a classic pull request:

```
.land | pr
```

The land action checks the status of the pull request and, if it is ready,
lands it using ghstack.

### Rebase

To rebase and update your pull request on top of the latest changes from the
main branch, comment:

```
.rebase
```

### Close

To close a pull request with a comment command, use:

```
.close
```

You can optionally specify a method (for example `ghstack`, `slpr`, or `ghpr`)
as a parameter:

```
.close | ghstack
```

### Backport

To create a backport pull request targeting another branch, comment:

```
.backport | release-1.0
```

## Repository Rules Configuration

To support a secure and efficient workflow, we recommend configuring GitHub
repository rules for branch protection and pull request review requirements:

### Main Branch Protection

Configure the main branch with:

- Linear commit history to keep history easy to follow
- Required signed commits for verification
- Rules applied specifically to `refs/heads/main`

Example:

```terraform
resource "github_repository_ruleset" "main" {
  name        = "Main branch protections"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/main"]
    }
  }

  rules {
    required_linear_history = true
    required_signatures     = true
  }
}
```

### Pull Request Requirements

Configure pull request requirements to:

- Require resolution of all review threads before merging
- Require all status checks to pass

This setup lets the ghstack app bypass restrictions for stack landing operations
while keeping standard PR merge behavior for developers. It enforces a workflow
where changes reach `main` through pull requests.

Example:

```terraform
resource "github_repository_ruleset" "landing" {
  name        = "Landing protections"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/main"]
    }
  }

  bypass_actors {
    actor_id    = "<app-id>"
    actor_type  = "Integration"
    bypass_mode = "always"
  }

  rules {
    pull_request {
      required_review_thread_resolution = true
    }
    required_status_checks {
      required_check {
        context        = "check"
        integration_id = 15368 # GitHub Actions
      }
      strict_required_status_checks_policy = true
    }
  }
}
```
