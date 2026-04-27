# Lab 7 — Serverless (Lambda + Fargate + DynamoDB)

## Apply

```bash
cd terraform/lab-07-lambda-fargate-dynamodb
terraform init
terraform apply -auto-approve
```

This creates ~13 resources: DynamoDB table, Lambda function (with role + policies + log group), ECS Fargate cluster + task definition (with execution role + log group).

Outputs printed: `lambda_name`, `dynamodb_table`, `fargate_cluster`, `task_definition`, `task_definition_arn`.

## Console actions + screenshots

### Part A — Lambda + DynamoDB

1. **Open Lambda console:** https://ap-south-1.console.aws.amazon.com/lambda/home?region=ap-south-1#/functions
   Click `lambda-mukesh-visitor-logger`.

2. **Screenshot — `screenshots/lab-07/7.1-lambda-function.png`**
   Capture the function's main page showing: Runtime = Python 3.12, Handler = handler.handler, the code panel.

3. **Test the function:**
   - Click the **Test** tab (or the orange **Test** button).
   - For "Event name" type `mukesh-test`, leave the JSON event as `{}`, click **Save**.
   - Click **Test**. You'll see "Executing function: succeeded" with a green checkmark.

4. **Screenshot — `screenshots/lab-07/7.2-lambda-test-success.png`**
   Capture the test result panel showing **Status: Succeeded** (green), the response body containing `id`, `timestamp`, `wrote_to: visitors-mukesh`, and the duration / billed duration / max memory used.

5. **Run Test 2 more times** (just click the Test button two more times). This puts 3 items in the DynamoDB table.

6. **Open DynamoDB console:** https://ap-south-1.console.aws.amazon.com/dynamodbv2/home?region=ap-south-1#tables
   Click `visitors-mukesh` → in the left menu click **Explore table items**.

7. **Screenshot — `screenshots/lab-07/7.3-dynamodb-items.png`**
   Capture the items list showing 3 rows. Each should have an `id` (UUID), a `timestamp`, `name = Mukesh`, `source = lambda-mukesh-visitor-logger`.

### Part B — Fargate

1. **Open ECS console:** https://ap-south-1.console.aws.amazon.com/ecs/v2/clusters?region=ap-south-1
   Click `fargate-mukesh-cluster`.

2. **Run a one-off Fargate task:**
   - Click the **Tasks** tab → **Run new task**.
   - **Compute options:** Launch type → `FARGATE`.
   - **Application type:** Task.
   - **Task definition family:** `nginx-mukesh` (revision should be the latest, usually `1`).
   - **Networking:**
     - **VPC:** select the **default VPC** (it should be the only one without a custom name; CIDR `172.31.0.0/16`).
     - **Subnets:** select **all** of them (Fargate needs at least one with internet access via IGW).
     - **Security group:** the default SG of the VPC is fine (allows outbound). If asked to create one, name it `mukesh-fargate-sg` and allow all outbound.
     - **Public IP:** **Turned ON** (otherwise the task can't pull the nginx image from public ECR).
   - Click **Create**.
   - The task will go through PROVISIONING → PENDING → RUNNING (about 60–90 seconds).

3. **Screenshot — `screenshots/lab-07/7.4-fargate-task-running.png`**
   Once the task shows **Last status = RUNNING**, capture the cluster's Tasks tab showing: Task ID, Last status = RUNNING, Desired status = RUNNING, Launch type = FARGATE, Task definition = `nginx-mukesh:1`.

4. **Click the running task** → **Logs** tab.

5. **Screenshot — `screenshots/lab-07/7.5-fargate-task-logs.png`**
   Capture the CloudWatch log stream output showing nginx startup messages (e.g. `nginx/1.x.x`, `start worker process`, `Configuration complete; ready for start up`).

6. **Stop the Fargate task manually:**
   - Back in the cluster's Tasks tab → check the running task → click **Stop selected**.
   - Confirm. The task moves to STOPPED. Wait until it disappears from the active list.

   ⚠️ **You must stop the task before `terraform destroy`** — Terraform tracks the cluster and task definition, but it does NOT track the running task you launched manually. If a task is still running when you destroy, the cluster delete will fail.

## Destroy

```bash
terraform destroy -auto-approve
```

Expected: 13 resources destroyed.

If destroy fails because the cluster has active tasks, go back to ECS console, stop any remaining tasks, wait for them to fully drain, then re-run destroy.
