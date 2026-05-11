# teefix — TEE re-provisioning helper

Companion tooling for the [`Being lenient on hardware reported supportedNumKeysInCsr`](https://github.com/spacealtctrl/RemoteKeyProvisioning/commit/fe5b60f) commit on this fork. Lets unlocked Sony Xperia 1V (SM8550) devices on this ROM keep a working TEE — fixing apps that refuse to run with broken hardware attestation (X / Twitter, Microsoft / Azure Authenticator, banking apps, etc.).

> Background and the full story behind why stock Sony TEE breaks: <https://xdaforums.com/t/fixing-tee-for-unlocked-devices-and-the-story-behind-play-integrity-being-broken-on-stock-rom.4773867/> by [@tongyuantongyu](https://xdaforums.com/m/tongyuantongyu.10131431/).

## What it does

`KmInstallKeybox` (extracted from a Xiaomi `fuxi` SM8550 dump — same SoC as Xperia 1V) is run with `LD_PRELOAD=./libqtikeymaster4.so` against the keybox you already imported in **Settings → crDroid Settings → Misc → Tricky Store**. This re-provisions the TEE's attestation keys so the on-device RKP service can subsequently fetch fresh keys from `remoteprovisioning.googleapis.com`.

Combined with the rkpdapp `getBatchSize()` patch in this repo, the TEE → RKP → Google chain finally works on unlocked Xperia 1V running this ROM.

This is **not** a Play Integrity / Strong Integrity bypass. It restores genuine TEE function. Strong Integrity still needs the keybox + Tricky Store (already handled by crDroid built-in).

## Files

| File                      | Purpose                                                          |
|---------------------------|------------------------------------------------------------------|
| `FIXTEE`                  | On-device shell script. Lives at `/data/adb/ksu/bin/FIXTEE`.     |
| `KmInstallKeybox`         | Qualcomm vendor tool that programs the TEE attestation keys.     |
| `libqtikeymaster4.so`     | QTI keymaster lib `KmInstallKeybox` preloads against.            |
| `install.sh`              | Host-side installer (pushes everything in place via `adb`).      |

`KmInstallKeybox` and `libqtikeymaster4.so` originate from a Xiaomi 13 (`missi-user 15 AQ3A.240912.001 OS2.0.200.7.VMCCNXM`) ROM dump, which shares the SM8550 SoC. Sony does not ship these binaries in stock or AOSP-derived ROMs.

## Install (host)

Connect the device with USB debugging + root debugging enabled, then from this directory:

```
./install.sh
```

That pushes the binaries to `/data/local/tmp/TEEFix/`, stashes backup copies in `/data/adb/teefix/` (survives `/data/local/tmp` cleanup), and drops `FIXTEE` into `/data/adb/ksu/bin/` so it resolves on root's `PATH`.

## Run (device, every ROM update)

In Termux (or any root shell):

```
su
FIXTEE
```

Then **reboot** and connect to the internet — wait a few seconds for RKP to fetch fresh keys from Google. If `KeyAttestation` still fails, run `FIXTEE` again and reboot a second time (the original XDA post notes that two rounds are sometimes required).

## How `FIXTEE` finds the keybox

It reads `secure: spoof_trickystore_keybox` (the base64-encoded XML that crDroid's built-in Tricky Store writes when you import a keybox via Settings → crDroid Settings → Misc → Tricky Store), decodes it to `/data/local/tmp/TEEFix/keybox.xml`, auto-detects the `DeviceID` from the file, and runs:

```
LD_PRELOAD=./libqtikeymaster4.so ./KmInstallKeybox keybox.xml <DeviceID> true rkp
```

Whatever keybox you change to in Settings is what the next `FIXTEE` run uses — no edits needed.

## Why this lives here

This RKP fork already carries the rkpdapp patch needed for SM8550 TEE's batch-of-4 limit. Pairing the user-side helper script in the same repo keeps the two halves of the fix together: a ROM update bumps both at once.

## Credits

- [@tongyuantongyu](https://xdaforums.com/m/tongyuantongyu.10131431/) — original investigation, RKP patch, and TEEFix.zip.
- Xiaomi `fuxi` ROM dump — source of the QTI keymaster binaries.
