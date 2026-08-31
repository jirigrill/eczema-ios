# Signing and CloudKit container

## Overview

What exists on the Apple Developer account for this app, so the project-scaffolding work copies these values rather than re-deriving them. Development only — nothing here is distribution or submission setup.

Recorded from the run of [`scripts/signing-setup.sh`](../../scripts/signing-setup.sh), resolving [eczema-helper#768](https://github.com/jirigrill/eczema-helper/issues/768).

**This file holds identifiers and capabilities only.** No keys, no `.p12`, no Team ID, no device UDID — [#699](https://github.com/jirigrill/eczema-helper/issues/699) rules out secrets in the repo entirely, and CI builds with `CODE_SIGNING_ALLOWED=NO` so it never needs an identity. The Team ID and UDID live in a gitignored `.env` written by the wizard.

---

## Identifiers

| Thing | Value |
| --- | --- |
| Bundle identifier | `jirigrill.eczema` |
| CloudKit container | `iCloud.jirigrill.eczema` |
| App ID description | Eczema Diary |

Both strings were settled by [#697](https://github.com/jirigrill/eczema-helper/issues/697), **deliberately independent of the app's name**. `Eczema Diary` is a working title and the real name is still an open decision ([#770](https://github.com/jirigrill/eczema-helper/issues/770)), needed before first submission. The identifiers do not have to resemble it — `iCloud.<bundle-id>` is an Xcode default, not an Apple rule — so the rename is free.

The bundle id is two segments rather than reverse-DNS, on purpose. Apple's freeze points differ and are worth knowing: the bundle id stays editable until the **first build upload**, but a Store record's SKU is permanent **immediately at record creation**. A CloudKit container can never be deleted or renamed.

## Signing identity

A development identity already existed on the build Mac and was reused — nothing was minted. A development certificate is **per-team, not per-bundle-id**, so the identity that signed the earlier spikes ([#752](https://github.com/jirigrill/eczema-helper/issues/752)) signs the app target too.

- Certificate: `Apple Development: Jiri Grill (57V7L4QL47)`, valid to 2027-08-17
- Enrolment: **individual**, no s.r.o. for v1
- Distribution certificate: **none, deliberately.** Development only; distribution is a submission-time concern.

The physical test device (iPhone 15 Pro) is registered on the team explicitly, rather than only implicitly by Xcode's automatic signing, so any profile on the team can use it.

## Capabilities on the App ID

Two map decisions force these rather than leaving them to preference:

- [#705](https://github.com/jirigrill/eczema-helper/issues/705) — sync is **mandatory, with no toggle**, so iCloud with CloudKit support is required.
- [#714](https://github.com/jirigrill/eczema-helper/issues/714) — **every encryptable field is encrypted, permanently**. Mirroring arrives on silent pushes, so Push Notifications is required too.

Registered on `jirigrill.eczema`: **iCloud** (with CloudKit support, container `iCloud.jirigrill.eczema` selected) and **Push Notifications**.

## Entitlements for the scaffolding work

```
com.apple.developer.icloud-services              = [ CloudKit ]
com.apple.developer.icloud-container-identifiers = [ iCloud.jirigrill.eczema ]
com.apple.developer.aps-environment              = development
UIBackgroundModes                                = [ remote-notification ]
```

Absent on purpose:

- **No keychain-sharing group.** This is the one entitlement a reader might expect from [#763](https://github.com/jirigrill/eczema-helper/issues/763)'s photo-encryption key. That key lives in this app's own keychain item with `kSecAttrSynchronizable = true` and `AfterFirstUnlock` accessibility; keychain **sync** needs no sharing entitlement. Sharing is for crossing app boundaries, which nothing here does.
- **No App Groups.** Nothing crosses a process boundary.

## Container state

The container is registered and visible in the CloudKit console with a **Development** environment present.

**The schema has not been promoted to Production, and must not be promoted casually.** That promotion is a hard deadline on [#714](https://github.com/jirigrill/eczema-helper/issues/714) (field encryption is irreversible once the schema is live) and [#762](https://github.com/jirigrill/eczema-helper/issues/762) — tripping it early from a stray verification click in the console would be expensive.
