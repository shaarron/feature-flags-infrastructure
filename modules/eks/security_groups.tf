# Security Group for Worker Nodes
resource "aws_security_group" "nodes" {
  name        = "${var.name_prefix}-eks-nodes-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  

  tags = {
    # Essential tag for EKS to recognize the security group
    "kubernetes.io/cluster/${var.name_prefix}-custom-cluster" = "owned"
  }
}

# Inbound rule: Allow Nodes to communicate with each other
resource "aws_security_group_rule" "nodes_internal" {
  description              = "Allow nodes to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.nodes.id
  to_port                  = 65535
  type                     = "ingress"
}

# Inbound rule: Allow Control Plane to talk to Nodes (kubelet)
resource "aws_security_group_rule" "control_plane_to_nodes" {
  description              = "Allow worker nodes to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  to_port                  = 65535
  type                     = "ingress"
}