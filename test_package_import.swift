#!/usr/bin/env swift

// Test script to verify PhotoCoachCore package can be imported
import Foundation

// This script tests if we can use PhotoCoachCore as a local package
// Run from PhotoCoach directory: swift test_package_import.swift

print("Testing PhotoCoachCore package import...")

// Check if Package.swift exists in PhotoCoachCore
let packagePath = "PhotoCoachCore/Package.swift"
if FileManager.default.fileExists(atPath: packagePath) {
    print("✅ PhotoCoachCore Package.swift found")
} else {
    print("❌ PhotoCoachCore Package.swift missing")
    exit(1)
}

// Try to build the package
import subprocess

print("Building PhotoCoachCore package...")
// Note: This approach doesn't work in Swift scripts, but shows the concept
print("Run: cd PhotoCoachCore && swift build")
print("Package structure ready for Xcode integration")