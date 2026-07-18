# AquaHunter iOS / iPadOS

原生 SwiftUI 客户端，与 macOS 共享 `apple/Shared/` 中的数据客户端、模型、视觉系统和主要页面。生产界面只显示经过许可证审核且允许商业使用的数据；当前真实来源为 Statistics Norway Statbank 表 03024。

## 应用身份

- Product：`AquaHunterIOS`
- Bundle ID：`com.hsaffiliate.aquahunter`
- Apple Team：Hot Season Enterprise, Inc. (`C8Y5J74PQW`)
- 最低系统：iOS/iPadOS 17
- 版本：`1.0.0 (1)`
- 发布顺序：TestFlight → App Store

Apple Universal App ID 已注册，资源 ID 为 `9L83D5GT2F`。App Store Connect 应用记录尚需创建或核实。

## 当前生产功能

- Pulse：从 SSB 官方 PxWeb API 加载真实挪威养殖三文鱼周度出口基准。
- Markets：展示 NOK/kg、周度周期、出口重量、6W/30W/1Y 历史和来源链接。
- Pulse、Radar 与 Network：显示可离线使用的世界底图；只有已获授权的业务标记或图层才会叠加。
- Radar、Network：没有合规生产数据时保留地图并明确显示数据不可用，不生成概率、买家、港口作业或船舶位置。
- Aqua AI：当前发行版不提供；真实问答服务、来源引用、成本限制和隐私审查完成后再进入导航。
- 首次使用：必须确认《海上作业与法律风险声明》。
- Settings：背景、语言、风险声明与 `contact@hotseason.app` 支持邮件。

SSB 数据按 CC BY 4.0 使用。许可与来源规则：

- [`../docs/DATA_SOURCE_POLICY.md`](../docs/DATA_SOURCE_POLICY.md)
- [`../docs/data-sources.json`](../docs/data-sources.json)

## 地图策略

当前发布界面使用 MapLibre Native `6.26.0`（BSD 2-Clause）渲染随应用打包的 Natural Earth `5.1.2` `ne_110m_land.geojson`（公共领域）。地图完全离线，不调用 Apple Maps、Google Maps 或公共 OpenStreetMap 社区瓦片服务，也没有按请求计费。

地图资产路径为 [`../map-assets/natural-earth/ne_110m_land.geojson`](../map-assets/natural-earth/ne_110m_land.geojson)，SHA-256 为 `9e0729ee253ca7d7a5c4ae9395fb1902264c5377c52e224d13dd85010e2835d9`。许可与第三方声明见 [`../map-assets/README.md`](../map-assets/README.md) 和 [`../docs/THIRD_PARTY_NOTICES.md`](../docs/THIRD_PARTY_NOTICES.md)。该地图仅供地理方向参考，不是海图，不能用于导航或法律边界判断。

## 生成工程

```bash
cd ios
xcodegen generate
open AquaHunterIOS.xcodeproj
```

## 构建、测试与发布门禁

```bash
python3 tools/validate_data_sources.py --release
python3 tools/validate_release_content.py

cd ios
xcodebuild \
  -project AquaHunterIOS.xcodeproj \
  -scheme AquaHunterIOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

Release 构建会自动执行两个门禁脚本。任何未批准来源、虚构回退或阻止使用的地图依赖都会阻断构建。

发布归档优先使用 ASC：

```bash
asc xcode archive \
  --project ios/AquaHunterIOS.xcodeproj \
  --scheme AquaHunterIOS \
  --configuration Release \
  --clean \
  --archive-path .asc/artifacts/AquaHunterIOS.xcarchive \
  --xcodebuild-flag=-destination \
  --xcodebuild-flag=generic/platform=iOS
```

使用 AquaHunter 专用 App Store profile 导出 IPA：

```bash
asc xcode export \
  --archive-path .asc/artifacts/AquaHunterIOS.xcarchive \
  --export-options ios/ExportOptions.plist \
  --ipa-path .asc/artifacts/AquaHunterIOS.ipa \
  --overwrite
```

签名资源：

- iOS App Store profile：`AquaHunter iOS App Store 2026`
- profile 资源 ID：`JXA4CFW2VH`
- 到期时间：2027-07-17

导出 IPA 后上传 TestFlight：

```bash
asc publish testflight \
  --app APP_STORE_CONNECT_APP_ID \
  --ipa .asc/artifacts/AquaHunterIOS.ipa \
  --group "Internal Testers" \
  --test-notes "Official SSB weekly salmon export benchmark with source transparency" \
  --locale en-US \
  --wait
```

## App Store Connect 建议值

- 平台：iOS；如采用 Universal Purchase，同时选择 macOS
- 名称：`AquaHunter`
- 主要语言：English (U.S.)
- Bundle ID：`AquaHunter - com.hsaffiliate.aquahunter`
- SKU：`AQUAHUNTER-IOS-001`
- 用户访问：Full Access

## 发布阻断项

- App Store Connect 应用记录与 App ID 绑定尚需完成或核实。
- Distribution 签名、归档、导出选项和 TestFlight 内测组尚需验证。
- App Privacy、隐私政策公开 HTTPS URL、商店元数据和截图尚需完成。
- 风险声明必须由目标司法辖区的合格律师审查。
- 城市价格、Radar 概率、Network 业务记录在相应合规数据源到位前保持不可用；离线基础地图保持可用。
