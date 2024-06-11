# This script runs the list checks command to create three text files with the latest checks.

# Get basic checks
prowler aws --list-checks -c \
    account_maintain_current_contact_details \
    awslambda_function_using_supported_runtimes \
    cloudtrail_multi_region_enabled \
    config_recorder_all_regions_enabled \
    ec2_securitygroup_allow_ingress_from_internet_to_any_port \
    guardduty_is_enabled \
    iam_password_policy_lowercase \
    iam_password_policy_number \
    iam_password_policy_symbol \
    iam_password_policy_uppercase \
    iam_root_mfa_enabled \
    iam_rotate_access_key_90_days \
    s3_bucket_public_access \
    | sed 's/\x1b\[[0-9;]*m//g' \
    > ./checks/basic_checks.txt

# Get intermediate checks
prowler aws --list-checks \
    --severity critical high \
    | sed 's/\x1b\[[0-9;]*m//g' \
    > ./checks/intermediate_checks.txt

# Get full checks
prowler aws --list-checks \
    | sed 's/\x1b\[[0-9;]*m//g' \
    > ./checks/full_checks.txt