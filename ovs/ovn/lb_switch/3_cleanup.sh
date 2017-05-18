#!/bin/bash
ovn-nbctl clear logical_switch dmz load_balancer
ovn-nbctl destroy load_balancer $uuid
