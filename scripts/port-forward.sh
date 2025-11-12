#!/usr/bin/env bash

FRONTEND_PORT=$1
BACKEND_PORT=$2

reliable_port_forward() {
    SERVICE=$1
    LOCAL_PORT=$2
    REMOTE_PORT=$3
    
    echo "🔗 Trying to activate Port Forwarding for ${SERVICE} (${LOCAL_PORT}:${REMOTE_PORT})..."
    
    for i in {1..10}; do
        nohup kubectl port-forward svc/${SERVICE} ${LOCAL_PORT}:${REMOTE_PORT} > /dev/null 2>&1 &
        PF_PID=$!
        
        sleep 1
        
        if ps -p ${PF_PID} > /dev/null; then
            echo "✅ Successful activating Port Forwarding for ${SERVICE} (PID: ${PF_PID})"
            return 0
        else
            echo "❗ Try №${i}: Connection to ${SERVICE} is aborted. Retry after 3 seconds..."
            sleep 3
        fi
    done
    
    echo "❌ Error: Can't activate Port Forwarding for ${SERVICE} after 10 tries."
    return 1
}

reliable_port_forward frontend-service ${FRONTEND_PORT} 80
reliable_port_forward backend-service ${BACKEND_PORT} ${BACKEND_PORT}

if [ $? -ne 0 ]; then
    exit 1
fi