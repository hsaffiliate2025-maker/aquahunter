# AquaHunter

> Global Seafood Intelligence Platform  
> Bloomberg for the Global Seafood Industry.

AquaHunter 是面向全球海鲜产业的跨平台数据产品，聚合价格、买家、港口、贸易、船舶和海洋环境信号，并以可解释的 Fish Probability 与 AI 分析辅助采购和作业判断。

当前仓库是 Android、iOS、macOS 三端 monorepo。三端生产界面已接入 Statistics Norway（SSB）Statbank 表 03024 的真实周度三文鱼出口数据，以及 Natural Earth 5.1.2 公共领域离线世界底图；其他业务图层在没有合规数据时显示不可用，不使用虚构回退。任何新增来源都必须真实、可追溯，并且许可证或合同明确允许 AquaHunter 所需的商业使用、转换与展示。

## 平台入口

| 平台 | 工程 | 平台文档 | 当前状态 |
|---|---|---|---|
| Android | [`android/`](android/) | [`android/README.md`](android/README.md) | 已生成签名 AAB/APK；等待 Play 应用记录与服务账号授权 |
| iOS / iPadOS | [`ios/`](ios/) | [`ios/README.md`](ios/README.md) | 已生成 App Store 签名 IPA；等待 App Store Connect 应用记录 |
| macOS | [`macos/`](macos/) | [`macos/README.md`](macos/README.md) | 已生成 Mac App Store 签名 PKG；等待 App Store Connect 应用记录 |

共享 Apple 数据模型、视觉系统和主要页面位于 [`apple/Shared/`](apple/Shared/)。完整产品需求保存在 [`docs/PRD.md`](docs/PRD.md)。数据许可政策与机器可检查的白名单分别位于 [`docs/DATA_SOURCE_POLICY.md`](docs/DATA_SOURCE_POLICY.md) 和 [`docs/data-sources.json`](docs/data-sources.json)。最终商业图标母版位于 [`artifacts/icon/aquahunter-app-icon-final.png`](artifacts/icon/aquahunter-app-icon-final.png)，经过筛选的正式商店截图和 Google Play 图形素材位于 [`store/`](store/)。

## 身份与发布渠道

| 项目 | 值 |
|---|---|
| 产品名 | `AquaHunter` |
| Android applicationId | `com.hsaffiliate.aquahunter` |
| Apple Universal Bundle ID | `com.hsaffiliate.aquahunter` |
| Apple Team | Hot Season Enterprise, Inc. (`C8Y5J74PQW`) |
| Apple 上传工具 | `asc`（Hot Season App Store Connect API） |
| Google 上传工具 | `gpd`（Google Play Developer API） |

Apple Universal App ID 已注册。三端签名发布产物已经生成并完成签名、内容与地图资产核验；App Store Connect 尚无 AquaHunter 应用记录，Google Play Developer API 服务账号当前也无权访问该 package。创建商店记录、授权并上传时必须继续使用完全相同的标识。

## 当前发布产物

| 平台 | 版本 | 产物 | SHA-256 |
|---|---|---|---|
| iOS / iPadOS | `1.0.0 (1)` | `.asc/artifacts/AquaHunterIOS.ipa` | `6ccc5b90fe64638ff6a455370ba05f6bcfe302f8249e4cfba2d30ea77e1f6325` |
| macOS | `1.0.0 (1)` | `.asc/artifacts/AquaHunterMacExportSigned/AquaHunterMac.pkg` | `5ebfaa7ac0260cb29a05c9b96470841b6a5d8ba7c7fb1841c0b0a9ae07799e60` |
| Android | `0.1.0 (1)` | `android/app/build/outputs/bundle/release/app-release.aab` | `9169fec91b01321df2eb8ca57e8b3ede98633aa508eab493492ec42a466c172f` |

上述二进制产物由本地发布流程生成并被 `.gitignore` 排除，不提交 GitHub。每次修改发布代码或版本号后都必须重新生成并更新哈希，不得把旧产物上传为新版本。

