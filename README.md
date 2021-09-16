Rust Lambda Builder
===================

![GitHub](https://img.shields.io/github/license/sevco/rust-lambda-action)
![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/sevco/rust-lambda-action)
![GitHub Workflow Status](https://img.shields.io/github/workflow/status/sevco/rust-lambda-action/CI)
![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/sevcosec/rust-lambda-action)
![Docker Image Version (latest semver)](https://img.shields.io/docker/v/sevcosec/rust-lambda-action)

GitHub action for building statically linked Rust binaries (x86_64-unknown-linux-musl) packaged for [AWS Lambda](https://aws.amazon.com/blogs/opensource/rust-runtime-for-aws-lambda/). Based on [emk/rust-musl-builder](https://github.com/emk/rust-musl-builder).

```yaml
- uses: sevco/rust-lambda-action@v1.0.0
  with:
    args: build --release --all-features
    credentials: ${{ secrets.GIT_CREDENTIALS }}
    cargo_config: |
      [registry]
      default = "…"
      token = "…"
  ```
  ### Inputs
  | Variable | Description | Required | Default |
  |----------|-------------|----------|---------|
  | credentials | If provided git will be configured to use these credentials and https | false | |
  | directory | Relative path under $GITHUB_WORKSPACE where Cargo project is located | false | |
  | cargo_config | Cargo configuration to use in addition to Lambda configs | false |

  ### Output
  `$directory/target/lambda/$project.zip`