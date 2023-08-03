import { S3Client, ListObjectsV2Command, DeleteObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
import { STSClient, AssumeRoleCommand } from "@aws-sdk/client-sts";
import { resolve, join } from "path";
import { readFileSync, readdirSync, lstatSync } from "fs";
import mime from "mime-types";

// The Role ARN for site deployment as output by terraform
const roleARN = "arn:aws:iam::290491194943:role/blog.cechols.com-site-deployer-20230801230759953700000001";
// The bucket name the site is deployed into as output by terraform
const bucket = "blog.cechols.com";
// The region used to create the resources in terraform. This would be the same as the value of the terraform variable region.
const region = "us-east-2";
// This assumes the CWD is the parent directory of the directory this script is located in...
const siteLocation = resolve("dist");

/**
 * 
 * @param {string} rootDir 
 * @param {string[]} additionalPathParts 
 */
function enumerateDir(rootDir, additionalPathParts = []) {
    let objects = [];
    const contents = readdirSync(rootDir);
    for (const item of contents) {
        const fullPath = join(rootDir, item);
        const stat = lstatSync(fullPath);
        if (stat.isDirectory()) {
            // need recursive call for dir...
            objects = objects.concat(enumerateDir(fullPath, [...additionalPathParts, item]));
            continue;
        }
        const content = readFileSync(fullPath, {

        });
        let key = item;
        if (additionalPathParts.length > 0) {
            key = `${additionalPathParts.join("/")}/${item}`;
        }
        objects.push({
            key: key,
            content: content,
            mime: mime.lookup(key),
        });
    }
    return objects;
}


(async () => {
    //     console.log(enumerateDir(siteLocation).map(c => c.key));
    //     return;
    console.log("starting site deployment");
    let credentials = undefined
    try {
        const sts = new STSClient({

        });
        console.log("assuming role for deployment");
        const assumeRoleCommand = new AssumeRoleCommand({
            RoleArn: roleARN,
            RoleSessionName: "site-deploy",
        });
        const assumeRoleResult = await sts.send(assumeRoleCommand);
        credentials = assumeRoleResult.Credentials;
    } catch (ex) {
        // uh oh...
        console.log("failed to assume role", JSON.stringify(ex.message));
        return;
    }

    const s3 = new S3Client({
        credentials: {
            accessKeyId: credentials.AccessKeyId,
            secretAccessKey: credentials.SecretAccessKey,
            sessionToken: credentials.SessionToken
        },
        region,
    });

    // enumerate contents of bucket
    let callCount = 1;

    let existingObjects = [];
    try {
        console.log("getting contents of bucket for delete");
        const listObjectsCommand = new ListObjectsV2Command({
            Bucket: bucket,
        });
        let isTruncated = true

        while (isTruncated) {
            const { Contents, IsTruncated, NextContinuationToken, KeyCount } = await s3.send(listObjectsCommand);
            if (KeyCount > 0) {
                existingObjects = existingObjects.concat(Contents);
            }
            isTruncated = IsTruncated;
            listObjectsCommand.input.ContinuationToken = NextContinuationToken;
        }
    } catch (ex) {
        console.log(`S3 list objects failed on call count ${callCount}`, JSON.stringify(ex.message));
        return;
    }

    console.log("finished getting existing items", existingObjects.length);

    // delete existing bucket contents
    try {
        console.log("deleting existing files");
        for (const object of existingObjects) {
            const deleteCommand = new DeleteObjectCommand({
                Bucket: bucket,
                Key: object.Key,
            });
            await s3.send(deleteCommand);
        }
    } catch (ex) {
        console.log(`S3 delete object failed`, JSON.stringify(ex));
        return;
    }


    // put all files from dist folder in s3...
    console.log("enumerating static site folder for upload");
    const filesToUpload = enumerateDir(siteLocation);
    try {
        console.log("uploading new files");
        for (const file of filesToUpload) {
            const putObjectCommand = new PutObjectCommand({
                Bucket: bucket,
                Key: file.key,
                Body: file.content,
                ContentType: file.mime,
            });
            await s3.send(putObjectCommand);
        }
    } catch (ex) {
        console.log(`S3 put object failed`, JSON.stringify(ex));
        return;
    }
    console.log("deployment complete", filesToUpload.length);
})();

