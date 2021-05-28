# Contribution guide
<!-- markdownlint-disable MD013 -->
Trivadis expressly welcomes all contributions to this repository from anyone.

If you want to submit a pull request to fix a bug or improve an existing good
practice, please open an issue first and link to that issue when you submit your
pull request.

If you have any questions about a possible submission, feel free to open an issue too.

## Contributing to the *Good Practice* Guide

All contributors are expected to adhere to our [code of conduct](CODE_OF_CONDUCT.md).

For pull requests to be accepted, the bottom of your commit message must have
the following line using your name and e-mail address.

```bash
Signed-off-by: Your Name <you@example.org>
```

This will be automatically added to pull requests if you using the `signoff`
parameter when committing your changes:

```bash
  git commit [--signoff|-S]
```

## *Good Practice* ownership and responsibility

The *Good Practice* are provided on behalf of Trivadis. Accordingly, changes and
enhancements are always reviewed by a Trivadis peer. However, the individual
*Good Practice* rules are worked out individually. Please make sure, that you
are familiar with the approval process to submit code to an existing GitHub
repository. The *Good Practice* owner will also be assigned to any issues
relating to their content.

You must ensure that you check the [issues](https://github.com/Trivadis/good-practice-template/issues)
on at least a weekly basis, though daily is preferred.

Contact [Stefan Oehrli](https://github.com/oehrlis) for more information.

### Pull request process

1. Fork this repository
1. Create a branch in your fork to implement the changes. We recommend using
the issue number as part of your branch name, e.g. `1234-fixes`
1. Ensure that any documentation is updated with the changes that are required
by your fix.
1. Ensure that any samples are updated if the base image has been changed.
1. Submit the pull request. *Do not leave the pull request blank*. Explain exactly
what your changes are meant to do and provide simple steps on how to validate
your changes. Ensure that you reference the issue you created as well.
We will assign the pull request to 1-2 people for review before it is merged.

## Golden Rules

We have some golden rules that all submitted *Good Practice* must adhere to.
These rules are provided by Trivadis Knowledge Management and may change at any time.

Most of these are targeted at Trivadis employees, but apply to anyone who submits
a pull request.

### Basic rules for *Good Practice*

1. First check if this issue / enhancement for the *Good Practice* w already exists. See [issues](https://github.com/Trivadis/good-practice-template/issues)
2. Extend an existing *Good Practice* wherever possible rather than create new ones.
3. Follow the KISS principle. keep it simple, stupid

### Security-related rules

1. Do not hard-code any passwords or ssh keys.
1. No information about customers
1. No particularly sensitive personal data (age, health, etc.)
1. Whenever possible, please avoid personal data in the documentation

### Documentation rules

1. No host or domain names should be included in any code or examples.
   If an example domain name is required, use `example.com`.
2. All documentation including `README.md` files needs to meet Markdown Lint we do in particular use [markdownlint](https://github.com/DavidAnson/markdownlinthttps://github.com/DavidAnson/markdownlint) from David Anson.

### Guidelines and recommendations

The following are some guidelines that will not prevent a *Good Practice* from being
merged, but are generally frowned upon if breached.

- to be documented
