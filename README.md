# AquaHunter

> Global Seafood Intelligence Platform  
> Bloomberg for the Global Seafood Industry.

AquaHunter 是面向全球海鲜产业的跨平台数据产品，聚合价格、买家、港口、贸易、船舶和海洋环境信号，并以可解释的 Fish Probability 与 AI 分析辅助采购和作业判断。

当前仓库是 Android、iOS、macOS 三端 monorepo。三端生产界面已接入 Statistics Norway（SSB）Statbank 表 03024 的真实周度三文鱼出口数据，以及 Natural Earth 5.1.2 公共领域离线世界底图；其他业务图层在没有合规数据时显示不可用，不使用虚构回退。任何新增来源都必须真实、可追溯，并且许可证或合同明确允许 AquaHunter 所需的商业使用、转换与展示。

## 平台入口

| 平台 | 工程 | 平台文档 | 当前状态 |
|---|---|---|---|
| Android | [`android/`](android/) | [`android/README.md`](android/README.md) | Compose，真实 SSB 数据，MapLibre 离线底图 |
| iOS / iPadOS | [`ios/`](ios/) | [`ios/README.md`](ios/README.md) | SwiftUI，真实 SSB 数据，MapLibre 离线底图 |
| macOS | [`macos/`](macos/) | [`macos/README.md`](macos/README.md) | SwiftUI，真实 SSB 数据，Natural Earth 离线底图 |

共享 Apple 数据模型、视觉系统和主要页面位于 [`apple/Shared/`](apple/Shared/)。完整产品需求保存在 [`docs/PRD.md`](docs/PRD.md)。数据许可政策与机器可检查的白名单分别位于 [`docs/DATA_SOURCE_POLICY.md`](docs/DATA_SOURCE_POLICY.md) 和 [`docs/data-sources.json`](docs/data-sources.json)。最终商业图标母版位于 [`artifacts/icon/aquahunter-app-icon-final.png`](artifacts/icon/aquahunter-app-icon-final.png)。

## 身份与发布渠道

| 项目 | 值 |
|---|---|
| 产品名 | `AquaHunter` |
| Android applicationId | `com.hsaffiliate.aquahunter` |
| Apple Universal Bundle ID | `com.hsaffiliate.aquahunter` |
| Apple Team | Hot Season Enterprise, Inc. (`C8Y5J74PQW`) |
| Apple 上传工具 | `asc`（Hot Season App Store Connect API） |
| Google 上传工具 | `gpd`（Google Play Developer API） |

Apple Universal App ID 已注册。App Store Connect 应用记录、Google Play 应用记录、商店资料、签名构建和上传必须继续使用完全相同的标识。

## 总开发计划

### Phase 0 — 三端工程基线

- [x] Android Compose 开发基线
- [x] iOS/macOS SwiftUI 工程结构和共享产品核心
- [x] 三端统一商业图标与深海蓝视觉语言
- [x] Apple Universal Bundle ID 注册
- [ ] iOS、macOS 和 Android 全部在 CI 中构建测试
- [ ] 12 语言字符串目录、翻译完整性检查和阿拉伯语 RTL

### Phase 1 — 可用数据闭环

- [x] 建立数据源许可白名单、溯源字段和发布校验器
- [x] 三端生产构建不编译或引用开发期虚构业务数据
- [x] SSB 03024 周度三文鱼出口基准、历史曲线、来源、许可与时效
- [x] 三端 Natural Earth 5.1.2 公共领域离线世界底图
- [x] iOS/Android MapLibre Native 商业可用渲染器与第三方许可清单
- [x] 无合规源时的不可用/拒答状态
- [ ] 统一后端 API Contract 与完整 Species、Market、PriceObservation、Organization 模型
- [ ] 增加经过许可审计的城市市场价格，支持同口径市场比较
- [ ] 买家、供应商、港口与贸易流向检索
- [ ] 按具体 Dataset/Product ID 完成 NOAA、FAO、Copernicus、NASA 与市场数据许可审计
- [x] 首个真实源：SSB 03024 周度三文鱼出口基准
- [ ] 接入 GEBCO 2026 水深并实现强制“不用于导航”标识

### Phase 2 — Fish Radar Beta

- [ ] SST、叶绿素、洋流、水深、季节和历史捕捞栅格管道
- [ ] Fish Probability 模型版本、回测、校准和置信度
- [ ] 地图概率图层、因子解释、保护区和安全提示
- [ ] Ocean Intelligence Score 实验版
- [ ] AI 问答只引用可追溯数据，无数据时拒绝编造；服务真正可用前不放入发行导航

### Phase 3 — 账号与商业化

