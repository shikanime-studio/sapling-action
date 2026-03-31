# Agents

This repository provides comment-driven agents (composite actions) that
automate common PR operations. Add them to workflows as shown in README,
then trigger via PR comments.

## Comment Commands

- .land
  - Lands the current PR using the publication method determined from the
    stack or an explicit param.
  - Usage: `.land` or `.land | ghstack|slpr|ghpr`
  - Permissions: contents: write, issues: write, pull-requests: write
  - Action: `shikanime-studio/actions/land`

- .rebase
  - Rebases the current PR on its base branch.
  - Usage: `.rebase`
  - Permissions: contents: write, issues: write
  - Action: `shikanime-studio/actions/rebase`

- .close
  - Closes the current PR and optionally cleans up remote branches,
    depending on stack method.
  - Usage: `.close`
  - Permissions: pull-requests: write, contents: write, issues: write
  - Action: `shikanime-studio/actions/close`

- .backport
  - Backports the current PR onto a target branch. Supports ghstack,
    sapling PRs, and GitHub PRs.
  - Usage: `.backport | <target-branch>`
  - Permissions: contents: write, pull-requests: write, issues: write
  - Action: `shikanime-studio/actions/backport`

- .run
  - Triggers a workflow dispatch on the same repository using GitHub CLI.
  - Usage: `.run | <workflow-name-or-path>`
  - Notes: The target workflow must have `workflow_dispatch` enabled.
    Runs against the PR head ref.
  - Permissions: actions: write (plus minimal read on contents/PRs)
  - Action: `shikanime-studio/actions/run`

## Non-Comment Workflows

- update
  - Updates flake inputs and publishes via ghstack/sapling/GitHub PR,
    depending on configuration.
  - Typical usage: scheduled or manual workflow with `workflow_dispatch`.
  - Action: `shikanime-studio/actions/update`

- cleanup
  - Deletes branches after PR merge/close (stack-aware).
  - Trigger: `pull_request: closed`
  - Action: `shikanime-studio/actions/cleanup`

## Utilities

- stack
  - Determines stack method and parent PR detection; used internally by
    multiple agents.
  - Action: `shikanime-studio/actions/stack`

## Nix Matrix Helpers

- nix/setup-checks
  - Produces a matrix of `{ system, runner }` for checks from flake outputs.
  - Input `systems`: JSON object `{ runner: [systems...] }`.

- nix/setup-packages
  - Produces a matrix of `{ system, runner, name }` for package builds.
  - Inputs: `systems` as above; `excludes` JSON array of package names
    (defaults include `devenv-up`, `devenv-test`).
