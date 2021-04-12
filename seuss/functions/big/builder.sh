#!/bin/bash
for i in $(seq 5248)
do
    cp base.js module_"$i".js
done