## 当前商店素材

| 渠道 | 目录 | 当前结果 |
|---|---|---|
| iPhone 6.5-inch | [`store/app-store/iphone-65/`](store/app-store/iphone-65/) | 3 张 1284×2778；ASC 本地校验通过 |
| iPad Pro 12.9-inch | [`store/app-store/ipad-pro-129/`](store/app-store/ipad-pro-129/) | 3 张 2048×2732；ASC 本地校验通过 |
| macOS | [`store/app-store/macos/`](store/app-store/macos/) | 3 张 2560×1600 |
| Google Play | [`store/google-play/`](store/google-play/) | 3 张 Pixel 6 截图、512×512 图标和 1024×500 feature graphic |

商店截图只展示真实 SSB 周度观测、历史曲线、来源许可和离线地图。`artifacts/screenshots/` 保留开发过程截图并被 Git 忽略，其中可能存在旧版 demo 界面，禁止直接上传。完整说明见 [`store/README.md`](store/README.md)。

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
- [ ] Research Credits / AI Analysis Credits 服务端钱包、预留、扣费、释放与幂等状态机
- [ ] Apple/Google/Web 支付验真、不可变交易账本、退款/撤销/恢复和跨设备余额恢复
- [ ] AI 模型白名单、单任务预算、全局日预算、速率限制、成本监控与紧急熔断
- [ ] Free / Pro / Enterprise 服务端权限与配额
- [ ] 订阅恢复、退款、宽限期、账单重试和收据校验
- [ ] 数据导出、API Key、Webhook 和团队审计日志

### Phase 4 — 发布

- [ ] Android developer verification 注册最终包名
- [x] 三端本地签名发布产物、签名与内容核验
- [ ] Google Play Internal → Closed → Production 测试链路
- [ ] iOS TestFlight 与 macOS TestFlight/App Store 上传
- [x] 首版英文 iPhone、iPad、macOS 和 Google Play 正式截图与图形素材
- [ ] 12 语言商店元数据、完整界面本地化、隐私和 Data Safety/App Privacy
- [ ] ASC/GPD 上传前验证、分阶段发布和回滚手册

## 未来付费点需求

商业化必须建立在真实、获授权且标明时效的数据上。开发 fixture 不进入发行包、不设置付费墙，也不销售联系方式。

### Future paid AI module — Research Credits

后续 AI 收费单位定名为 **Research Credit（AI Analysis Credit）**。用户购买的是一个明确、可验证的业务分析结果，而不是模型 token、字数或“无限 AI”。当前发行版没有可用 AI 服务和购买入口；生产后端、支付验真与以下门禁全部完成前，不把 Aqua AI 放回导航，也不显示可工作的购买按钮。

计划中的服务端权威任务定价：

| 业务结果 | 计划扣费 | 成功结果最低要求 |
|---|---:|---|
| 单一市场价格趋势解释 | 1 credit | 指定品种、市场和时间窗；引用有效价格记录、单位、新鲜度与置信度 |
| AI Fish Radar 因子解释 | 2 credits | 基于已发布的概率结果解释 SST、叶绿素、洋流等因子；包含时间窗、模型版本与置信度 |
| 买家或供应商研究摘要 | 3 credits | 使用经过许可的企业记录，返回可点击引用、覆盖范围、更新时间和缺失项 |
| 多市场采购研究简报 | 5 credits | 完成可比性检查、货币/单位说明、来源引用、风险与不确定性摘要 |

客户端提交的 credits 数量不可信；后端按任务类型映射权威价格。昂贵任务可以调整 credits，但必须在确认前明确显示，已开始的请求不得临时涨价。

扣费规则：

- 只在结果通过来源、结构、时效、置信度、安全与产品有效性检查后提交扣费。
- 无数据、数据过期、置信度低于任务门槛、安全拒绝、上游失败、超时、模型输出无效、用户收到免费本地回退时不扣费。
- 每次请求携带幂等键；相同账号与幂等键的重放返回原结果或状态，不重复扣费。
- 后端先原子预留 credits，成功后提交；失败时释放。超时预留由对账任务安全释放。
- 不提供“无限 AI”。每个 credit 包或订阅都必须有明确额度、任务级 credits、输入/输出上限、并发限制和公平使用速率。

