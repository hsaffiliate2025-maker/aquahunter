# AquaHunter iOS / iPadOS

原生 SwiftUI 客户端，与 macOS 共享 `apple/Shared/` 中的数据客户端、模型、视觉系统和主要页面。生产界面只显示经过许可证审核且允许商业使用的数据；当前真实来源为 Statistics Norway Statbank 表 03024。

## 应用身份

- Product：`AquaHunterIOS`
- Bundle ID：`com.hotseason.aquahunter`
- Apple Team：Hot Season Enterprise, Inc. (`C8Y5J74PQW`)
- 最低系统：iOS/iPadOS 17
- 版本：`1.1.0 (3)`
- 发布顺序：TestFlight → App Store

Apple Universal App ID 已注册，资源 ID 为 `SQV9L48FRA`。App Store Connect 应用记录为 `AquaHunter: Seafood Intel`（App ID `6792849577`，SKU `AQUAHUNTER-IOS-001`）。首版 `1.0.0 (1)` 已上线；`1.1.0 (3)` 构建 ID `d41e84ef-bb83-4c90-855a-0720037df099` 已处理为 `VALID` 并绑定 iOS 版本。

## 当前生产功能

- Pulse：从 SSB 官方 PxWeb API 加载真实挪威养殖三文鱼周度出口基准。
- Markets：展示 NOK/kg、周度周期、出口重量、6W/30W/1Y 历史和来源链接。
- Pulse、Radar 与 Network：显示可离线使用的世界底图；只有已获授权的业务标记或图层才会叠加。
- Radar、Network：没有合规生产数据时保留地图并明确显示数据不可用，不生成概率、买家、港口作业或船舶位置。
- Aqua AI：当前发行版不提供；真实问答服务、来源引用、成本限制和隐私审查完成后再进入导航。
- 首次使用：必须确认《海上作业与法律风险声明》。
- Settings：背景、语言、风险声明与 `contact@hotseason.app` 支持邮件。
- Research Toolkit：在真实 SSB 序列上交付历史、UTF-8 CSV、同口径比较、市场快照、季节性、到岸成本及应用内提醒。
- 商业化：6 个有限额度订阅和 18 个结果次数包；StoreKit 2 验证后入本机幂等账本，只有成功交付的结果才扣次数。
- 本地化：App、购买状态、感谢语、功能入口引导、商店描述、关键词及全部 24 个商品覆盖 12 种语言；阿拉伯语支持 RTL。

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
  --archive-path .asc/artifacts/AquaHunterIOS-v1.1.0.xcarchive \
  --xcodebuild-flag=-destination \
  --xcodebuild-flag=generic/platform=iOS
```

使用 AquaHunter 专用 App Store profile 导出 IPA：

```bash
asc xcode export \
  --archive-path .asc/artifacts/AquaHunterIOS-v1.1.0.xcarchive \
  --export-options ios/ExportOptions.plist \
  --ipa-path .asc/artifacts/AquaHunterIOS-v1.1.0.ipa \
  --overwrite
```

签名资源：

- iOS App Store profile：`AquaHunter iOS App Store 2026 v1.1 Local Key`
- profile 资源 ID：`5935SJ9FXC`
- 到期时间：2027-07-17
- Distribution certificate 资源 ID：`38T5M89JA4`
- Distribution certificate SHA-1：`4E02BF84E8F1AEE62F0F887813081170EC915ADF`

导出 IPA 后上传 TestFlight：

```bash
asc publish testflight \
  --app APP_STORE_CONNECT_APP_ID \
  --ipa .asc/artifacts/AquaHunterIOS-v1.1.0.ipa \
  --group "Internal Testers" \
  --test-notes "Official SSB weekly salmon export benchmark with source transparency" \
  --locale en-US \
  --wait
```

当前已验证的本地产物：

- 路径：`.asc/artifacts/AquaHunterIOS-v1.1.0.ipa`
- 版本：`1.1.0 (3)`
- SHA-256：`8ab8e71fbb1aaa974c5024475717971a2408a210eb5aec456b7317f1dd5dfdfe`
- 签名：`iPhone Distribution: Hot Season Enterprise, Inc. (C8Y5J74PQW)`
- Embedded profile：`AquaHunter iOS App Store 2026 v1.1 Local Key`

该 IPA 已确认包含离线地图、Research Toolkit、StoreKit 2 商品目录和 12 语言资源；发布二进制中没有 Aqua AI/Ask 或开发期问答内容。

## App Store 截图与元数据

- iPhone 6.5-inch：[`../store/app-store/iphone-65/`](../store/app-store/iphone-65/)；3 张 1284×2778
- iPad Pro 12.9-inch：[`../store/app-store/ipad-pro-129/`](../store/app-store/ipad-pro-129/)；3 张 2048×2732
- 12 语言 `1.1.0` 元数据：[`../metadata/version/1.1.0/`](../metadata/version/1.1.0/)
- 24 × 12 商品元数据：[`../store-metadata/iap-localizations.json`](../store-metadata/iap-localizations.json)

两组截图均来自当前生产代码路径，展示真实 SSB 周度观测、离线地图和 30 周历史曲线，并分别通过：

```bash
asc screenshots validate \
  --path store/app-store/iphone-65 \
  --device-type IPHONE_65

asc screenshots validate \
  --path store/app-store/ipad-pro-129 \
  --device-type IPAD_PRO_3GEN_129

asc metadata validate --dir metadata
```

## App Store Connect 建议值

- 平台：iOS；如采用 Universal Purchase，同时选择 macOS
- 名称：`AquaHunter: Seafood Intel`（App Store 名称 `AquaHunter` 已被占用；商店显示名与产品名分离）
- 主要语言：English (U.S.)
- Bundle ID：`AquaHunter - com.hotseason.aquahunter`
- SKU：`AQUAHUNTER-IOS-001`
- 用户访问：Full Access

## 发布阻断项

- 2026-07-31：`1.1.0 (3)` 已处理为 `VALID` 并绑定版本；12 语言描述、更新说明、关键词、运行时付费工具文本和 24 × 12 IAP 文案已同步。
- 2026-07-30：build 3 已在 App Store Connect 申报仅使用豁免的系统 HTTPS/TLS（`usesNonExemptEncryption = false`）；重新执行 `asc validate` 后为 0 errors、0 blocking。
- App Review 备注已写明首次风险声明、Toolkit 商店入口、24 个商品、购买后多语言感谢与“打开功能”跳转、恢复购买和成功交付后才扣次数的规则。
- Apple 后台 18 个消耗型商品和 6 个订阅均为 `WAITING_FOR_REVIEW`，审核截图已换为显示真实 StoreKit 价格与购买按钮的 1206×2622 当前界面。
- 2026-07-31：iOS 审核提交 `beeb1cfa-196b-4d44-88b3-4778e4a0125e` 已包含 iOS `1.1.0 (3)`、18 个消耗型商品、`AquaHunter Markets` 订阅组和组内 6 个订阅。App Store Connect 将其显示为 26 个审核条目，实际对应 24 个付费 SKU；提交状态为 `WAITING_FOR_REVIEW`。
- 审核期间仍需完成沙盒购买、恢复、退款/撤销与 RTL 验证；若发现权益或本地化缺陷，应先撤回修正，不得让空权益商品通过审核。
- 风险声明必须由目标司法辖区的合格律师审查。
- 城市价格、Radar 概率、Network 业务记录在相应合规数据源到位前保持不可用；离线基础地图保持可用。
