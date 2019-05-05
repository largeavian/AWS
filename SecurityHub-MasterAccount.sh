## 'file' should contain the master securityhub account only
## This account will be assumed and have commands run as the targets included in 'file2'
file="/home/ec2-user/list-temp.txt"
YELLOW='\033[1;33m'
RED='\033[1;31m'
PURP='\033[1;34m'
NC='\033[0m'
while IFS= read -r acctid
        do
                # Clears all affected env variables
                unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

                # Assume role and print info to idp.txt
                idp=$(aws sts assume-role --role-arn arn:aws:iam::$acctid:role/<ROLENAME> --role-session-name IDP)

                # Sets env variables
                export AWS_ACCESS_KEY_ID=$(echo $idp | jq -r .Credentials.AccessKeyId)
                export AWS_SECRET_ACCESS_KEY=$(echo $idp | jq -r .Credentials.SecretAccessKey)
                export AWS_SESSION_TOKEN=$(echo $idp | jq -r .Credentials.SessionToken)

                # Populate per account commands below this line
                # Note that there are two SNS targets list (1 for status changes and another for Findings)
                AcctNumber=$(aws sts get-caller-identity | jq -r .Account)
                echo -e Attempting commands against ${RED}$AcctNumber${NC}...

                # 'file2' should be a list of accounts and email addresses separated by a tab
                file2="/home/ec2-user/list-sechub.txt"
                while IFS= read -r TargetAcctId
                do
                    id=$(grep "$TargetAcctId" $file2 | cut -f1)
                    email=$(grep "$TargetAcctId" $file2 | cut -f2)   

                    echo -e ...on ${YELLOW}$id${NC}...

                        file3="/home/ec2-user/regions-temp.txt"
                        while IFS= read -r region
                        do
                            echo -e ...in ${PURP}$region${NC}...
                                ## All commands below will be executed as the accounts listed in 'file2'
                                aws securityhub create-members --account-details AccountId=$id,Email=$email --region $region
                                aws securityhub invite-members --account-ids $id --region $region
                        done < "$file3"

                done < "$file2"

        done < "$file"