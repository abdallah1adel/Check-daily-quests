#!/bin/bash

echo "📦 GITHUB REPOSITORY SETUP"
echo "=========================="
echo ""

# Navigate to project root
cd /Users/pcpos/Desktop/MegamanCompanion

# 1. Setup for PRIVATE repo (companion-private)
echo "🔒 STEP 1: Push to PRIVATE repo (full codebase)"
echo "────────────────────────────────────────────────"
echo ""

# Check if already a git repo
if [ ! -d ".git" ]; then
    echo "Initializing git repository..."
    git init
    git branch -M main
fi

# Add all files (no gitignore restrictions for private)
echo "Adding all files to staging..."
git add .

# Commit
echo "Creating commit..."
git commit -m "Phase 2: Multi-user system with Firebase & Facebook integration"

# Add private remote
echo "Adding private remote..."
git remote remove origin 2>/dev/null
git remote add origin https://github.com/abdallah1adel/companion-private.git

# Push to private
echo ""
read -p "Ready to push to PRIVATE repo? This will upload ALL files including Protocol 22. (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Pushing to private repo..."
    git push -u origin main --force
    echo "✅ Private repo updated!"
fi

echo ""
echo "────────────────────────────────────────────────"
echo ""

# 2. Setup GitHub Pages
echo "📄 STEP 2: Enable GitHub Pages for legal docs"
echo "────────────────────────────────────────────────"
echo ""
echo "1. Go to: https://github.com/abdallah1adel/companion-private/settings/pages"
echo "2. Under 'Source', select: Deploy from a branch"
echo "3. Select branch: 'main'"
echo "4. Select folder: '/docs'"
echo "5. Click 'Save'"
echo ""
echo "Your legal pages will be available at:"
echo "  Privacy: https://abdallah1adel.github.io/companion-private/privacy.html"
echo "  Deletion: https://abdallah1adel.github.io/companion-private/delete-data.html"
echo ""
read -p "Press ENTER when you've enabled GitHub Pages..."

# 3. Create PUBLIC repo version
echo ""
echo "🌐 STEP 3: Prepare PUBLIC repo (sanitized version)"
echo "────────────────────────────────────────────────"
echo ""
echo "This will create a clean version WITHOUT sensitive data."
echo ""
read -p "Create public repo version? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Create public directory
    mkdir -p ../MegamanCompanion-public
    
    # Copy files but use public .gitignore
    echo "Copying files (excluding sensitive data)..."
    rsync -av --exclude-from='.gitignore.public' \
        --exclude='.git' \
        --exclude='scripts/venv' \
        --exclude='*.mlpackage' \
        . ../MegamanCompanion-public/
    
    # Copy public .gitignore as main .gitignore
    cp .gitignore.public ../MegamanCompanion-public/.gitignore
    
    # Navigate to public folder
    cd ../MegamanCompanion-public
    
    # Initialize git
    git init
    git branch -M main
    git add .
    git commit -m "Initial public release - PCPOS Companion"
    
    echo ""
    echo "✅ Public repo prepared at: ../MegamanCompanion-public"
    echo ""
    echo "Next steps for PUBLIC repo:"
    echo "1. Create NEW repo at: https://github.com/new"
    echo "2. Name it: 'companion' (public)"
    echo "3. Make it PUBLIC"
    echo "4. Then run:"
    echo ""
    echo "   cd ../MegamanCompanion-public"
    echo "   git remote add origin https://github.com/abdallah1adel/companion.git"
    echo "   git push -u origin main"
    echo ""
fi

echo ""
echo "🎉 SETUP COMPLETE!"
echo ""
echo "Summary:"
echo "✅ Private repo: Full codebase with Protocol 22"
echo "✅ GitHub Pages: Legal docs for Facebook compliance"
echo "✅ Public repo: Sanitized version (if created)"
echo ""
echo "Facebook URLs to use:"
echo "  Privacy: https://abdallah1adel.github.io/companion-private/privacy.html"
echo "  Deletion: https://abdallah1adel.github.io/companion-private/delete-data.html"
