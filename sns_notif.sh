#!/bin/bash

aws sns create-topic --name mission-control-alerts
aws sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:724772067672:mission-control-alerts \
    --protocol email \
    --notification-endpoint KelezaDevOps@keleza.site