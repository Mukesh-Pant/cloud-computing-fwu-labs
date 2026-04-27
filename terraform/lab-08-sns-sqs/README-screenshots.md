# Lab 8 — Messaging Queue & Pub/Sub Simulation (SNS + SQS)

## Apply

This lab needs your email address at apply time. Replace `your.email@example.com` with the address you want to use for SNS notifications:

```bash
cd terraform/lab-08-sns-sqs
terraform init
terraform apply -auto-approve -var="subscriber_email=your.email@example.com"
```

After apply you should immediately see an email titled **"AWS Notification - Subscription Confirmation"** in your inbox (check spam if missing).

## Console actions + screenshots

### Step 1 — Confirm the email subscription

Open the AWS subscription confirmation email → click the **"Confirm subscription"** link. You'll land on a page saying "Subscription confirmed!" — that confirms SNS can now deliver to your email.

### Step 2 — `screenshots/lab-08/8.1-sns-topic.png`

Open SNS console: https://ap-south-1.console.aws.amazon.com/sns/v3/home?region=ap-south-1#/topics
Click `sns-mukesh-notifications`. Scroll to the **Subscriptions** section.

Capture the topic page showing **2 subscriptions**:
- The SQS subscription with Status = `Confirmed`
- The email subscription with Status = `Confirmed` (after step 1)

If the email subscription still shows `Pending confirmation`, refresh the page after clicking the email confirmation link.

### Step 3 — Publish a test message

Still on the topic page, click the **"Publish message"** button (top right).

- **Subject:** `Test from Mukesh — Lab 8`
- **Message body:**
  ```
  Hello from Mukesh's Lab 8 — testing SNS pub/sub fan-out.
  This message should reach both the email subscriber and the SQS queue.
  FWU Cloud Computing, Roll No. 29.
  ```
- Click **Publish message** at the bottom.

### Step 4 — `screenshots/lab-08/8.2-email-received.png`

Switch to your email inbox. Within ~10 seconds you should receive an email titled `Test from Mukesh — Lab 8` from `no-reply@sns.amazonaws.com`.

Capture your inbox showing the received email (or open the email and capture its contents — either is fine, but make sure the sender = `no-reply@sns.amazonaws.com` and the subject is visible).

### Step 5 — `screenshots/lab-08/8.3-sqs-poll-result.png`

Open SQS console: https://ap-south-1.console.aws.amazon.com/sqs/v3/home?region=ap-south-1#/queues
Click `sqs-mukesh-orders` → click **Send and receive messages** button → in the "Receive messages" panel click **Poll for messages**.

After a moment, you should see one message appear in the list. Click the message → its body opens, showing the JSON SNS envelope wrapping your test message:

```json
{
  "Type": "Notification",
  "MessageId": "...",
  "TopicArn": "arn:aws:sns:ap-south-1:...:sns-mukesh-notifications",
  "Subject": "Test from Mukesh — Lab 8",
  "Message": "Hello from Mukesh's Lab 8 — testing SNS pub/sub fan-out...",
  ...
}
```

Capture the message body view showing the JSON envelope with your `Subject` and `Message` text visible. This proves the same SNS message was fanned out to SQS as well as email.

## Destroy

```bash
terraform destroy -auto-approve -var="subscriber_email=your.email@example.com"
```

Expected: 5 resources destroyed.
