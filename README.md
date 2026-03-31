# Actions

This repository provides a set of GitHub Actions that let you land, rebase,
close, backport, and update pull requests using Sapling, ghstack, and jujutsu
directly from the GitHub Pull Request web interface. Each command is triggered
from PR comments and handled by a dedicated action.

## Required Permissions

Required permissions depend on the action being executed. When using a GitHub
App token, configure repository permissions accordingly:

- Land: contents: write, pull-requests: write, issues: write
- Rebase: contents: write, issues: write
- Close: pull-requests: write, contents: write, issues: write
- Backport: contents: write, pull-requests: write, issues: write
- Update: contents: write, pull-requests: write, issues: write
- Cleanup: contents: write

Permissions can be configured at the workflow level or per job. The examples
below set them at the workflow level and request matching scopes from the
GitHub App via actions/create-github-app-token.

## Workflow Configuration

Add a workflow like the following to `.github/workflows/commands.yaml` to wire
comment-driven commands to their corresponding actions. This example reflects
the current setup used in `.github/workflows/commands.yaml`:

```yaml
name: Command
'on':
  issue_comment:
    types:
      - created
permissions:
  contents: write
  issues: write
  pull-requests: write
jobs:
  land:
    if: >-
      github.event.issue.pull_request != null &&
      contains(github.event.comment.body, '.land')
    runs-on: ubuntu-slim
    steps:
      - continue-on-error: true
        id: createGithubAppToken
        uses: actions/create-github-app-token@v2
        with:
          app-id: ${{ vars.OPERATOR_APP_ID }}
          permission-contents: write
          permission-issues: write
          permission-pull-requests: write
          private-key: ${{ secrets.OPERATOR_PRIVATE_KEY }}
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
          token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
      - uses: cachix/install-nix-action@v31
        with:
          github_access_token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
      - uses: shikanime-studio/actions/command/land@main
        with:
          email: operator6o@shikanime.studio
          fullname: Operator 6O
          github-token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
          gpg-passphrase: ${{ secrets.GPG_PASSPHRASE }}
          gpg-private-key: ${{ secrets.GPG_PRIVATE_KEY }}
          sign-commits: true
          username: operator6o
  rebase:
    if: >-
      github.event.issue.pull_request != null &&
      contains(github.event.comment.body, '.rebase')
    runs-on: ubuntu-slim
    steps:
      - continue-on-error: true
        id: createGithubAppToken
        uses: actions/create-github-app-token@v2
        with:
          app-id: ${{ vars.OPERATOR_APP_ID }}
          permission-contents: write
          permission-issues: write
          permission-pull-requests: write
          private-key: ${{ secrets.OPERATOR_PRIVATE_KEY }}
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
          token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
      - uses: cachix/install-nix-action@v31
        with:
          github_access_token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
      - uses: shikanime-studio/actions/command/rebase@main
        with:
          email: operator6o@shikanime.studio
          fullname: Operator 6O
          github-token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
          gpg-passphrase: ${{ secrets.GPG_PASSPHRASE }}
          gpg-private-key: ${{ secrets.GPG_PRIVATE_KEY }}
          sign-commits: true
          username: operator6o
  close:
    if: >-
      github.event.issue.pull_request != null &&
      contains(github.event.comment.body, '.close')
    runs-on: ubuntu-slim
    steps:
      - continue-on-error: true
        id: createGithubAppToken
        uses: actions/create-github-app-token@v2
        with:
          app-id: ${{ vars.OPERATOR_APP_ID }}
          permission-contents: write
          permission-issues: write
          permission-pull-requests: write
          private-key: ${{ secrets.OPERATOR_PRIVATE_KEY }}
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
          token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
      - uses: cachix/install-nix-action@v31
        with:
          github_access_token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
      - uses: shikanime-studio/actions/command/close@main
        with:
          github-token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
          username: operator6o
  backport:
    if: >-
      github.event.issue.pull_request != null &&
      contains(github.event.comment.body, '.backport')
    runs-on: ubuntu-slim
    steps:
      - continue-on-error: true
        id: createGithubAppToken
        uses: actions/create-github-app-token@v2
        with:
          app-id: ${{ vars.OPERATOR_APP_ID }}
          permission-contents: write
          permission-issues: write
          permission-pull-requests: write
          private-key: ${{ secrets.OPERATOR_PRIVATE_KEY }}
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
          token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
      - uses: cachix/install-nix-action@v31
        with:
          github_access_token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
      - uses: shikanime-studio/actions/command/backport@main
        with:
          github-token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
          gpg-passphrase: ${{ secrets.GPG_PASSPHRASE }}
          gpg-private-key: ${{ secrets.GPG_PRIVATE_KEY }}
          sign-commits: true
```

## Nix Matrix Actions

Use the composite actions to generate matrices for checks and packages.

