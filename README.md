# Telegram iOS — Liquid Glass (iOS Contest 2025)

## Demo

https://github.com/user-attachments/assets/165dfdf1-5e3c-4113-b8ce-6eb70947d5d7

## Description

This branch contains a **partial implementation of Liquid Glass effects** for **Telegram iOS**, created as a submission for **iOS Contest 2025**.

The current implementation focuses on the **Tab Bar only**, replicating the Liquid Glass appearance and interaction behavior (highlight, scale, bounce, stretching) on **iOS 18 and earlier**, without relying on new UI frameworks or external dependencies.

The solution is designed to integrate cleanly into the existing Telegram iOS codebase and follows the contest constraints regarding performance and stability.

### Branch

All contest-related changes are located in the following branch:

👉 **`contest_2025`**  
https://github.com/qaziro/Telegram-iOS/tree/contest_2025

### Technical Notes

- The glass distortion and refraction are based on a shader adapted from  
  **LiquidGlass** by BarredEwe:  
  https://github.com/BarredEwe/LiquidGlass.git
- The original shader is used under the **MIT License**
- No third-party UI frameworks were added
- Full backward compatibility with iOS 13.0 and newer.

# Telegram iOS Source Code Compilation Guide

We welcome all developers to use our API and source code to create applications on our platform.
There are several things we require from **all developers** for the moment.

# Creating your Telegram Application

1. [**Obtain your own api_id**](https://core.telegram.org/api/obtaining_api_id) for your application.
2. Please **do not** use the name Telegram for your app — or make sure your users understand that it is unofficial.
3. Kindly **do not** use our standard logo (white paper plane in a blue circle) as your app's logo.
4. Please study our [**security guidelines**](https://core.telegram.org/mtproto/security_guidelines) and take good care of your users' data and privacy.
5. Please remember to publish **your** code too in order to comply with the licences.

# Quick Compilation Guide

## Get the Code

```bash
git clone --recursive -j8 -b contest_2025 https://github.com/qaziro/Telegram-iOS.git
```

## Setup Xcode

Install Xcode (directly from https://developer.apple.com/download/applications or using the App Store).

## Adjust Configuration

1. Generate a random identifier:
```bash
openssl rand -hex 8
```
2. Create a new Xcode project. Use `Telegram` as the Product Name. Use `org.{identifier from step 1}` as the Organization Identifier.
3. Open `Keychain Access` and navigate to `Certificates`. Locate `Apple Development: your@email.address (XXXXXXXXXX)` and double tap the certificate. Under `Details`, locate `Organizational Unit`. This is the Team ID.
4. Edit `build-system/template_minimal_development_configuration.json`. Use data from the previous steps.

## Generate an Xcode project

```bash
python3 build-system/Make/Make.py \
--cacheDir="$HOME/telegram-bazel-cache" \
generateProject \
--configurationPath=build-system/template_minimal_development_configuration.json \
--xcodeManagedCodesigning
```

# Advanced Compilation Guide

## Xcode

1. Copy and edit `build-system/appstore-configuration.json`.
2. Copy `build-system/fake-codesigning`. Create and download provisioning profiles, using the `profiles` folder as a reference for the entitlements.
3. Generate an Xcode project:
```bash
python3 build-system/Make/Make.py \
--cacheDir="$HOME/telegram-bazel-cache" \
generateProject \
--configurationPath=configuration_from_step_1.json \
--codesigningInformationPath=directory_from_step_2
```

## IPA

1. Repeat the steps from the previous section. Use distribution provisioning profiles.
2. Run:
```bash
python3 build-system/Make/Make.py \
--cacheDir="$HOME/telegram-bazel-cache" \
build \
--configurationPath=...see previous section... \
--codesigningInformationPath=...see previous section... \
--buildNumber=100001 \
--configuration=release_arm64
```

# FAQ

## Xcode is stuck at "build-request.json not updated yet"

Occasionally, you might observe the following message in your build log:
```
"/Users/xxx/Library/Developer/Xcode/DerivedData/Telegram-xxx/Build/Intermediates.noindex/XCBuildData/xxx.xcbuilddata/build-request.json" not updated yet, waiting...
```
Should this occur, simply cancel the ongoing build and initiate a new one.

## Telegram_xcodeproj: no such package 

Following a system restart, the auto-generated Xcode project might encounter a build failure accompanied by this error:
```
ERROR: Skipping '@rules_xcodeproj_generated//generator/Telegram/Telegram_xcodeproj:Telegram_xcodeproj': no such package '@rules_xcodeproj_generated//generator/Telegram/Telegram_xcodeproj': BUILD file not found in directory 'generator/Telegram/Telegram_xcodeproj' of external repository @rules_xcodeproj_generated. Add a BUILD file to a directory to mark it as a package.
```
If you encounter this issue, re-run the project generation steps in the README.

# Tips

## Codesigning is not required for simulator-only builds

Add `--disableProvisioningProfiles`:
```bash
python3 build-system/Make/Make.py \
--cacheDir="$HOME/telegram-bazel-cache" \
generateProject \
--configurationPath=path-to-configuration.json \
--codesigningInformationPath=path-to-provisioning-data \
--disableProvisioningProfiles
```

## Versions

Each release is built using a specific Xcode version (see `versions.json`). The helper script checks the versions of the installed software and reports an error if they don't match the ones specified in `versions.json`. It is possible to bypass these checks:

```bash
python3 build-system/Make/Make.py --overrideXcodeVersion build ...
```
