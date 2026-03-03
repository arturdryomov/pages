---
title: "Amazon S3 Paper Cuts"
description: "S3 caveats and corresponding workarounds"
date: "2026-02-28"
slug: "amazon-s3-paper-cuts"
---

Amazon Simple Storage Service became not so simple over time.
Not surprising at all — a lot has happened since 2006.
[The API reference](https://docs.aws.amazon.com/AmazonS3/latest/API/API_Operations_Amazon_Simple_Storage_Service.html)
has more than 100 actions and Amazon itself
[puts S3 features into a couple dozen of categories](https://aws.amazon.com/s3/features/).

It’s a good tool for countless applications — naturally, it has caveats.
Fortunately or not, it’s also a product. As such, caveats become problems
and problems become unpleasant and surprising bills.

# [Versions](https://docs.aws.amazon.com/AmazonS3/latest/userguide/versioning-workflows.html)

The good thing about versions is that enabling them is explicit.
This should prompt questions about the versioning itself.
How many versions need to be maintained at the same time?
What is the purpose of versions — a safeguard against destructive actions,
maintaining full object history or something else?
Such questions and corresponding answers narrow down the volume and the cost.

The bad thing about versions — their usage metrics are mostly implicit.
Versions will be included in the bucket reporting for the total used storage but
to find out the total size of versions one needs to use
[the inventory](https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-inventory.html).

```sql
SELECT 
  SUM(size) AS size_bytes
FROM
  inventory
WHERE
  is_latest = FALSE
```

Since this setup needs to be established and monitored on a regular basis,
it’s trivial to overlook. Preventive measures might be a better idea.
For example, if versions are used as a safeguard and it’s known that in case of problems
the on-call person will react in a timely manner, it’s reasonable to keep versions
for a limited time.

```terraform
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_versions" {
  bucket = aws_s3_bucket.bucket_versions.id

  rule {
    id = "rule_remove_versions"
    status = "Enabled"

    noncurrent_version_expiration {
      newer_noncurrent_versions = 1
      noncurrent_days = 7
    }
  }
}
```

# [Parts](https://docs.aws.amazon.com/AmazonS3/latest/userguide/mpuoverview.html)

Unlike versions, multipart uploads are not configurable — if a client decides
to use the multipart API, it can be done without limitations.
As such, if the client author is not aware of multipart caveats,
unexpected expenses are almost guaranteed due to unseen data.

The problem with multipart uploads is that individual parts don’t expire by default.
This means that if an upload is initiated but not completed
(due to network or storage failures), individual parts remain indefinitely
(but of course, not for free).
The problem is in the conceptual conflict — parts are presented as temporary
but the default behavior makes them permanent.

Since parts are not objects, the UI will not show them. The reporting will include parts
as a portion of the overall storage size but this is an implicit metric.
It appears that even the inventory does not include individual parts.
The single option is to use the CLI but it’s impractical at scale.

```console
$ aws s3api list_multipart_uploads --bucket bucket_parts
```

Since measuring (and monitoring) the impact is almost impossible,
the remaining option is to configure the expiration:

```terraform
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_parts" {
  bucket = aws_s3_bucket.bucket_parts.id

  rule {
    id = "rule_remove_parts"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
```

# [Storage Classes](https://aws.amazon.com/s3/storage-classes/)

Intelligent-Tiering, Glacier, and friends are great but a simple fact might
make them troublesome. The fact is — storage classes are associated with objects,
not with buckets. It’s impossible to set a default storage class for a bucket.
It’s possible, however, to use a transition:

```terraform
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_class" {
  bucket = aws_s3_bucket.bucket_class.id

  rule {
    id = "rule_change_class"
    status = "Enabled"

    transition {
      days = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}
```

It works. There is a nuance though.
Since life cycle rules and transitions execute on a schedule rather than instantly,
if a client uses the standard class for an upload, the object will remain
in the standard class for some time.

This happens because the storage class is the client’s choice.
It might be useful to communicate to clients to use the Intelligent-Tiering class
instead of the default standard class.

The standard class costs the same as the Intelligent-Tiering Frequent Access tier,
but there is lost time before the object transitions
to the Intelligent-Tiering Infrequent Access and following tiers.

There is an option to enforce the class for uploads:

```terraform
resource "aws_s3_bucket_policy" "policy_class" {
  bucket = aws_s3_bucket.bucket_class.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "EnforceClass"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.bucket_class.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-storage-class" = ["INTELLIGENT_TIERING"]
          }
        }
      }
    ]
  })
}
```

# Die Cut

Not gonna lie — S3 could use a bit of guidance and alerting about such issues.
Regardless, it’s a tool. Tools change and evolve over time.
What is irreplaceable is the attention to details and retrospective analysis.
It’s not easy to keep everything in check but it’s always important in the long run.
