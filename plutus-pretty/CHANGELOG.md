# Revision history for `plutus-pretty`

This format is based on [Keep A Changelog](https://keepachangelog.com/en/1.0.0).

## Unreleased

## 2.2 -- 2022-01-04

### Added

* `PlutusTx.Skeletal` instances for `AssetClass` and `(,,)`.

### Changed

* More compact JSON from `showSkeletal`.
* More efficient internals (~10% smaller on-chain code).

## 2.1 -- 2021-11-19

### Added

* `PlutusTx.Skeleton` for a combination `Pretty` and `Show` for on-chain
  debugging.

## 2.0 -- 2021-11-11

### Changed

- Plutus upgrade: `plutus` pinned to `3f089ccf0ca746b399c99afe51e063b0640af547`, 
  `plutus-apps` pinned to `404af7ac3e27ebcb218c05f79d9a70ca966407c9`

## 1.0 -- 2021-10-14 

* Initial release.
