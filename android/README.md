# AquaHunter Android

原生 Android 客户端，采用 Kotlin 与 Jetpack Compose。生产界面只显示经过许可证审核、允许商业使用并保留来源链的数据；当前已接入 Statistics Norway（SSB）Statbank 表 03024 的真实周度挪威养殖三文鱼出口价格与出口重量。

## 应用身份

- applicationId：`com.hsaffiliate.aquahunter`
- versionName：`0.1.0`
- minSdk：API 26
- compile/targetSdk：API 36
- 计划首次发布轨道：Google Play Internal testing
- Android developer verification：必须注册同一 package name

## 当前生产功能

- Markets：从 SSB 官方 PxWeb API 读取真实数据，保留 NOK/kg、周度周期和原始统计语义。
- Pulse：展示同一授权数据源的最新观测及趋势。
- Pulse、Radar 与 Network：显示可离线使用的世界底图；只有已获授权的业务标记或图层才会叠加。
- Radar、Network：没有合规生产数据时保留地图并明确显示数据不可用，不生成后备概率、买家、港口作业或船舶位置。
- Aqua AI：当前发行版不提供；真实问答服务、来源引用、成本限制和隐私审查完成后再进入导航。
- 首次使用：必须确认《海上作业与法律风险声明》。
- Settings：背景、语言、风险声明和联系邮箱 `contact@hotseason.app`。

SSB 来源使用 CC BY 4.0，工程规则与完整清单见：

- [`../docs/DATA_SOURCE_POLICY.md`](../docs/DATA_SOURCE_POLICY.md)
- [`../docs/data-sources.json`](../docs/data-sources.json)

## 地图策略

Google Maps SDK 及 API key 已从 Android 生产代码移除。当前版本使用 MapLibre Native OpenGL `13.0.2`（BSD 2-Clause）渲染随应用打包的 Natural Earth `5.1.2` `ne_110m_land.geojson`（公共领域）。地图完全离线，不调用 Google Maps、Apple Maps 或公共 OpenStreetMap 社区瓦片服务，也没有按请求计费。

地图资产路径为 [`../map-assets/natural-earth/ne_110m_land.geojson`](../map-assets/natural-earth/ne_110m_land.geojson)，SHA-256 为 `9e0729ee253ca7d7a5c4ae9395fb1902264c5377c52e224d13dd85010e2835d9`。许可与第三方声明见 [`../map-assets/README.md`](../map-assets/README.md) 和 [`../docs/THIRD_PARTY_NOTICES.md`](../docs/THIRD_PARTY_NOTICES.md)。该地图仅供地理方向参考，不是海图，不能用于导航或法律边界判断。

应用不使用设备定位或 Wi-Fi 状态，并通过 manifest merger 显式移除 MapLibre 库清单中的可选 `ACCESS_FINE_LOCATION`、`ACCESS_COARSE_LOCATION` 与 `ACCESS_WIFI_STATE` 权限。未来若增加精细地图，只能使用自托管数据或另有明确商业移动端授权的供应商。

## 本地运行与验证

要求 Android Studio、JDK 17+ 和 Android SDK 36。

```bash
cd android
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew testDebugUnitTest lintDebug assembleDebug
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew connectedDebugAndroidTest
```

发布门禁：

```bash
cd ..
python3 tools/validate_data_sources.py --release
python3 tools/validate_release_content.py
```

产物：

- Debug APK：`android/app/build/outputs/apk/debug/app-debug.apk`
- Signed Release APK：`android/app/build/outputs/apk/release/app-release.apk`
- Release AAB：`android/app/build/outputs/bundle/release/app-release.aab`

当前已验证的本地产物：

- AAB SHA-256：`9169fec91b01321df2eb8ca57e8b3ede98633aa508eab493492ec42a466c172f`
- APK SHA-256：`850e8ab655612e794b686c2ebae712893f685ab7bc198fa45cebeeb2e3218a13`
- Upload certificate SHA-256：`7bc5fe76f96a300a7c4281e957d5659bf089ac68902f2abd951255f3c5cc960e`

签名包已确认包含离线地图样式和 Natural Earth GeoJSON；release DEX 中没有 Aqua AI/Ask 或开发期问答内容。每次改动 release 代码、依赖或版本号后必须重新构建并复核哈希。

## Google Play 签名

1. 在 Android developer verification 注册 `com.hsaffiliate.aquahunter`。
2. 创建 AquaHunter 独立 upload key；密码自动存入 macOS 钥匙串，keystore 保存在用户资料目录而不是仓库：

```bash
android/scripts/create_upload_keystore.sh
```

3. 备份 `$HOME/Library/Application Support/AquaHunter/signing/aquahunter-upload.p12`，禁止提交仓库或发送到聊天。
4. 启用 Play App Signing。
5. 构建签名 AAB：

```bash
android/scripts/build_signed_release.sh
```

Release 构建现在必须提供完整 upload signing；直接运行无签名 `bundleRelease` 会失败，不再产生可能被误上传的未签名 AAB。也可使用忽略的 `android/keystore.properties` 手动配置，但默认发布脚本不会把密码写入仓库。

## 使用 GPD API 发布

Google Play Console 必须先创建应用记录，并把服务账号授权到该应用。只有在来源门禁、内容门禁、签名和商店政策全部通过后才能上传：

```bash
gpd auth doctor --refresh-check --output table
gpd auth check --package com.hsaffiliate.aquahunter --output table
gpd validate \
  --package com.hsaffiliate.aquahunter \
  --track internal \
  --file app/build/outputs/bundle/release/app-release.aab \
  --network \
  --strict
gpd publish play app/build/outputs/bundle/release/app-release.aab \
  --package com.hsaffiliate.aquahunter \
  --track internal \
  --status completed \
  --dry-run
```

确认 dry-run 计划无误后，再去掉 `--dry-run`。

## 商店与政策资料

- [`docs/google-play/RELEASE_CHECKLIST.md`](docs/google-play/RELEASE_CHECKLIST.md)
- [`docs/google-play/STORE_LISTING.md`](docs/google-play/STORE_LISTING.md)
- [`docs/google-play/DATA_SAFETY.md`](docs/google-play/DATA_SAFETY.md)
- [`docs/google-play/PRIVACY_POLICY.md`](docs/google-play/PRIVACY_POLICY.md)
- [`../store/google-play/`](../store/google-play/)：3 张 Pixel 6 正式截图、512×512 图标和 1024×500 feature graphic

Google Play 只上传 `store/google-play/` 中经过筛选的素材。被忽略的 `artifacts/screenshots/` 包含历史开发截图，其中部分带旧 demo UI，不得上传。

## 发布阻断项

- Google Play 应用记录与服务账号权限尚需核实。
- 本地 upload keystore 与签名发布构建已验证；Play App Signing 需在首次上传时启用并核实。
- 隐私政策文案、法定运营主体和邮寄地址已写入仓库并部署到 `https://hotseason.app/en/policy#aquahunter`；提交 Data safety 时仍需与最终 AAB 再次逐项核对。
- 上线前必须重新核对实际 AAB 的依赖、网络行为、Data safety 和目标地区法律。
