#!/bin/bash
awk 'gsub(/\|/,"&")<29' 311-Public-Data-Extract-2015-clean.txt > 311-Public-Data-Extract-2015-ready.txt
