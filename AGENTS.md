# TokenTracker Project Notes

## Goal
iOS app that tracks remaining usage per AI provider (OpenAI / DeepSeek / Qwen / Zhipu). The app is designed to be provider‑agnostic and modular so real token/balance APIs can be plugged in later.

## Current Architecture
- UI is SwiftUI with a `TabView`:
  - `Dashboard` shows current remaining/limit, burn rate, ETA, and trend charts.
  - `Settings` manages provider configuration (model + API key + optional budget).
- Domain models:
  - `ProviderID`, `Provider`, `TokenUsage`, `TokenUsageSample`, `UsageUnit`.
  - `UsageUnit` supports tokens or currency (e.g. USD) for balance-based APIs.
- Services:
  - `TokenUsageClient` protocol for providers.
  - `ProviderRegistry` wires ProviderID -> TokenUsageClient.
  - `TokenUsageRepository` owns cache + history + retention.
  - `ProviderSettingsStore` (UserDefaults + Keychain).
  - Local JSON stores: `LocalTokenUsageStore`, `LocalTokenUsageHistoryStore`.

## Data Lifecycle
- Refresh interval: **60 seconds** (see `DashboardViewModel.startAutoRefresh`).
- Each refresh records a `TokenUsageSample`.
- History retention: **7 days**, older samples are pruned in `TokenUsageRepository`.

## DeepSeek Integration
- Implemented in `DeepSeekTokenUsageClient`.
- Uses `GET /user/balance` with `Authorization: Bearer <API_KEY>`.
- Balance data mapped to `TokenUsage` with unit = currency (USD/CNY).
- Optional budget (set in Settings) becomes `limit` if higher than current balance.
- Note: DeepSeek currently uses balance endpoint (not raw token usage). Replace when a token-usage endpoint is available.

## Settings UX
- `SettingsView` lets user pick model, save API key (Keychain), set budget.
- `ProviderCatalog` is the source for provider models/base URLs.

## Adding a New Provider
1. Add provider cases/models/base URL in `ProviderCatalog` and `ProviderID`.
2. Implement `TokenUsageClient` (e.g., `OpenAITokenUsageClient`).
3. Wire it in `ProviderRegistry`.
4. Add settings fields in `SettingsView` / `SettingsViewModel`.

## Key Files
- UI: `TokenTracker/Views/*`
- ViewModels: `TokenTracker/ViewModels/*`
- Services: `TokenTracker/Services/*`
- Models: `TokenTracker/Models/*`
- Xcode project: `TokenTracker.xcodeproj`
