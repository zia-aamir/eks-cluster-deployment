# ── Data Sources ──────────────────────────────────────────────
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "available_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ── EKS Cluster ───────────────────────────────────────────────
resource "aws_eks_cluster" "project-cluster" {
  name     = "project-cluster"
  role_arn = aws_iam_role.example.arn

  vpc_config {
  subnet_ids = data.aws_subnets.available_subnets.ids
}

  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.example-AmazonEKSVPCResourceController,
  ]
}

# ── Outputs ───────────────────────────────────────────────────
output "endpoint" {
  value = aws_eks_cluster.project-cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.project-cluster.certificate_authority[0].data
}

# ── Node Group ────────────────────────────────────────────────
resource "aws_eks_node_group" "node-grp" {
  cluster_name    = aws_eks_cluster.project-cluster.name
  node_group_name = "pc-node-group"
  node_role_arn   = aws_iam_role.worker.arn
  subnet_ids      = data.aws_subnets.available-subnets.ids
  capacity_type   = "ON_DEMAND"
  disk_size       = "20"
  instance_types  = ["t3.small"]

  labels = tomap({ env = "dev" })

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}
