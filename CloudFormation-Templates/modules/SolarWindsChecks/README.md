# Self-Service Security Assessment tool - SolarWinds Checks

`Note`: This module does not automatically run each feature, so please read the module function documentation below.

## Athena VPC Flow logs query
### Detecting communication with malicious IPs noted in [CISA Alert AA20-352A](https://us-cert.cisa.gov/ncas/alerts/aa20-352a) with Amazon Athena query.

This module will create a Athena query called `AA20352A IP IOC` to scan your VPC flow logs against the IP addresses provided in the CISA alert looking for any communication to or from these addresses.

### REQUIREMENTS

## 1. Permissions
This process will require permissions to create Athena Tables, Run Queries and access to S3 bucket with VPC Flow logs

## 2. Assumptions

1. VPC [Flow logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html) are enabled and stored in a [S3 bucket](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-s3.html)
2. VPC Flow logs capture 'All' traffic
3. You have access to the S3 bucket that contains VPC Flow logs
4. You have some basic familiarity with [Amazon Athena](https://docs.aws.amazon.com/athena/latest/ug/getting-started.html)
5. This template was deployed in the same region as the VPC Flow logs bucket (e.g. US-East-1)

## Step 1: Setup Athena table with VPC Flow Logs
`Note`: If you have previously created a table for your VPC flow logs in Athena, you may skip to step 2

### Create an Athena table to query VPC Flow Logs
Follow the guide in the Athena documentation [here](https://docs.aws.amazon.com/athena/latest/ug/vpc-flow-logs.html)

## Step 2: Partition the Flow logs table and convert to Parquet format

Flow logs collect flow log records, consolidate them into log files, and then publish the log files to the Amazon S3 bucket (*for example DOCEXAMPLE-1122*) at 5-minute intervals. Each log file contains flow log records for the IP traffic recorded in the previous five minutes.

Flow logs are stored in the following structure
*bucket_ARN/optional_folder/AWSLogs/aws_account_id/vpcflowlogs/region/year/month/day/log_file_name.log.gz*

To query the logs, partition the table created above for the date you want to use in queries

```
ALTER TABLE vpc_flow_logs
ADD PARTITION (`date`='YYYY-MM-DD')
LOCATION 's3://<NAME-OF-BUCKET-CONTAINING-VPC-FLOWLOGS>/AWSLogs/<ACCOUNT-ID>/vpcflowlogs/<REGION-CODE>/<YYYY>/<MM>/<DD>';
```
For example ```s3://DOCEXAMPLE-1122/AWSLogs/111111111111/vpcflowlogs/us-east-1//2020/12/22```

Additional details for [querying VPC Flow Logs](https://docs.aws.amazon.com/athena/latest/ug/vpc-flow-logs.html)

`Note`: Make sure to change the dates both under PARTITION AND LOCATION

```
CREATE EXTERNAL TABLE IF NOT EXISTS vpc_logs_pq (
  version int,
  account string,
  interfaceid string,
  sourceaddress string,
  destinationaddress string,
  sourceport int,
  destinationport int,
  protocol int,
  numpackets int,
  numbytes bigint,
  starttime int,
  endtime int,
  action string,
  logstatus string
)
PARTITIONED BY(year int, month int, day int)
STORED AS PARQUET
LOCATION 's3://<your-bucket-name>/vpcflowlogs/parquet/'
tblproperties ("parquet.compress"="SNAPPY");
```

## Step 3: Run the Athena query
The following content is from the template that was deployed as "AA20352A IP IOC" in your Athena console.

The following query contains the IP addresses as mentioned under [CISA Alert AA20-352A](https://us-cert.cisa.gov/ncas/alerts/aa20-352a)

```
SELECT *
FROM vpc_logs_pq
WHERE destinationaddress in ('3.87.182.149','3.16.81.254','54.215.192.52','8.18.144.11','8.18.144.12','8.18.144.9','8.18.144.20','8.18.144.40','8.18.144.44','8.18.144.62','8.18.144.130','8.18.144.135','8.18.144.136','8.18.144.149','8.18.144.156','8.18.144.158','8.18.144.165','8.18.144.170','8.18.144.180','8.18.144.188','8.18.145.3','8.18.145.21','8.18.145.33','8.18.145.36','8.18.145.131','8.18.145.134','8.18.145.136','8.18.145.139','8.18.145.150','8.18.145.157','8.18.145.181','13.57.184.217','18.217.225.111','18.220.219.143','20.141.48.154','34.219.234.134','184.72.1.3','184.72.21.54','184.72.48.22','184.72.101.22','184.72.113.55','184.72.145.34','184.72.209.33','184.72.212.52','184.72.224.3','184.72.229.1','184.72.240.3','184.72.245.1','196.203.11.89','13.59.205.66','54.193.127.66','107.152.35.77','13.59.205.66','173.237.190.2','198.12.75.112','20.141.48.154') OR sourceaddress in ('3.87.182.149', '3.16.81.254','54.215.192.52','8.18.144.11','8.18.144.12','8.18.144.9','8.18.144.20','8.18.144.40','8.18.144.44','8.18.144.62','8.18.144.130','8.18.144.135','8.18.144.136','8.18.144.149','8.18.144.156','8.18.144.158','8.18.144.165','8.18.144.170','8.18.144.180','8.18.144.188','8.18.145.3','8.18.145.21','8.18.145.33','8.18.145.36','8.18.145.131','8.18.145.134','8.18.145.136','8.18.145.139','8.18.145.150','8.18.145.157','8.18.145.181','13.57.184.217','18.217.225.111','18.220.219.143','20.141.48.154','34.219.234.134','184.72.1.3','184.72.21.54','184.72.48.22','184.72.101.22','184.72.113.55','184.72.145.34','184.72.209.33','184.72.212.52','184.72.224.3','184.72.229.1','184.72.240.3','184.72.245.1','196.203.11.89','13.59.205.66','54.193.127.66','107.152.35.77','13.59.205.66','173.237.190.2','198.12.75.112','20.141.48.154')
LIMIT 100;
```
Sample output shows the communication details (example IP Address) for the compromised instance: ![screenshot](/docs/img/query_output.png)

Now you can perform incident response on the compromised EC2 instances:
- [How to perform automated incident response in a multi-account environment](https://aws.amazon.com/blogs/security/how-to-perform-automated-incident-response-multi-account-environment/)
- [How to automate incident response in the AWS Cloud for EC2 instances](https://aws.amazon.com/blogs/security/how-to-automate-incident-response-in-aws-cloud-for-ec2-instances/)
- [AWS Security Incident Response best practices White-paper](https://aws.amazon.com/blogs/security/introducing-the-aws-security-incident-response-whitepaper/)

# Solarwinds Windows hash detection for CISA alert aa20-352a
This template creates an SSM Automation document that can be used to quickly query their Windows EC2 fleets for malicious Solarwinds .dll's.

### REQUIREMENTS
An IAM principle that is able to execute the SSM automation against the selected EC2 fleet.

## Overview - Open Source project checks
Query files for Solarwind hashes based on CISA Appendix A: Affected SolarWinds Orion Products.  

This CloudFormation uses the AWS Run Command to connect to an EC2 instance you identify {InstanceIds}.  

It looks for hashes identified in the CISA Reference Document (https://us-cert.cisa.gov/ncas/alerts/aa20-352a), Appendices A and B.  

Using the hashes from CISA, it runs the Powershell Get-ChildItem cmdlet, looking for *SolarWinds.Orion.Core.BusinessLayer*.*  on the c:\ drive.  

It gets the SHA256 hash for the Solarwinds files and matches hashes to identify if you are at risk for CISA alert aa20-352a

### What will be created

+ A Systems Manager Automation document
    + Creates a directory *C:\SWHash*
    + Runs the powershell command *Get-ChildItem** to look for solarwinds .dll's and create SHA256 hashes of those files.
    + Compares those hashes to the hashes identified in the CISA alert for both appendix A and B

## How to deploy this tool
1. Navigate the the Systems Manager console
2. In the left navigation pane and select `Automation` from the Change Management option ![screenshot](/docs/img/solarhash-1.png)
3. Press the Execute Automation button in the upper right
4. Change the group to "Owned by me" ![screenshot](/docs/img/solarhash-2.png)
5. Select the `SolorWindsAA20-352AAutomatedScanner` ![screenshot](/docs/img/solarhash-3.png)
6. Select "Next" in the lower right
7. Select `Single execution`
8. In the input parameters enter the instance-id OR toggle the `Show interactive instance picker` and select the instances to be scanned
9. Press the Execute button in the lower right corner
10. The status will change from `In progress` to `Complete` when the automation has completed ![screenshot](/docs/img/solarhash-4.png)

## How do I read the output?
* You can review the output in the Systems Manager Automation document execution response.  

You can also review the output in the /aws/ssm/AWS-RunPowerShellScript log group in the Cloud Watch Logs console.

It is recommended that you create a dashboard widget based on the results of the query for tracking purposes.  

1. Go to Logs, Insights in the CloudWatch console.  
2. In the *Select log group(s)* field, enter /aws/ssm/AWS-RunPowerShellScript
3. In the query text box, enter *fields @timestamp, @message*
4. Set the query time (recommend 1 day)
5. Click *Run query*
6. Click *Add to dashboard* and follow the prompts.

## Route53 DNS Log - DNS query

### What will be created
+ Athena Query for Route53 DNS query logs

### REQUIREMENTS

## 1. Permissions
This process will require permissions to create Athena Tables, Run Queries and access to S3 bucket with DNS logs

## 2. Assumptions
1. Route 53 DNS [query logs](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html) are enabled and stored in a S3 bucket
3. You have access to the S3 bucket that contains DNS logs
4. You have some basic familiarity with [Amazon Athena](https://docs.aws.amazon.com/athena/latest/ug/getting-started.html)
5. This template was deployed in the same region as the DNS logs bucket (e.g. US-East-1)

## Step 1: Setup Athena table with DNS Logs
`Note`: If you have previously created a table for your DNS logs in Athena, you may skip to step 2

### Create an Athena table to query DNS Logs
Follow the guide in the Athena documentation [here](https://docs.aws.amazon.com/athena/latest/ug/vpc-flow-logs.html)

Use the following query - Replace **s3://<YOUR-S3-BUCKET>/dns-query-logs/** with your correct location
```
CREATE EXTERNAL TABLE IF NOT EXISTS default.route53query (
  `version` float,
  `account_id` string,
  `region` string,
  `vpc_id` string,
  `query_timestamp` string,
  `query_name` string,
  `query_type` string,
  `query_class` string,
  `rcode` string,
  `answers` array<string>,
  `srcaddr` string,
  `srcport` int,
  `transport` string,
  `srcids` string
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
WITH SERDEPROPERTIES (
  'serialization.format' = '1'
) LOCATION 's3://<YOUR-S3-BUCKET>/dns-query-logs/'

TBLPROPERTIES ('has_encrypted_data'='false');
```

## Step 2: Run the Athena query
The following content is from the template that was deployed as "AA20352A IP IOC" in your Athena console.

The following query contains the IP addresses as mentioned under [CISA Alert AA20-352A](https://us-cert.cisa.gov/ncas/alerts/aa20-352a)

```
SELECT *
FROM "default"."route53query"
WHERE query_name IN ('deftsecurity.com.','avsvmcloud.com.','digitalcollege.org.','freescanonline.com.','globalnetworkissues.com.','kubecloud.com.','lcomputers.com.','seobundlekit.com.','solartrackingsystem.net.','thedoccloud.com.','virtualwebdata.com.','webcodez.com.','infinitysoftware.com.','mobilnweb.com.','ervsytem.com.','infinitysoftwares.com.')
```


## Alternate query - Cloudwatch log insights
For customers that have Cloudwatch log insights enabled, you can use the following query, be sure to adjust the time period from the default 1hr setting.
```
filter query_name = "deftsecurity.com."
or query_name = "avsvmcloud.com."
or query_name = "digitalcollege.org."
or query_name = "freescanonline.com."
or query_name = "globalnetworkissues.com."
or query_name = "kubecloud.com."
or query_name = "lcomputers.com."
or query_name = "seobundlekit.com."
or query_name = "solartrackingsystem.net."
or query_name = "thedoccloud.com."
or query_name = "virtualwebdata.com."
or query_name = "webcodez.com."
or query_name = "infinitysoftware.com."
or query_name = "mobilnweb.com."
or query_name = "ervsytem.com."
or query_name = "infinitysoftwares.com."
| stats count(*) as query_namecnt by query_name
| sort query_namecnt desc
| limit 100

```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This project is licensed under the Apache-2.0 License.
