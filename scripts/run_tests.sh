#!/bin/bash

set -e

echo "🧪 Running Flutter tests..."

cd "$(dirname "$0")/.."

flutter test --reporter=expanded

echo "✅ All tests passed"
