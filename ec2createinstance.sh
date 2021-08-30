#! /bin/bash

aws ec2 --profile lecture create-vpc --cidr-block 10.35.0.0/16

aws ec2 --profile lecture describe-vpcs --query "Vpcs[?CidrBlock == '10.35.0.0/16'].VpcId"

vpcid=$(aws ec2 --profile lecture describe-vpcs --query "Vpcs[?CidrBlock == '10.35.0.0/16'].VpcId" --output text)

aws ec2 --profile lecture describe-availability-zones --query "AvailabilityZones" | jq -r ".[0].ZoneId"

azid1=$(aws ec2 --profile lecture describe-availability-zones --query "AvailabilityZones" | jq -r ".[0].ZoneId")


aws ec2 --profile lecture create-subnet --vpc-id $vpcid --cidr-block 10.35.0.0/24 --availability-zone-id $azid1

aws ec2 --profile lecture describe-subnets --query "Subnets[?VpcId=='$vpcid'] | [?starts_with(CidrBlock, '10.35.0')]" | jq -r ".[0].SubnetId"

subnetid1=$(aws ec2 --profile lecture describe-subnets --query "Subnets[?VpcId=='$vpcid'] | [?starts_with(CidrBlock, '10.35.0')]" | jq -r ".[0].SubnetId")
aws ec2 --profile lecture create-internet-gateway

aws ec2 --profile lecture describe-internet-gateways --query "InternetGateways[?Attachments[0].State==null]" | jq -r ".[0].InternetGatewayId"

igwid=$(aws ec2 --profile lecture describe-internet-gateways --query "InternetGateways[?Attachments[0].State==null]" | jq -r ".[0].InternetGatewayId")
aws ec2 --profile lecture attach-internet-gateway --vpc-id $vpcid --internet-gateway-id $igwid

aws ec2 --profile lecture describe-internet-gateways --query "InternetGateways[?Attachments[0].VpcId=='$vpcid']" | jq -r ".[0].InternetGatewayId"

igwid=$(aws ec2 --profile lecture describe-internet-gateways --query "InternetGateways[?Attachments[0].VpcId=='$vpcid']" | jq -r ".[0].InternetGatewayId")

aws ec2 --profile lecture create-route-table --vpc-id $vpcid

aws ec2 --profile lecture describe-route-tables --query "RouteTables[?VpcId=='$vpcid'] | [?Associations[0].Main==null]" | jq -r ".[].RouteTableId"

user_rtableid=$(aws ec2 --profile lecture describe-route-tables --query "RouteTables[?VpcId=='$vpcid'] | [?Associations[0].Main == null]" | jq -r ".[].RouteTableId")

aws ec2 --profile lecture create-route --route-table-id $user_rtableid --destination-cidr-block 0.0.0.0/0 --gateway-id $igwid

aws ec2 --profile lecture associate-route-table --subnet-id $subnetid1 --route-table-id $user_rtableid

aws ec2 --profile lecture modify-subnet-attribute --subnet-id $subnetid1 --map-public-ip-on-launch
aws ec2 --profile lecture describe-route-tables --query "RouteTables[?VpcId=='$vpcid'] | [?Associations[0].SubnetId == '$subnetid1']" | jq -r ".[0].Associations[0].RouteTableAssociationId"

user_rtable_aid1=$(aws ec2 --profile lecture describe-route-tables --query "RouteTables[?VpcId=='$vpcid'] | [?Associations[0].SubnetId == '$subnetid1']" | jq -r ".[0].Associations[0].RouteTableAssociationId")
sshkeyname=BoB10@ProductDev.4249

ami_id=ami-095ca789e0549777d
aws ec2 --profile lecture create-security-group --group-name BoB10@ProductDev.cli.4249 --description BoB10@ProductDev.cli.4249 --vpc-id $vpcid

aws ec2 --profile lecture describe-security-groups --query "SecurityGroups[?VpcId=='$vpcid'] | [?contains(Description, 'BoB10@ProductDev.cli.4249')]"

sg_id=$(aws ec2 --profile lecture describe-security-groups --query "SecurityGroups[?VpcId=='$vpcid'] | [?contains(Description, 'BoB10@ProductDev.cli.4249')]" | jq -r ".[0].GroupId")
aws ec2 --profile lecture authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0

aws ec2 --profile lecture run-instances --image-id $ami_id --count 1 --instance-type t2.micro --key-name $sshkeyname --security-group-ids $sg_id \ --subnet-id $subnetid1 --tag-specifications 'ResourceType=instance, Tags=[{Key=Name,Value='BoB10@ProductDev.cli.4249'}]' --user-data file://./test.rules
