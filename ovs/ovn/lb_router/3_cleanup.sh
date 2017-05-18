#!/bin/bash

ovn-nbctl clear logical_router edge1 load_balancer
ovn-nbctl destroy load_balancer $uuid
