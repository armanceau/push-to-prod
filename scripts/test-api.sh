#!/bin/bash

# Script de test rapide pour vérifier le bon fonctionnement

echo "Lancement des tests de vérification..."

BASE_URL="http://localhost:3000"
TIMEOUT=30

test_endpoint() {
    local url=$1
    local expected_status=$2
    local description=$3
    
    echo "Testing: $description"
    
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" $url)
    http_code=$(echo $response | tr -d '\n' | sed -E 's/.*HTTPSTATUS:([0-9]{3})$/\1/')
    
    if [ "$http_code" -eq "$expected_status" ]; then
        echo "  ✅ PASS: $description (Status: $http_code)"
    else
        echo "  ❌ FAIL: $description (Expected: $expected_status, Got: $http_code)"
        return 1
    fi
}

test_json_endpoint() {
    local url=$1
    local json_data=$2
    local expected_status=$3
    local description=$4
    
    echo "Testing: $description"
    
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
        -H "Content-Type: application/json" \
        -d "$json_data" \
        $url)
    
    http_code=$(echo $response | tr -d '\n' | sed -E 's/.*HTTPSTATUS:([0-9]{3})$/\1/')
    
    if [ "$http_code" -eq "$expected_status" ]; then
        echo "  ✅ PASS: $description (Status: $http_code)"
    else
        echo "  ❌ FAIL: $description (Expected: $expected_status, Got: $http_code)"
        return 1
    fi
}

echo "⏳ Attente du démarrage de l'application..."
for i in $(seq 1 $TIMEOUT); do
    if curl -s $BASE_URL/health > /dev/null 2>&1; then
        echo "Application démarrée !"
        break
    fi
    if [ $i -eq $TIMEOUT ]; then
        echo "Timeout: L'application n'a pas démarré dans les $TIMEOUT secondes"
        exit 1
    fi
    sleep 1
done

echo ""
echo "Tests des endpoints..."

test_endpoint "$BASE_URL/" 200 "Page d'accueil"
test_endpoint "$BASE_URL/health" 200 "Health check"
test_endpoint "$BASE_URL/api/users" 200 "API utilisateurs"
test_endpoint "$BASE_URL/nonexistent" 404 "Route inexistante"

echo ""
echo "Tests de l'API calculatrice..."

test_json_endpoint "$BASE_URL/api/calculate" '{"operation":"add","a":5,"b":3}' 200 "Addition valide"
test_json_endpoint "$BASE_URL/api/calculate" '{"operation":"divide","a":10,"b":0}' 400 "Division par zéro"
test_json_endpoint "$BASE_URL/api/calculate" '{"operation":"invalid","a":1,"b":2}' 400 "Opération invalide"

echo ""
echo "Tests terminés !"