# DeepSeek Unauthenticated ApplicationGraph — 2026-10-06

## Status
Preserved finding from ApplicationGraph.ps1 against the unauthenticated DeepSeek sign-in surface.

## Observation boundary
The observer inspected application structure from a browser under user control without authenticating to DeepSeek.

Reported capture:
- 9 CDP targets, including the DeepSeek page
- DOM: 123 nodes
- scripts: 9 total, 7 external
- resources: 69
- distinct resource hosts: 9
- form controls: 2 (text/password)
- localStorage key names: 32
- sessionStorage key names: 1

The capture intentionally recorded storage KEY NAMES only. It did not record storage values, credential values, cookie values, token values, or authorization-header values.

## Observed storage-key names

### DeepSeek/application namespace
- __appKit_@deepseek/chat_banner
- __appKit_@deepseek/chat_bannerSettings
- __appKit_@deepseek/chat_debug
- __appKit_@deepseek/chat_debugPanelEnabled
- __appKit_@deepseek/chat_fg_enableHcaptcha
- __appKit_@deepseek/chat_lastSessionValue
- __appKit_@deepseek/chat_localePreference
- __appKit_@deepseek/chat_themePreference
- __appKit_userInfo
- deepseek-device-id:chat
- searchEnabled
- thinkingEnabled
- settingsJwt
- userToken
- smidV2

### Remote-feature/configuration-looking namespace
- __ds_remote_feature_did
- __ds_remote_feature_store
- __ds_remote_feature_store_model
- __ds_remote_feature_store_provider
- searchStateTriggerAppliedVersion
- debugLiteModelChannel
- debugModelChannel

### Telemetry/APM-looking namespace
- __tea_cache_first_20006317
- __tea_cache_tokens_20006317
- APMPLUS__cache__server__config__675113
- APMPLUS675113
- __tea_session_id_20006317

### AWS-WAF-looking namespace
- aws_waf_referrer
- aws_waf_token_challenge_attempts
- awswaf_token_refresh_timestamp

### Other
- __close_idb_signal
- .thumbcache_<hash>
- closeUnsafeEnvWarn

## Cross-layer correlation
Earlier browser/network observations included runtime requests to:
- gator.volces.com/list
- apmplus.volces.com/settings/get/webpro
- fp-it-acc.portal101.cn/deviceprofile/v4

The ApplicationGraph storage-name surface includes identifiers/configuration namespaces whose naming is consistent with device, feature/configuration, telemetry/APM, and WAF-related application mechanisms.

This is useful convergence between two independently observable layers:
1. browser/network destinations
2. browser storage schema/key names

The relationship is CORRELATED/CONTEXTUAL unless a direct implementation link is independently demonstrated.

## What this evidence supports
- The unauthenticated page exposes substantial application structure before login.
- Storage schema/key names can reveal architectural intent without reading their values.
- Names such as userToken and settingsJwt establish named storage slots/schema surface; they do NOT establish that a usable token/value was present.
- Names such as deepseek-device-id:chat and __ds_remote_feature_did establish identifier-oriented storage namespaces; they do NOT by themselves establish the contents, persistence semantics, uniqueness, or identity linkage.
- AWS-WAF-looking key names establish WAF-related client storage surface; they do NOT by themselves prove that a particular challenge executed.
- Debug/configuration-looking keys establish exposed configuration/debug namespaces; they do NOT by themselves prove remote per-user control.
- APM/tea-looking names plus observed telemetry-related destinations are meaningful cross-layer evidence, but vendor ownership/SDK provenance requires independent verification before being promoted to OBSERVED fact.

## What this evidence does NOT support
Do not claim from key names alone that:
- any credential or authentication token was captured
- userToken/settingsJwt contained a value
- five identifiers all identify the same user
- AWS WAF definitely challenged this browser during the observation
- a particular third-party SDK/vendor owns every similarly named key
- a network request directly read or wrote a specific storage key
- an exact user identity was tracked across all observed services

Those claims require additional direct evidence.

## Architectural finding
ApplicationGraph demonstrates a useful privacy/security-audit mode:

APPLICATION SHAPE
  page/DOM
  scripts/resources
  host relationships
  form-control schema
  storage KEY NAMES
  network destinations

without collecting:

APPLICATION CONTENT/SECRETS
  passwords
  cookie values
  token values
  authorization headers
  storage values

This preserves the MachineObserver invariant: observe only what the sensor legitimately exposes and never upgrade inference into observation.

## Regression value
This artifact should be retained as the first unauthenticated ApplicationGraph baseline. Future runs can diff:
- target count/types
- DOM/resource counts
- external script set
- host set
- form-control schema
- localStorage/sessionStorage key-name sets

Changes should be reported as additions/removals, with raw observations preserved separately.

## Evidence classes
- CDP target/page/resource observations: OBSERVED
- storage key names: OBSERVED
- network destinations captured by browser/network sensors: OBSERVED
- cross-layer association: CORRELATED
- semantic meaning inferred from names: INFERRED/CONTEXT
- storage values not collected: UNKNOWN
- authentication/session contents: UNKNOWN