```yaml
jobs:
  setup-checks:
    runs-on: ubuntu-latest
    outputs:
      continue: ${{ steps.matrix.outputs.continue }}
      matrix: ${{ steps.matrix.outputs.matrix }}
    steps:
      - id: matrix
        uses: ./nix/setup-checks
        with:
          systems: >-
            {
              "ubuntu-latest": ["x86_64-linux"],
              "ubuntu-24.04-arm": [
                "aarch64-linux",
                "armv6l-linux",
                "armv7l-linux"
              ]
            }

  checks:
    needs: [setup-checks]
    if: needs.setup-checks.outputs.continue == 'true'
    runs-on: ${{ matrix.runner }}
    strategy:
      fail-fast: false
      matrix:
        include: >-
          ${{ fromJSON(needs.setup-checks.outputs.matrix) }}
    steps:
      - run: nix flake check \
          --accept-flake-config \
          --no-pure-eval \
          --system "${{ matrix.system }}"

  setup-packages:
    runs-on: ubuntu-latest
    outputs:
      continue: ${{ steps.matrix.outputs.continue }}
      matrix: ${{ steps.matrix.outputs.matrix }}
    steps:
      - id: matrix
        uses: ./nix/setup-packages
        with:
          systems: >-
            {
              "ubuntu-latest": ["x86_64-linux"],
              "ubuntu-24.04-arm": ["aarch64-linux"]
            }
          excludes: '["devenv-up","devenv-test"]'

  packages:
    needs: [setup-packages]
    if: needs.setup-packages.outputs.continue == 'true'
    runs-on: ${{ matrix.runner }}
    strategy:
      fail-fast: false
      matrix:
        include: >-
          ${{ fromJSON(needs.setup-packages.outputs.matrix) }}
    steps:
      - run: nix build \
          --accept-flake-config \
          --no-pure-eval \
          ".#packages.${{ matrix.system }}.${{ matrix.name }}"
```

## Run Workflow

Trigger a workflow dispatch from a PR comment:

- Comment format: `.run | <workflow>`
- `<workflow>` can be a workflow name or a workflow file path.
- The target workflow must have `workflow_dispatch` enabled.
- The job token needs `actions: write`.

Example job:

```yaml
  run:
    if: >-
      github.event.issue.pull_request != null &&
      contains(github.event.comment.body, '.run')
    permissions:
      actions: write
      issues: write
      pull-requests: read
    runs-on: ubuntu-slim
    steps:
      - continue-on-error: true
        id: createGithubAppToken
        uses: actions/create-github-app-token@v3
        with:
          app-id: ${{ vars.OPERATOR_APP_ID }}
          permission-actions: write
          permission-issues: write
          permission-pull-requests: read
          private-key: ${{ secrets.OPERATOR_PRIVATE_KEY }}
      - uses: shikanime-studio/actions/command/run@main
        with:
          github-token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
```

To automate dependency updates and repository hygiene, you can also add a
scheduled workflow for updates that uses the `update` action:

```yaml
name: Update
'on':
  schedule:
    - cron: 0 4 * * 0
  workflow_dispatch:
jobs:
  dependencies:
    runs-on: ubuntu-slim
    steps:
      - continue-on-error: true
        id: createGithubAppToken
        uses: actions/create-github-app-token@v2
        with:
          app-id: ${{ vars.OPERATOR_APP_ID }}
          permission-contents: write
          permission-issues: write
          permission-pull-requests: write
          private-key: ${{ secrets.OPERATOR_PRIVATE_KEY }}
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
          token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
      - uses: cachix/install-nix-action@v31
        with:
          github_access_token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
      - uses: shikanime-studio/actions/update@v7
        with:
          gpg-passphrase: ${{ secrets.GPG_PASSPHRASE }}
          gpg-private-key: ${{ secrets.GPG_PRIVATE_KEY }}
          sign-commits: true
  stale:
    runs-on: ubuntu-slim
    steps:
      - continue-on-error: true
        id: createGithubAppToken
        uses: actions/create-github-app-token@v2
        with:
          app-id: ${{ vars.OPERATOR_APP_ID }}
          permission-contents: write
          permission-issues: write
          permission-pull-requests: write
          private-key: ${{ secrets.OPERATOR_PRIVATE_KEY }}
      - uses: actions/stale@v10
        with:
          days-before-close: 14
          days-before-stale: 30
          repo-token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
```

To automatically delete branches after a pull request is merged or closed, add a
cleanup workflow to `.github/workflows/cleanup.yaml`:

```yaml
name: Cleanup
'on':
  pull_request:
    types:
      - closed
jobs:
  cleanup:
    runs-on: ubuntu-slim
    steps:
      - continue-on-error: true
        id: createGithubAppToken
        uses: actions/create-github-app-token@v2
        with:
          app-id: ${{ vars.OPERATOR_APP_ID }}
          permission-contents: write
          private-key: ${{ secrets.OPERATOR_PRIVATE_KEY }}
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
          token: >-
            ${{ steps.createGithubAppToken.outputs.token
                || secrets.GITHUB_TOKEN }}
      - uses: shikanime-studio/actions/cleanup@v7
```
