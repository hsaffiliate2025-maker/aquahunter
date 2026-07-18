# AquaHunter macOS

原生 SwiftUI 桌面客户端，使用适合采购、研究和运营团队的宽屏布局，并与 iOS 共享 `apple/Shared/` 产品核心。当前真实来源为 Statistics Norway Statbank 表 03024；无合规来源的模块显示不可用。

## 应用身份

- Product：`AquaHunterMac`
- Bundle ID：`com.hsaffiliate.aquahunter`
- Apple Team：Hot Season Enterprise, Inc. (`C8Y5J74PQW`)
- 最低系统：macOS 14
- 版本：`1.0.0 (1)`
- Sandbox：启用，仅允许客户端网络访问
- 发布：Mac TestFlight / Mac App Store

## 当前生产功能

- SSB 官方周度挪威养殖三文鱼出口价格、重量和历史曲线。
- 原始 NOK/kg 单位、周度周期、来源、许可与统计口径说明。
- 使用 Natural Earth 公共领域数据离线绘制的世界底图；缺失业务数据时不伪造图层。
- Aqua AI 当前发行版不提供；真实问答服务和引用链完成后再进入导航。
- 首次风险声明、背景与语言设置、重复查看声明和支持邮件。

许可证与生产来源清单：

- [`../docs/DATA_SOURCE_POLICY.md`](../docs/DATA_SOURCE_POLICY.md)
- [`../docs/data-sources.json`](../docs/data-sources.json)

## 地图策略

macOS 使用 SwiftUI Canvas 渲染与移动端相同的 Natural Earth `5.1.2` `ne_110m_land.geojson` 公共领域资产。当前 MapLibre iOS 二进制发行包不含 macOS slice，因此桌面端不强行链接不兼容框架。地图完全离线，不调用 Apple Maps、Google Maps 或公共 OpenStreetMap 社区瓦片服务。

地图文件、固定 SHA-256 和使用限制见 [`../map-assets/README.md`](../map-assets/README.md)；第三方说明见 [`../docs/THIRD_PARTY_NOTICES.md`](../docs/THIRD_PARTY_NOTICES.md)。该地图不是海图，不能用于导航或法律边界判断。

## 生成工程

```bash
cd macos
xcodegen generate
open AquaHunterMac.xcodeproj
```

## 构建、测试与发布门禁

```bash
python3 tools/validate_data_sources.py --release
python3 tools/validate_release_content.py

cd macos
xcodebuild \
  -project AquaHunterMac.xcodeproj \
  -scheme AquaHunterMac \
  -destination 'platform=macOS' \
  test
```

使用 ASC 归档：

```bash
asc xcode archive \
  --project macos/AquaHunterMac.xcodeproj \
  --scheme AquaHunterMac \
  --configuration Release \
  --clean \
  --archive-path .asc/artifacts/AquaHunterMac.xcarchive \
  --xcodebuild-flag=-destination \
  --xcodebuild-flag=generic/platform=macOS
```

使用 AquaHunter 专用 Mac App Store profile 导出 `.pkg`：

```bash
xcodebuild -exportArchive \
  -archivePath .asc/artifacts/AquaHunterMac.xcarchive \
  -exportPath .asc/artifacts/AquaHunterMacExport \
  -exportOptionsPlist macos/ExportOptions.plist
```

签名资源：

- Mac App Store profile：`AquaHunter Mac App Store 2026 Local Key`
- profile 资源 ID：`A3PRHWPWA8`
- 到期时间：2027-07-18

为避免修改整个登录钥匙串，macOS 导出使用独立临时钥匙串。先在“钥匙串访问”的 `login → My Certificates` 中分别导出以下两项，证书下面必须带有私钥：

- `3rd Party Mac Developer Application: Hot Season Enterprise, Inc. (C8Y5J74PQW)`
- `3rd Party Mac Developer Installer: Hot Season Enterprise, Inc. (C8Y5J74PQW)`

保存为：

- `/private/tmp/aquahunter-final-signing/AquaHunterApplication.p12`
- `/private/tmp/aquahunter-final-signing/AquaHunterInstaller.p12`

然后运行：

```bash
zsh tools/setup_macos_signing_keychain.sh
```

脚本只操作 AquaHunter 临时钥匙串，密码隐藏输入，并在继续导出前验证 `codesign` 与 `productbuild` 均可无弹窗调用。不要对整个 `login.keychain` 执行 `set-key-partition-list`。

Mac App Store 导出 `.pkg` 后上传：

```bash
asc builds upload \
  --app APP_STORE_CONNECT_APP_ID \
  --pkg .asc/artifacts/AquaHunterMac.pkg \
  --version 1.0.0 \
  --build-number 1 \
  --wait
```

## 桌面版差异化计划

- 多栏市场比较和可调时间窗口
- 大屏贸易流、港口和船舶地图
- CSV/Excel 批量导入导出
- 采购监控工作区、规则告警和团队共享
- Enterprise API、Webhook、审计日志和 ERP 集成

上述功能必须在数据许可、隐私、安全与商业合同完成后启用。

## 发布阻断项

- Mac Distribution 签名、归档、导出和 TestFlight/App Store 上传尚需验证。
- App Store Connect Universal Purchase 结构尚需确认。
- App Privacy、公开隐私政策、商店元数据和截图尚需完成。
- 文件导入、通知或新网络服务加入时必须同步复审 entitlements 与隐私声明。
