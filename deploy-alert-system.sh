#!/bin/bash

# RescueTN Alert System Deployment Script
# This script deploys the Cloud Functions and Firestore rules

set -e

echo "🚀 RescueTN Alert System Deployment"
echo "===================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI not found. Please install it first:${NC}"
    echo "npm install -g firebase-tools"
    exit 1
fi

echo -e "${YELLOW}1️⃣  Installing Node.js dependencies...${NC}"
cd functions
npm install --production
cd ..
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

echo -e "${YELLOW}2️⃣  Deploying Firestore rules...${NC}"
firebase deploy --only firestore:rules --project rescuetn
echo -e "${GREEN}✅ Firestore rules deployed${NC}"
echo ""

echo -e "${YELLOW}3️⃣  Deploying Cloud Functions...${NC}"
firebase deploy --only functions --project rescuetn
echo -e "${GREEN}✅ Cloud Functions deployed${NC}"
echo ""

echo -e "${YELLOW}4️⃣  Verifying deployment...${NC}"
firebase functions:list --project rescuetn
echo ""

echo -e "${GREEN}🎉 Deployment complete!${NC}"
echo ""
echo "📊 Next steps:"
echo "1. Go to Firebase Console: https://console.firebase.google.com/project/rescuetn"
echo "2. Check Functions tab for deployment status"
echo "3. Test by creating an alert in Firestore Console"
echo "4. View function logs: firebase functions:log --project rescuetn"
echo ""
echo -e "${GREEN}Alert system is now live! 🚀${NC}"
