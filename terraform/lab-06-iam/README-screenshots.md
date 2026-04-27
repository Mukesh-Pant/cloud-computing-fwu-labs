# Lab 6 — IAM Users, Groups & Policies

## Apply

```bash
cd terraform/lab-06-iam
terraform init
terraform apply -auto-approve
```

After apply, retrieve the auto-generated password for `mukesh-dev`:

```bash
terraform output dev_password
terraform output console_login_url
terraform output account_id
```

(Copy these values — you'll need them for screenshot 6.4.)

## Screenshots to capture

Open https://us-east-1.console.aws.amazon.com/iam/home (IAM is global; UI loads in any region).

1. **`screenshots/lab-06/6.1-iam-users-list.png`**
   IAM → Users. Capture the users list showing both `mukesh-dev` and `mukesh-readonly` with their creation date and `Owner: Mukesh` tag.

2. **`screenshots/lab-06/6.2-iam-group-developers.png`**
   IAM → User groups → click `Developers-mukesh`. Capture **two tabs together if possible** (or two screenshots merged):
   - **Users** tab showing `mukesh-dev` as member.
   - **Permissions** tab showing `AmazonEC2FullAccess` attached.

   *If your console only shows one tab at a time, just capture the Permissions tab — the membership shown in 6.1's user listing covers the group association.*

3. **`screenshots/lab-06/6.3-iam-user-readonly-policies.png`**
   IAM → Users → click `mukesh-readonly` → **Permissions** tab. Capture showing `ReadOnlyAccess` policy attached directly to the user.

4. **`screenshots/lab-06/6.4-iam-login-as-dev.png`** *(this requires console action)*
   - Open a **new incognito / private browser window**.
   - Go to the `console_login_url` from Terraform output (looks like `https://<account-id>.signin.aws.amazon.com/console`).
   - Sign in with: IAM user name `mukesh-dev`, password from `terraform output dev_password`.
   - You'll land on the AWS Console homepage. Capture the page showing the **top-right banner** which displays `mukesh-dev @ <account-alias>` — this proves the IAM user can log in.
   - Optionally navigate to EC2 to confirm the user has EC2 access (per Developers group policy). Then close the incognito window.

## Destroy

```bash
terraform destroy -auto-approve
```

Expected: 7 resources destroyed (2 users + group + 3 policy attachments + login profile).

⚠️ **If destroy fails on the user_login_profile**: AWS sometimes refuses to delete a login profile if the password was changed manually. Just re-run `terraform destroy -auto-approve`.
