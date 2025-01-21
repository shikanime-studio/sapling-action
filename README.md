# ghstack GitHub Action

This GitHub Action is a tool that enables you to land pull requests using
ghstack directly from GitHub Pull Requests web interface. It adds a command that
can be used in pull request comments to check the status and automatically land
the PR using ghstack.

## Required Permissions

For this action to work properly, the GitHub App needs to be configured with the
following repository permissions:

- `contents: write` - To push changes when landing the PR
- `pull-requests: write` - To update and merge pull requests

These permissions must be set in the GitHub App settings interface.

## Workflow Configuration

Add the following to your `.github/workflows/ghstack.yml`:

```yaml
name: ghstack
on:
  issue_comment:
    types: [created]
jobs:
  ghstack:
    runs-on: ubuntu-latest
    steps:
      - uses: shikanime/ghstack-actions@main
        with:
          app-id: ${{ secrets.APP_ID }}
          private-key: ${{ secrets.PRIVATE_KEY }}
```

This configuration will enable the ghstack action to run whenever a comment is
added to a pull request.


## Usage

To use the ghstack action, add the following command to a comment in a pull
request for a ghstack pull request:

```
.land | ghstack
```

and a classic pull request:

```
.land | pr
```

This command will check the status of the pull request and, if it is ready to be
landed, it will automatically land the pull request using ghstack.

To rebase and update your pull requests with the latest changes from the main
branch, use the following command:

```
.rebase
```

## Repository Rules Configuration

To ensure secure and efficient development workflow, we recommend configuring
the following GitHub repository rules for branch protection and PR review
requirements:

### Main Branch Protection

Configure these essential settings to protect your main branch:

- Enable linear commit history to maintain a clean git history
- Require signed commits for security verification
- Apply rules specifically to refs/heads/main branch

Example configuration:

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
  }
}
```

### Pull Request Requirements

Configure these essential settings for pull request quality control:

- Require resolution of all review threads before merging to ensure thorough
  code review
- Require all status checks to pass for comprehensive validation and quality
  assurance

This configuration enables the ghstack app to bypass restrictions for stack
landing operations while maintaining standard PR merge capabilities for
developers. It enforces a structured workflow where changes must be integrated
into the main branch through pull requests.

Example configuration:

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
        context = "check"
      }
      strict_required_status_checks_policy = true
    }
  }
}
```
