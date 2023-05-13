#!/bin/bash
set -eo pipefail

init() {
  if [ -z "$RANCHER_API_URL" ]; then
      echo "Abort Node Deletion.. no RANCHER_API_URL is set"
      return 1
  fi
  BASE_URL="$RANCHER_API_URL/v3"
  if [[ $TEST_MODE ]]; then
    OUTPUT_FILE=output.txt
    RESULT_FILE=result.txt
  else
    OUTPUT_FILE=$(mktemp)
    RESULT_FILE=$(mktemp)
  fi
  if [ -z "$ACCESS_TOKEN" ]; then
    echo "Abort Node Deletion.. no ACCESS_TOKEN is set"
    return 1
  fi
  CURL_OPTS=(--silent --show-error --header 'Accept: application/json' --header 'Content-Type: application/json' --header "Authorization: Bearer $ACCESS_TOKEN" --output "$OUTPUT_FILE" --write-out '%{http_code}')
  return 0
}

# Check Http Code
chc() {
  if [[ $HTTP_CODE -lt 200 || $HTTP_CODE -ge 300 ]]; then
    echo "Unexpected HTTP code received: $HTTP_CODE! Check file $OUTPUT_FILE! Aborting..." >&2
    return 1
  fi
  return 0
}

rancher_get_cluster_nodes() {
    local CLUSTER_ID="$1"
    local NODE_NAME="$2"
    local HTTP_CODE
  local JQ_FILTER


    local URL="$BASE_URL/clusters/$CLUSTER_ID/nodes?hostname=$NODE_NAME"
  echo "Fetch Node in Cluster..."
  HTTP_CODE=$(curl "${CURL_OPTS[@]}" "$URL")
  chc


  JQ_FILTER=".data[].links.self"
  MACHINE_URL=$(jq -r "$JQ_FILTER" "$OUTPUT_FILE")

  if [[ ! $MACHINE_URL ]]; then
    echo "Response doesn't contain any machines! Aborting..." >&2
    return 1
  fi

  echo "$MACHINE_URL" > "$RESULT_FILE"
  return 0
}

rancher_cordon_and_drain_node() {
    local HTTP_CODE
    local JQ_FILTER
    local URL

    URL=$(<"$RESULT_FILE")
    echo "Fetch Options for Machine drain and cordon..."
    HTTP_CODE=$(curl "${CURL_OPTS[@]}" "$URL")
    chc

    JQ_FILTER=".controlPlane==true and .etcd==true"
    IS_MASTER_NODE=$(jq -r "$JQ_FILTER" "$OUTPUT_FILE")

    if $IS_MASTER_NODE; then
        echo "Skip Cordon and Drain since this a Master Node..."
        return 0
    else
        JQ_FILTER=".actions.cordon"
        CORDON_URL=$(jq -r "$JQ_FILTER" "$OUTPUT_FILE")

        JQ_FILTER=".actions.drain"
        DRAIN_URL=$(jq -r "$JQ_FILTER" "$OUTPUT_FILE")

        if [[ ! $CORDON_URL ]] && [[ ! $DRAIN_URL ]]; then
            echo "Response doesn't contain options for drain and cordon! Aborting..." >&2
            return 1
        fi

        echo "Cordon Machine..."
        HTTP_CODE=$(curl "${CURL_OPTS[@]}" --request POST "$CORDON_URL")
        chc

        echo "Drain Machine..."
        local DATA="{\"deleteLocalData\":true,\"force\":true}"
        HTTP_CODE=$(curl "${CURL_OPTS[@]}" --request POST "$DRAIN_URL" --data-raw "$DATA")
        chc

        rancher_wait_for_drain_completion
        return 0
    fi
}

rancher_wait_for_drain_completion() {
    local HTTP_CODE
    local JQ_FILTER
    local URL

    URL=$(<"$RESULT_FILE")
    echo "Fetch Drain Status for Machine..."
    HTTP_CODE=$(curl "${CURL_OPTS[@]}" "$URL")
    chc

    JQ_FILTER=".state"
    STATE=$(jq -r "$JQ_FILTER" "$OUTPUT_FILE")

    if [ "$STATE" == "drained" ];then
        echo "Machine has been Successfully drained..."
        return 0
    else
        echo "Machine isn't Successfully drained..."
        echo "Sleep 5s and check again..."
        sleep 5
        rancher_wait_for_drain_completion
    fi
}

rancher_delete_node() {
    local HTTP_CODE
    local URL
    local CLUSTER_NAMESPACE
    local MACHINE_ID
    local JQ_FILTER

    URL=$(<"$RESULT_FILE")
    echo "Delete Node..."
    HTTP_CODE=$(curl "${CURL_OPTS[@]}" --request DELETE "$URL")
    chc

    JQ_FILTER='.annotations["cluster.x-k8s.io/machine"]'
    MACHINE_ID=$(jq -r "$JQ_FILTER" "$OUTPUT_FILE")

    JQ_FILTER='.annotations["cluster.x-k8s.io/cluster-namespace"]'
    CLUSTER_NAMESPACE=$(jq -r "$JQ_FILTER" "$OUTPUT_FILE")

    rancher_wait_for_delete_completion "$CLUSTER_NAMESPACE" "$MACHINE_ID"
    return 0
}

rancher_wait_for_delete_completion(){
    local HTTP_CODE
    local URL
    local CLUSTER_NAMESPACE="$1"
    local MACHINE_ID="$2"

    echo "Fetch all Machines..."
    URL="$RANCHER_API_URL/v1/cluster.x-k8s.io.machines"
    HTTP_CODE=$(curl "${CURL_OPTS[@]}" "$URL")
    chc

    JQ_FILTER='isempty(.data[] | select(.id=='\"$CLUSTER_NAMESPACE/$MACHINE_ID\"'))'
    DELETE_STATE=$(jq -r "$JQ_FILTER" "$OUTPUT_FILE")

    if [ "$DELETE_STATE" = true ]; then
        echo "Machine has been Successfully deleted..."
        return 0
    else
        echo "Machine isn't Successfully deleted..."
        echo "Sleep 5s and check again..."
        sleep 5
        rancher_wait_for_delete_completion "$CLUSTER_NAMESPACE" "$MACHINE_ID"
    fi
}

if [[ $1 = "-h" ]]; then
  echo "Drain and Delete Node of a given Cluster."
  echo "Usage:"
  echo "  $(basename $"0") <cluster-id> <nodename>"
  echo "    cluster-id     = the id of a cluster e.g. c-m-fsw4jx7x"
  echo "    nodename   = the name of the node which needs to be drained"
  echo "Example:"
  echo "  $(basename $"0") c-m-fsw4jx7x test-w01"
  exit 0
fi

CLUSTERID=$1
if [[ ! $CLUSTERID ]]; then
  echo "Missing argument cluster-id! Aborting..." >&2
  exit 1
fi

NODENAME=$2
if [[ ! $NODENAME ]]; then
  echo "Missing argument nodename! Aborting..." >&2
  exit 1
fi



init
rancher_get_cluster_nodes "$CLUSTERID" "$NODENAME"
rancher_cordon_and_drain_node
rancher_delete_node
exit 0