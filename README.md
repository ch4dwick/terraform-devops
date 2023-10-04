# Simple Terraform DevOps Workflow

## Use Case

- Assume you are managing a team of DevOps maintaining two or more accounts.

- For security and safety reasons, you need to review and confirm Terraform infra changes before they are applied, preventing your team from inadvertently applying an unauthorized change.

You may customize this project to suit your needs.

## Prerequisites

- Latest version of terraform cli
- Latest version of aws-cli v2
- An S3 bucket in each account or a shared bucket with read and write permissions to store the Terraform state files.
- AWS read-only permissions for DevOps working on these scripts. This ensures that they can preview the changes but not apply them. A bare minimum would at least have read access to the S3 buckets for the state files.
- AWS IAM read-write credentials for each account that this script will be applied. A bare minimum would at least have read-write access to the S3 buckets for the state files.
- Permissions to run Github actions.
- Permissions to create and view github environment secrets.
- PAT token with repository read-write permissions for use with manual commits in tfplan.yaml & tag-manual.yaml.

## Conventions

This project follows a naming convention to properly apply.

Refer to [tf-plan.yaml](.github/workflows/tf-plan.yaml) and [tf-apply.yaml](.github/workflows/tf-apply.yaml).

The Github action assumes the following string patterns.

### Environment secrets

This pattern will be widely used in most actions to validate, plan, and apply the changes.

\<target account>/AWS_ACCESS_KEY_ID

\<target account>/AWS_SECRET_ACCESS_KEY

e.g.

```yaml
account1
    AWS_ACCESS_KEY_ID: 123456789012345
    AWS_SECRET_ACCESS_KEY: xxxxxxx
account1
    AWS_ACCESS_KEY_ID: 000000000232323
    AWS_SECRET_ACCESS_KEY: xxxxxxx
```

If you have multiple accounts, better to use gh-cli to speed automate the creation of each entry. You can also use Terraform to automate the creation of the same IAM and permissions on each AWS account that this project will maintain.

### Branch naming

The branch name must be prefixed with the account name, followed by your branch label. This pattern will be used by pr-closed.yaml.

e.g.

```bash
git checokut -b account1/new-ec2
```

### Tagging

The tag must be prefixed with the account name followed by any string identifier. This pattern will be used by tf-apply.yaml.

e.g.

```bash
git tag account1-v01 && git push origin account1-v01
```

## Inititialize local environment

This will pull the current state, if it exists, or create a new one.

```bash
cd account1
terraform init
cd account2
terraform init
```

## Validate your scripts

```bash
terraform validate
```

or for an initial assessment.

```bash
terraform plan
```

Create / Update Resources

```bash
terraform apply
```

It is recommended only the lead DevOps has permissions to apply changes.

Note: Updates are NOT guaranteed. Depending on the resource, it will either be updated or recreated (destroy & create).

## Typical workflow

1. Create new branch prefixed with the target account where the changes will be applied.
2. Create/Update terraform scripts as needed.
3. Run terraform plan to verify changes. (DevOps with full read-only access)
4. Push changes.
5. Create & Submit PR for review.
6. Once merged, pr-closed.yaml action is triggered and generates the \<account>.tfplan then pushes it to the repository in tfplan/\*\* folder.

- The Github action will generate the tfplan file but NOT apply it. For convenience, the tfplan output can be viewed in your [actions](actions/workflows/pr-closed.yaml).

### Optional: If the Senior DevOps needs to test locally.

7. Pull latest from main branch.
8. Review plan file.
9. Once confirmed, the commit is tagged for deployment. If not, revise the plan from source branch, NEVER the main branch as any correction needs to generate a new *.tfplan.

- Tagging a commit will trigger the tf-apply.yaml action and apply the changes to the target account. The action can be cancelled as long as the apply process is not in progress. Avoid terminating the action when it is at this step as this can lead to a corrupted state.

# Via GitHub Actions

## Tagging

### https://github.com/ch4dwick/terraform-devops/actions/workflows/tag-manual.yaml

On routine commits that do not contain drastic changes to the infrastructure, tagging the latest commit manually will suffice. Note that the parameter accepted must match the naming convention defined in the rollout process.

## Manual plan

Stale state and plan file (very rare)

### https://github.com/ch4dwick/terraform-devops/actions/workflows/pr-manual-plan.yaml

On rare occasions, an action might fail after pushing a new tag. Firstly, check if you pulled the latest codes before tagging. A stale error will happen if you tag an older commit. If the commit is the latest and you still get a stale state plan, try generating a new tfplan file by running the pr-manual-plan.yaml action manually. You can select which environment to use from the dropdown when executing the change. Note that each environment uses different account credentials and will generate a tfplan for that account. If you select the wrong target account, the plan file for that account will contain no changes and will do nothing.

# Caveats

S3 Backend is broken for new sso login flow. To get around this, do not set an sso session name to switch to legacy mode when running aws configure sso. Will update as soon as a fix is released.\*\*

Terraform state is saved in S3 Bucket backend declared in main.tf. **DO NOT DELETE** this bucket or this folder without moving the state files first. Move the state files first either locally or another folder then update your local terraform states accordingly with `terraform init -update`

Local state files will **not** work with this workflow as Github needs to be able to read the state files remotely or within the same filesystem as the project.

There is currently no mechanism in place that prevents a junior DevOps from tagging a commit without your knowledge. Remember that tags trigger the apply workflow. You may need to implement the security mechanism yourelf.

Multi-profile Provider authentication:

As of v4 there are some changes impacting the way you use profiles in Terraform. Aside from the credentials stored in a named profile and using it in the .tf script, you need to export it in the same shell where you will be running the script. Failure to do this will result in inconsistent behavior on which accounts Terraform will use.

Removing the profile key and simply using environment variable AWS_PROFILE is simpler.

## Stale plan file

There might be instances where the latest plan file might be tagged as stale. Re-run the previous successful PR merge to generate a new one. Please contact an AWS Admin if issue persists.

# References

1. HashiCorp Terraform: https://www.terraform.io/

2. AWS Provider documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/

3. Amazon Web Services: https://aws.amazon.com/

4. Terraform Tutorial: https://learn.hashicorp.com/terraform

5. Terraform Provider changes for v4: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-4-upgrade#changes-to-authentication
