import { defineBackend } from '@aws-amplify/backend';
import { Policy, PolicyStatement, Effect } from "aws-cdk-lib/aws-iam";
import { auth } from './auth/resource.js';
import { data } from './data/resource.js';

const aws_s3_bucket_name  = "bucket"
const aws_region = "region"

const backend = defineBackend({
  auth,
  data,
});


backend.addOutput({
  version: "1.3",
  storage: {
    aws_region: aws_region,
    bucket_name: aws_s3_bucket_name,
    buckets: [
      {
        name: aws_s3_bucket_name,
        bucket_name: aws_s3_bucket_name,
        aws_region: aws_region,
        //@ts-expect-error amplify backend type issue https://github.com/aws-amplify/amplify-backend/issues/2569
        paths: {
          "public/*": {
            authenticated: ["get", "list", "write", "delete"],
            groupsadmin: ["get", "list", "write", "delete"],
          },
          "admin/*": {
            groupsadmin: ["get", "list", "write", "delete"],
          },
        },
      },
    ],
  },
});
