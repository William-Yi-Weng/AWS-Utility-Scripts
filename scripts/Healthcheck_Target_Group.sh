#!/bin/bash +x

echo "Job started by $BUILD_USER"


echo "Search Load Balancer in $AWS_PROFILE"
ALBS=$(aws elbv2 describe-load-balancers --profile $AWS_PROFILE --output text --query "LoadBalancers[].[LoadBalancerArn]")

echo "$ALBS"

unhealthy_targets=()

echo "Search Unhealthy Target Group in $AWS_PROFILE"
for lb in ${ALBS}
do
	target=$(aws elbv2 describe-listeners --profile $AWS_PROFILE --load-balancer-arn  ${lb} --query 'Listeners[?Port==`80`||Port==`443`].DefaultActions[].TargetGroupArn' --output text | sed "s/\t/ /")

	if [ -z "${target}" ] ;then
		continue
	fi
    
    IFS=' '
    read -a strarr <<< "$target"
    for tg in ${strarr[@]}
    do
		cont=$(aws elbv2 describe-target-health --profile $AWS_PROFILE --target-group-arn ${tg} --query 'TargetHealthDescriptions[]' --output text)
		if [ -z "${cont}" ] ;then
			unhealthy_targets+=${tg}
            unhealthy_targets+=$'\n'
		fi
    done
done

if [ -z "$unhealthy_targets" ] ;then
 	echo "All Target Group for port80/443 of Load Balancer are healthy today in $AWS_PROFILE"
else
 	echo "Some Target Group for portport80/443 of Load Balancer are detected unhealthy in $AWS_PROFILE!"
    echo "++++++++++++++++++++++++++++++++++++++++++++++"
    echo "List of Unhealthy Target Groups:"
 	echo "$unhealthy_targets"
    echo "++++++++++++++++++++++++++++++++++++++++++++++"
 	exit 1
fi




