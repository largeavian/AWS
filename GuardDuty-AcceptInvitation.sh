## Inclusion of accounts in 'file2' that do not have an invite or have already accepted an invite receive the following error:
## "aws: error: argument --master-id: expected one argument"

## Update with list for accounts to be targeted
file="/home/ec2-user/list-gd.txt"
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[0;34m'
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
                AcctNumber=$(aws sts get-caller-identity | jq -r .Account)
                echo -e "Attempting commands against ${YELLOW}$AcctNumber${NC}..."

                # 'file2' should include all regions where Security Hub will be deployed
                file2="/home/ec2-user/regions-temp.txt"

                while IFS= read -r region
                        do
                                # All commands below will be performed per each region listed in 'file2'
                                echo -e "...in ${BLUE}$region${NC}"
                                # Create a GuardDuty detector
                                aws guardduty create-detector --enable
                                # Define the variables from list-invitations
                                invitation=$(aws guardduty list-invitations --query 'Invitations[*].[InvitationId]' --output text)
                                masteracct=$(aws guardduty list-invitations --query 'Invitations[*].[AccountId]' --output text)
                                detectorid=$(aws guardduty list-detectors --query 'DetectorIds[*]' --output text)
                                # echo the variable data 
                                echo $invitation
                                echo $masteracct
                                echo $detectorid
                                # accept invitation using variables
                                aws guardduty  accept-invitation --master-id $masteracct --invitation-id $invitation --detector-id $detectorid
                          
                        done < "$file2"

        done < "$file"