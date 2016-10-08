#!/usr/local/bin/bash
# A shell script for managing AliYun SLB.

# Check bash version
if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
  echo "Sorry, you need at least bash-4.0 to run this script."
  exit 1
fi

# Check aliyun access key id
if [[ -z $ALIYUN_ACCESS_KEY_ID ]]; then
  echo "Please set environment variable 'ALIYUN_ACCESS_KEY_ID' (AliYun Access Key ID)"
  exit 1
fi

# Check aliyun access key secret
if [[ -z $ALIYUN_ACCESS_KEY_SECRET ]]; then
  echo "Please set environment variable 'ALIYUN_ACCESS_KEY_SECRET' (AliYun Access Key Secret)"
  exit 1
fi

# Source utils functions
current_dir=$(dirname "$0")
# shellcheck source=src/utils.sh
. "$current_dir/utils.sh"

# shellcheck disable=2154,2155
set_backend_servers() {
  local slbId="$1"
  local serverId="$2"
  local serverWeight="$3"

  declare -A params
  params[AccessKeyId]="$ALIYUN_ACCESS_KEY_ID"
  params[Format]="json"
  params[Version]="2014-05-15"
  params[Timestamp]=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  params[SignatureVersion]="1.0"
  params[SignatureMethod]="HMAC-SHA1"
  params[SignatureNonce]=$(random_chars 16)

  params[Action]="SetBackendServers"
  params[LoadBalancerId]="$slbId"
  params[BackendServers]="[{\"ServerId\":\"$serverId\",\"Weight\":\"$serverWeight\"}]"

  local originParams=""
  for k in "${!params[@]}"; do originParams+="$k=${params[$k]}&"; done
  originParams="${originParams:0:${#originParams} - 1}"
  debug "originParams: $originParams"

  debug "paramNames:" "${!params[@]}"
  local sortedParamNames=($(for p in "${!params[@]}"; do echo $p; done | sort))
  debug "sortedParamNames:" "${sortedParamNames[@]}"

  local sortedParams=""
  for k in "${sortedParamNames[@]}"; do sortedParams+="$k=$(url_encode "${params[$k]}")&"; done
  sortedParams="${sortedParams:0:${#sortedParams} - 1}"
  debug "sortedParams: $sortedParams"

  local encodedParams=$(url_encode $sortedParams)

  local strToSign="GET&%2F&$encodedParams"
  debug "strToSign: $strToSign"

  local signature=$(url_encode "$(hash_hmac $strToSign $ALIYUN_ACCESS_KEY_SECRET)")

  local finalParams="$originParams&Signature=$signature"
  debug "finalParams: $finalParams"

  curl -G "https://slb.aliyuncs.com/" -d "$finalParams"
  echo
}