安全与支付架构：

- OpenAI、Claude 或其他 AI provider key 只存在于 AquaHunter 后端 Secret Manager/服务器环境；不得进入 IPA、PKG、AAB、网页包、仓库、README、日志、截图或客户端分析事件。
- 客户端只调用 AquaHunter HTTPS 后端。后端负责账号认证、余额检查、幂等预留、模型调用、结果验证和账本提交。
- Apple 平台数字内容使用 StoreKit 2，Android 使用 Google Play Billing；Web 购买使用合规 Web 支付。所有交易都由后端验真，客户端成功回调不能增加余额。
- 服务端保存持久化认证账本：`accounts`、`wallets`、`ledger_entries`、`store_transactions`、`ai_requests`、`allowance_periods`。同一商店交易只能入账一次。
- 已购买的 consumable credits 不过期。订阅或赠送额度可以按明确披露的周期重置，但不能抹除单独购买的余额。
- 退款、撤销、pending、重复交易、恢复购买、重装与跨设备恢复必须通过认证账号和账本处理；余额以服务端为准。

盈利和发布门禁：

```text
cost_per_success =
  provider_input_cost
  + provider_output_cost
  + moderation_cost
  + retry_allowance
  + data_query_and_licensing_cost
  + hosting_and_storage

contribution_margin =
  store_or_web_net_revenue
  - tax_and_refund_reserve
  - credits_in_offer * cost_per_success
```

credit 包数量、免费额度和真实售价保持 `TBD`，必须先用生产候选模型、真实数据查询量、重试率、支付渠道费率、退款率和重度用户场景测算。候选产品 ID 可预留为 `aquahunter.research.20`、`aquahunter.research.80`、`aquahunter.research.240`；正式创建前仍需核对单位经济和商店规则。

每个成功结果必须显示来源、数据观测/发布时间、检索时间、新鲜度状态、置信度、模型/规则版本和所扣 credits。不得因付费而绕过数据许可、最小置信度、保护区、禁捕期、跨境法规、航行安全或隐私门禁。AI Fish Radar 与价格趋势分析均不保证鱼群存在、捕捞成功、合法进入海域、航程安全、成交价格或投资收益。

上线前还必须完成：生产后端监控、provider key 泄漏扫描、重复购买/重复生成测试、退款/撤销/恢复测试、失败不扣费测试、隐私政策和处理方披露、任务级与全局预算、紧急熔断，以及客服可查询非敏感交易引用但无法读取 provider secret 或不必要的原始研究输入。

### Free

- 延迟价格与有限市场地图
- 公开新闻和基础品种页面
- 付费 AI 模块上线后，可提供明确数量和重置规则的赠送 Research Credits
- Fish Probability 低分辨率预览
- 少量收藏与基础提醒

### Pro — 个人采购与分析

- 实时或更高频价格、完整历史曲线和单位/货币标准化
- AI 七日行情概率、Fish Radar 高分辨率图层与因子解释
- 买家/供应商授权联系方式与验证状态
- Excel/CSV/PDF 导出
- 价格、港口、概率和贸易异动提醒
- 明确数量的周期性 Research Credits 和个人 API 配额；不提供无限 AI

建议商店产品标识：

- `aquahunter.pro.monthly`
- `aquahunter.pro.annual`

Pro 周期额度与单独购买的 consumable Research Credits 必须分账，明确优先消耗顺序；取消或到期不得删除尚未使用的已购 credits。

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
├── store/                   # 经过筛选、可上传的商店截图与图形素材
├── metadata/                # ASC canonical App Store metadata
├── docs/PRD.md              # 完整产品需求
├── .asc/                    # ASC 工作流（不含凭据）
└── .gpd/                    # GPD 工作流（不含凭据）
```
