# DevOps Automation Project

A simple end-to-end DevOps pipeline: code is pushed to GitHub, Jenkins builds a Docker image and pushes it to GitHub Container Registry (GHCR), and Terraform provisions an AWS EC2 server that runs the container.

## Architecture

```
Git (local) → GitHub → Jenkins ─┬─ docker build + push → GHCR (ghcr.io)
                                └─ terraform apply     → AWS EC2 (Ubuntu + Docker)
                                                              │
                                    SSH → docker pull from GHCR → run container (port 80)
```

## Tools Used

| Tool | Purpose |
|---|---|
| Git / GitHub | Version control and source hosting |
| Terraform | Infrastructure as code (EC2 instance) |
| Docker | Containerizing the frontend (Apache httpd) |
| Jenkins | Automation: build, push, provision |
| GHCR | Docker image registry |
| AWS EC2 | Production server |

## Project Structure

```
devops-project/
├── provider.tf    # AWS provider (region: ap-south-1)
├── ec2.tf         # EC2 instance, user data, output
├── Dockerfile     # httpd image serving index.html
├── index.html     # Simple frontend page
└── .gitignore     # Excludes Terraform state and keys
```

## How It Works

### 1. Terraform
- `provider.tf` configures the AWS provider (`hashicorp/aws ~> 6.0`, region `ap-south-1`).
- `ec2.tf` creates an Ubuntu EC2 instance (`t3.micro`) with a key pair and security group.
- **User data** runs on first boot: installs Docker and starts a test `httpd` container on port 8080.
- The instance's public IP is exposed as an output (`public_ip`).

### 2. Docker
The `Dockerfile` builds on `httpd:2.4` and copies `index.html` into Apache's web root (`/usr/local/apache2/htdocs/`).

### 3. Jenkins (Freestyle project)
- **Source Code Management:** this GitHub repo, branch `*/main`.
- **Trigger:** Poll SCM.
- **Credential bindings:**
  - `GH_USER` / `GH_TOKEN`: GitHub username and personal access token (`write:packages`)
  - `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`: AWS access keys
- **Build steps (Windows batch):**

```bat
docker build -t ghcr.io/dafydcodes/devops-project:latest .
echo %GH_TOKEN%| docker login ghcr.io -u %GH_USER% --password-stdin
docker push ghcr.io/dafydcodes/devops-project:latest
```

```bat
terraform init -input=false
terraform apply -auto-approve -input=false
terraform output -raw public_ip
```

> Do not enable "Delete workspace before build starts". The Terraform state file lives in the workspace.

## Prerequisites

- AWS account, an existing EC2 key pair (`webserver-key`) and security group (`terraform-group`) in `ap-south-1`
- Security group rules:
  - Inbound: 22 (SSH), 80 (HTTP), 8080 (test container)
  - Outbound: all traffic (needed to pull images)
- Jenkins server with `git`, `docker` (Docker Desktop, Linux containers) and `terraform` on the PATH
- GitHub personal access token with `write:packages` (and `read:packages` for pulling)

## Deployment Steps

1. Push the code to GitHub:
   ```bash
   git add .
   git commit -m "your message"
   git push origin main
   ```
2. Jenkins detects the change, builds and pushes the image, and creates the EC2.
3. Get the public IP from the end of the Jenkins console output.
4. SSH into the server:
   ```bash
   ssh -i webserver-key.pem ubuntu@<EC2_IP>
   ```
5. Log in to GHCR, pull and run the image:
   ```bash
   echo <GITHUB_TOKEN> | docker login ghcr.io -u DafydCodes --password-stdin
   docker pull ghcr.io/dafydcodes/devops-project:latest
   docker run -d --name web --restart always -p 80:80 ghcr.io/dafydcodes/devops-project:latest
   ```
6. Open `http://<EC2_IP>` in a browser.

## Verifying

| URL | Expected |
|---|---|
| `http://<EC2_IP>:8080` | Apache default page (container started by user data) |
| `http://<EC2_IP>` | The custom page from this repo (production container) |

## Redeploying After Changes

After editing `index.html` and pushing, Jenkins rebuilds the image. On the server:

```bash
docker rm -f web
docker pull ghcr.io/dafydcodes/devops-project:latest
docker run -d --name web --restart always -p 80:80 ghcr.io/dafydcodes/devops-project:latest
```

## Troubleshooting

| Problem | Fix |
|---|---|
| `Cannot run program "sh"` in Jenkins | Use "Execute Windows batch command" on Windows |
| Empty `%GH_USER%` / `%GH_TOKEN%` in the log | Add the credential bindings in the job's Environment section |
| `.pem` "permissions too open" on Windows | Use `icacls` to remove inherited permissions and grant only your user read access |
| `docker login` times out on EC2 | Add an outbound "All traffic" rule to the security group |
| Docker missing on EC2 | Check `/var/log/cloud-init-output.log` and make sure `.tf` files use LF line endings |
| Pull is `unauthorized` | Check the token scope (`read:packages`) or make the package public |

## Cleanup

To avoid AWS charges, destroy the infrastructure when finished:

```bash
terraform destroy
```

Or terminate the instance in the EC2 console.

## Security Notes

- Never commit `.pem` keys, tokens or `*.tfstate` files.
- Restrict SSH (port 22) to your own IP instead of `0.0.0.0/0`.
- Keep credentials in Jenkins credentials, not in scripts.

## Possible Improvements

- Automate the deploy step so Jenkins SSHes into the EC2 and runs the pull/run commands
- Store Terraform state remotely in S3
- Move the pipeline into a `Jenkinsfile`
- Tag images with the build number instead of only `latest`
