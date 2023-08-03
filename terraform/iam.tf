data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "deploy_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "deploy" {
  name_prefix        = "${var.domain_name}-site-deployer-"
  assume_role_policy = data.aws_iam_policy_document.deploy_assume.json
}

data "aws_iam_policy_document" "deploy" {
  statement {
    sid    = "SiteListContents"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "${aws_s3_bucket.site.arn}",
    ]
  }
  statement {
    sid    = "SiteDeleteAndWrite"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.site.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "deploy" {
  name_prefix = "${var.domain_name}-site-deployer-"
  policy      = data.aws_iam_policy_document.deploy.json
}

resource "aws_iam_role_policy_attachment" "deploy" {
  role       = aws_iam_role.deploy.id
  policy_arn = aws_iam_policy.deploy.arn
}