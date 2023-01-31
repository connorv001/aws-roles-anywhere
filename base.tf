variable "organization" {
    default = "hello"
  }
  
  variable "organizational_unit" {
    default = "test"
  }
  
  variable "common_name" {
    default= "test-name.domain"
  }
  
  resource "aws_acmpca_certificate_authority" "example" {
    permanent_deletion_time_in_days = 7
    type                            = "ROOT"
    certificate_authority_configuration {
      key_algorithm = "RSA_2048"
      signing_algorithm = "SHA256WITHRSA"
      subject {
        common_name  = var.common_name
        organization = var.organization
        organizational_unit = var.organizational_unit
      }
    }
  }
  
  
  
  
  data "aws_partition" "current" {}
  
  resource "aws_acmpca_certificate" "example" {
    certificate_authority_arn   = aws_acmpca_certificate_authority.example.arn
    certificate_signing_request = aws_acmpca_certificate_authority.example.certificate_signing_request
    signing_algorithm = "SHA256WITHRSA"
  
    template_arn = "arn:${data.aws_partition.current.partition}:acm-pca:::template/RootCACertificate/V1"
  
    validity {
      type  = "YEARS"
      value = 1
    }
  }
  
  resource "aws_acmpca_certificate_authority_certificate" "example" {
    certificate_authority_arn = aws_acmpca_certificate_authority.example.arn
    certificate               = aws_acmpca_certificate.example.certificate
    certificate_chain         = aws_acmpca_certificate.example.certificate_chain
  }
  
  resource "aws_rolesanywhere_trust_anchor" "test" {
    name = "example"
    source {
      source_data {
        acm_pca_arn = aws_acmpca_certificate_authority.example.arn
      }
      source_type = "AWS_ACM_PCA"
    }
    # Wait for the ACMPCA to be ready to receive requests before setting up the trust anchor
    depends_on = [aws_acmpca_certificate_authority_certificate.example]
  }
  
  resource "tls_private_key" "example" {
  algorithm = "RSA"
  }
  
  resource "tls_cert_request" "example" {
  private_key_pem = tls_private_key.example.private_key_pem
  subject {
  common_name = var.common_name
  organization = var.organization
  organizational_unit = var.organizational_unit
  }
  }
  
  
  
  output "certificate_body" {
  value = aws_acmpca_certificate.example.certificate
  }
  
  resource "local_file" "cert-chain" {
    sensitive_content   = aws_acmpca_certificate.example.certificate_chain
    filename  = "certchain.txt"
  }
  
  
  resource "local_file" "tls_private_key" {
    sensitive_content   = tls_private_key.example.private_key_pem
    filename  = "tls_private_key.pem"
  }
  


resource "aws_iam_role" "test" {
    name = "test"
    path = "/"
  
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action = [
          "sts:AssumeRole",
          "sts:TagSession",
          "sts:SetSourceIdentity"
        ]
        Principal = {
          Service = "rolesanywhere.amazonaws.com",
        }
        Effect = "Allow"
        Sid    = ""
      }]
    })
  }
  
  resource "aws_iam_policy" "s3_full_access" {
    name        = "s3_full_access"
    path        = "/"
    description = "Allows full access to a specific S3 bucket"
  
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action = [
          "s3:*"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
        Effect = "Allow"
      }]
    })
  }
  
  resource "aws_iam_role_policy_attachment" "test_s3_full_access" {
    role       = aws_iam_role.test.name
    policy_arn = aws_iam_policy.s3_full_access.arn
  }
  
  
  
  resource "aws_rolesanywhere_profile" "test" {
  
    name      = "example"
    role_arns = [aws_iam_role.test.arn]
  }
  
  variable "bucket_name" {
    default = "the damn bucekt"
  }
  
  
  