- [ ] 跨平台账号、组织、角色和设备同步
- [ ] StoreKit 2 与 Google Play Billing 权益映射
- [ ] Free / Pro / Enterprise 服务端权限与配额
- [ ] 订阅恢复、退款、宽限期、账单重试和收据校验
- [ ] 数据导出、API Key、Webhook 和团队审计日志

### Phase 4 — 发布

- [ ] Android developer verification 注册最终包名
- [ ] Google Play Internal → Closed → Production 测试链路
- [ ] iOS TestFlight 与 macOS TestFlight/App Store 构建
- [ ] 12 语言商店元数据、截图、隐私和 Data Safety/App Privacy
- [ ] ASC/GPD 上传前验证、分阶段发布和回滚手册

## 未来付费点需求

商业化必须建立在真实、获授权且标明时效的数据上。开发 fixture 不进入发行包、不设置付费墙，也不销售联系方式。

### Free

- 延迟价格与有限市场地图
- 公开新闻和基础品种页面
- 每日有限 AI 查询
- Fish Probability 低分辨率预览
- 少量收藏与基础提醒

### Pro — 个人采购与分析

- 实时或更高频价格、完整历史曲线和单位/货币标准化
- AI 七日行情概率、Fish Radar 高分辨率图层与因子解释
- 买家/供应商授权联系方式与验证状态
- Excel/CSV/PDF 导出
- 价格、港口、概率和贸易异动提醒
- 更高 AI 配额和个人 API 配额

建议商店产品标识：

- `aquahunter.pro.monthly`
- `aquahunter.pro.annual`

### Enterprise — 团队与系统集成

- 团队席位、角色、审批和审计日志
- 高配额 API、Webhook、批量导出与 SLA
- ERP/SAP/Oracle 接口
- 私有数据源、定制模型与区域权限
- SSO、SCIM、专属支持和合规报告

Enterprise 采用销售合同与服务端授权，不直接作为移动商店普通订阅销售。

### Marketplace 与交易收入

- RFQ、在线报价和合同工作流
- 验证供应商、出口许可与证书核验
- Escrow、支付和交易争议流程
- 交易成功费、金融/保险合作分成

在交易合规、KYC/KYB、支付牌照与数据责任未完成前不得上线。

### 船队与冷链增值

- 船队管理、AIS 历史和风险告警
- 冷链温度、集装箱位置和异常处置
- 碳排放、可持续捕捞与供应链追溯报告
- 按船舶、设备、集装箱或数据量计费

## 发布原则

- Apple：使用 Hot Season `asc`，先 TestFlight，完成验证后再提交 App Store。
- Google：使用 `gpd`，首次上传先进入 Internal testing，再推广到 Closed/Production。
- 所有上传前必须通过平台 README 中的测试和验证命令。
- 所有上传前必须通过 `python3 tools/validate_data_sources.py --release` 和 `python3 tools/validate_release_content.py`；许可不清楚、生产源为空、仍含 fixture/合成数据或阻止使用的地图依赖时禁止上传。
- 生产数据必须明确允许商业使用、改编和产品所需的再分发；公开可访问本身不构成授权。
- 无合规数据时显示不可用，不以虚构价格、K 线、买家、船舶、Radar 或 AI 结论回退。
- 当前基础地图不产生按次费用：iOS/Android 使用 BSD 2-Clause 的 MapLibre Native，macOS 使用 SwiftUI Canvas，三端均只读取随包分发的 Natural Earth 5.1.2 公共领域 GeoJSON。文件、版本、SHA-256 与条款见 [`map-assets/README.md`](map-assets/README.md) 和 [`docs/THIRD_PARTY_NOTICES.md`](docs/THIRD_PARTY_NOTICES.md)。
- 当前发行包不请求 Google Maps、Apple Maps 或公共 `tile.openstreetmap.org` 服务。未来若增加更详细地图，只能使用自托管数据或另有明确商业移动端授权的供应商。
- 离线底图仅供地理方向参考，不是海图，不可用于导航、国界/海域判断、禁捕区判断、路线规划或生命安全决策。
- 不在仓库提交 API 私钥、service-account JSON、keystore、密码或真实地图密钥。
- 不把“Fish Probability”描述为鱼探仪或确定性捕捞结果。

## 仓库结构

```text
aquahunter/
├── android/                 # Kotlin + Jetpack Compose
├── ios/                     # iOS/iPadOS SwiftUI + XcodeGen
├── macos/                   # macOS SwiftUI + XcodeGen
├── apple/Shared/            # Apple 平台共享模型、主题和页面
├── apple/Tests/             # Apple 平台共享单元测试
├── map-assets/              # 版本锁定的公共领域离线地图资产与样式
├── artifacts/               # 图标与验证截图
├── docs/PRD.md              # 完整产品需求
├── .asc/                    # ASC 工作流（不含凭据）
└── .gpd/                    # GPD 工作流（不含凭据）
```
