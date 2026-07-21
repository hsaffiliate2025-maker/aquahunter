# AquaHunter

> Global Seafood Intelligence Platform  
> Bloomberg for the Global Seafood Industry.

AquaHunter 是面向全球海鲜产业的跨平台数据产品，聚合价格、买家、港口、贸易、船舶和海洋环境信号，并以可解释的 Fish Probability 与 AI 分析辅助采购和作业判断。

本 README 描述**产品需求**与**付费点计划**。构建、签名、上架流程、产物哈希与商店素材等平台细节以各端 README 为准：[`android/README.md`](android/README.md) · [`ios/README.md`](ios/README.md) · [`macos/README.md`](macos/README.md)。完整需求文档为 [`docs/PRD.md`](docs/PRD.md)。

## 产品需求（摘要）

**目标用户**：远洋/近海捕捞经营者、水产采购与贸易商、加工厂与进出口商、行业研究者。

**核心模块**：

- **Pulse**：已授权数据源的最新观测与趋势摘要。
- **Markets**：真实市场/出口价格基准、6W/30W/1Y 历史曲线、原始币种与统计口径、来源与许可展示。
- **Radar**：鱼群概率（环境适宜度）。只有当海温、叶绿素、洋流、水深、季节与历史渔获全部来自已批准商用的数据集时才输出概率；否则显示"暂无估计"，不生成合成数值。
- **Network**：买家、贸易流、港口与船舶。无合规数据的子模块隐藏或显示不可用。
- **Ask / Aqua AI**（后续）：带引用链的 AI 分析，按 Research Credit 计费；服务端 AI、成本与隐私门禁完成前不进入导航。

**硬性产品原则**：

1. 首次启动必须确认《海上作业与法律风险声明》（版本 `2026-07-21`），声明明确：所有展示数据来自公开/已授权来源；禁止在未开放或无批文的水域捕捞作业；市场价格波动概不负责。
2. 任何指标必须显示来源、观测/发布时间与许可；不虚构回退、不把统计值标成实时报价。
3. 数据源以 [`docs/DATA_SOURCE_POLICY.md`](docs/DATA_SOURCE_POLICY.md) 与 [`docs/data-sources.json`](docs/data-sources.json) 为发布硬门槛，上传前 `python3 tools/validate_data_sources.py --release` 必须通过。
4. 无账号、无广告、无分析 SDK、无敏感权限（当前发行版）。

**数据源现状（2026-07-21 复审）**：

- 生产启用：Statistics Norway Statbank 03024（CC BY 4.0）、Natural Earth 5.1.2 离线底图（公共领域）。
- 已核准待接入：東京都中央卸売市場日報（CC BY 4.0，真实水产日度批发价格）、NASA OB.PG 海温/海色（CC0）、NOAA OISST 与公开渔获汇总（CC0）、GEBCO 与 EMODnet 水深（CC BY/署名）、Protomaps OSM 离线矢量底图（ODbL Produced Work）。
- 明确不展示：FAO（附加条款限制商业促销用途）、Global Fishing Watch（API 禁商用）、ImportYeti / Volza（条款禁止二次商用）；AIS 船位需商业合同后再评估。

## 身份与发布渠道

三端统一标识 `com.hotseason.aquahunter`；商店显示名为 **AquaHunter: Seafood Intel**（App Store 上 `AquaHunter` 一名已被占用）。Apple 侧为 Hot Season Enterprise, Inc.（`C8Y5J74PQW`），经 `asc`（App Store Connect API）上架 App Store / Mac App Store；Android 经 Google Play Developer API 上架 Google Play。2026-07-21：三端均已提交商店审核。签名产物、哈希、商店素材与发布阻断项见各端 README；每次修改发布代码或版本号后必须重新构建并复核哈希，不得把旧产物上传为新版本。

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
- [x] 2026-07-21 完成 NOAA、NASA、Copernicus、FAO、GFW、ImportYeti/Volza、东京都及多国官方源许可核查并写入登记表
- [ ] 按具体 Dataset/Product ID 完成已核准源（东京都、NASA、NOAA、EUMOFA、e-Stat 等）的适配器接入
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

- [x] Android developer verification 注册最终包名 `com.hotseason.aquahunter`（2026-07-21）
- [x] 三端本地签名发布产物、签名与内容核验
- [x] 2026-07-21 Google Play internal 轨道发布 versionCode 1，并提交 production 审核
- [x] 2026-07-21 iOS 与 macOS 1.0.0 (1) 上传 App Store Connect 并提交 App Review
- [x] 首版英文 iPhone、iPad、macOS 和 Google Play 正式截图与图形素材
- [ ] 12 语言商店元数据、完整界面本地化、隐私和 Data Safety/App Privacy
- [ ] ASC/GPD 上传前验证、分阶段发布和回滚手册

## 付费点计划

模式：**Freemium 订阅 + Research Credits 消耗**。商业化必须建立在真实、获授权且标明时效的数据上。开发 fixture 不进入发行包、不设置付费墙，也不销售联系方式。所有权限与扣费在服务端执行；付费不能解锁任何绕过数据许可、保护区、禁捕期或航行安全的能力。

| 层级 | 定价形态 | 首批内容 |
|---|---|---|
| Visitor / Free | 免费 | 最新价格基准、离线底图、有限搜索；AI 上线后含少量周期赠送 credits |
| **Pro**（首个付费点） | 月/年订阅（`aquahunter.pro.monthly` / `aquahunter.pro.annual`） | 完整历史价格、AI 预测与高分辨率 Fish Radar、授权联系方式、导出、提醒、周期 Research Credits |
| **Enterprise** | 年度销售合同 | 团队席位、高配额 API、Webhook、SLA、审计、ERP 集成 |
| Research Credits | 消耗型内购（`aquahunter.research.20/80/240` 预留） | AI 分析按任务扣费，后端定权威价；单独购买余额不过期 |

**上线节奏**：v1.0 免费上架无 IAP（以真实数据建立信任与下载量）→ v1.x 接入东京都日报与 NASA/NOAA 环境层后引入 Pro 订阅（历史与导出为首批付费墙）→ v2 Radar 概率与 Aqua AI 上线后引入 Research Credits，随后开放 Enterprise。

### 竞品参考与 40 个付费权益 / IAP 候选

竞品官方付费能力显示，用户愿意为“更深的历史、可比价格、预警、获授权的贸易/船舶数据、工作流和可交付研究结果”付费，而不是为装饰付费：Undercurrent/UCN 提供海鲜价格历史、最多 12 个产品比较、市场简报、CSV 与 API；Tridge 提供价格基准、供应商核验、贸易信号、RFQ 与采购研究；Volza 提供进出口、买家/供应商与联系人筛选；MarineTraffic/VesselFinder 提供舰队、历史航迹、港口事件、ETA、提醒与卫星 AIS；PredictWind 提供高分辨率海洋/天气层；Fishbrain 提供深度图、法规信息与私有点位。参考仅用于产品模式研究，不代表可复制或转售这些竞品的数据。

官方参考：[UCN Prices](https://www.undercurrentnews.com/prices-landing/) · [Tridge Procurement](https://www.tridge.com/solutions/procurement) · [Volza Pricing](https://www.volza.com/pricing/) · [MarineTraffic plans](https://support.marinetraffic.com/en/articles/9552658-marinetraffic-online-plans) / [add-on 合并说明](https://support.marinetraffic.com/en/articles/10442248-22-january-2025-we-re-removing-add-ons-and-credits-from-marinetraffic) · [VesselFinder plans](https://www.vesselfinder.com/get-premium) · [PredictWind subscriptions](https://help.predictwind.com/en/articles/8563285-predictwind-subscriptions-differences-between-standard-and-professional) · [Fishbrain Pro](https://fishbrain.com/pro/upgrade)

下面正好列出 **40 个可收费业务权益候选**。它们是服务端 entitlement，不要求一次性在商店创建 40 个独立 Product ID；推荐按订阅、配额包和 Research Credits 组合成 8–12 个清晰商品分批上线，减少重复 SKU、订阅升级和退款复杂度。任何候选只有在数据商业授权、覆盖率、成本和商店审核门禁通过后才能启用。

| # | 权益代码 | 可收费业务结果 | 建议计费形态 |
|---:|---|---|---|
| 1 | `MKT-01` | 5 年完整价格历史与 K 线 | Markets Pro 订阅 |
| 2 | `MKT-02` | 同品种、同规格的多城市/市场比较 | Markets Pro 订阅 |
| 3 | `MKT-03` | 规格、等级、形态和产地价格矩阵 | Markets Pro 订阅 |
| 4 | `MKT-04` | 原币种、汇率、重量单位和标准化价并列 | Markets Pro 订阅 |
| 5 | `MKT-05` | 市场间可比价差与采购机会观察 | Markets Pro 订阅 |
| 6 | `MKT-06` | 自定义价格阈值提醒 | Alerts 配额/Pro |
| 7 | `MKT-07` | 波动、跳价和数据异常提醒 | Alerts 配额/Pro |
| 8 | `MKT-08` | 供应量、需求与同比/环比面板 | Markets Pro 订阅 |
| 9 | `MKT-09` | 到岸成本、关税、冷链和目标毛利计算 | 计算器 Pro/报告 |
| 10 | `MKT-10` | 每周 Market Pulse 与涨跌驱动 Wrap-Up | Markets Pro/Research Credits |
| 11 | `TRD-01` | 买家高级搜索与保存筛选 | Trade Pro 订阅 |
| 12 | `TRD-02` | 供应商高级搜索与保存筛选 | Trade Pro 订阅 |
| 13 | `TRD-03` | 买家进口历史、频次、数量与来源国 | Trade Pro 订阅 |
| 14 | `TRD-04` | 供应商出口历史、频次、数量与目的国 | Trade Pro 订阅 |
| 15 | `TRD-05` | 按 HS Code、品种、国家和港口的贸易流 | Trade Pro 订阅 |
| 16 | `TRD-06` | 最近活跃买家与采购意图信号 | Trade Pro/Alerts |
| 17 | `TRD-07` | 买家/供应商主体核验报告 | 单份报告/Research Credits |
| 18 | `TRD-08` | 出口许可、证书与有效期核验报告 | 单份报告/Research Credits |
| 19 | `TRD-09` | 指定产品与目的国的采购/销售对象 shortlist | Research Credits |
| 20 | `TRD-10` | RFQ 报价横评、风险项和谈判准备包 | Research Credits |
| 21 | `OCN-01` | SST、叶绿素、洋流、浪高等 Ocean Layers Pro | Ocean Pro 订阅 |
| 22 | `OCN-02` | 更高空间/时间分辨率 Fish Radar | Ocean Pro 订阅 |
| 23 | `OCN-03` | 多鱼种 Radar 与鱼种切换 | Ocean Pro 订阅 |
| 24 | `OCN-04` | 私有海域、作业区域和点位保存/同步 | Ocean Pro 订阅 |
| 25 | `OCN-05` | 官方禁捕期、保护区和法规变更提醒 | Alerts/Ocean Pro |
| 26 | `VES-01` | 扩展舰队监控列表与分组 | Fleet Pro 订阅 |
| 27 | `VES-02` | 单船卫星 AIS 跟踪通行证 | 按船/月消耗或订阅 |
| 28 | `VES-03` | 90 天历史航迹与事件回放 | Fleet Pro/单船通行证 |
| 29 | `PRT-01` | 港口停靠、预计到港、ETA 与泊位事件 | Ports Pro 订阅 |
| 30 | `PRT-02` | 船舶地理围栏、港口拥堵与事件提醒 | Alerts/Ports Pro |
| 31 | `AI-01` | 单市场价格趋势解释 | 1 Research Credit |
| 32 | `AI-02` | Fish Radar 环境因子解释 | 2 Research Credits |
| 33 | `AI-03` | 买家研究简报 | 3 Research Credits |
| 34 | `AI-04` | 供应商研究简报 | 3 Research Credits |
| 35 | `AI-05` | 多市场采购研究简报 | 5 Research Credits |
| 36 | `AI-06` | 报价/谈判准备简报 | 5 Research Credits |
| 37 | `DAT-01` | CSV、Excel、PDF 导出配额包 | 消耗型配额/Pro |
| 38 | `DAT-02` | REST API 调用配额包 | 月度订阅/配额包 |
| 39 | `DAT-03` | Webhook 与自动监控事件配额包 | 月度订阅/配额包 |
| 40 | `WRK-01` | 团队共享 watchlist、注释、审批与审计 | Team 订阅 |

**明确不收费**：背景色/主题、语言、无障碍、免责声明与法规安全提示、隐私设置、账号删除、购买恢复、数据来源与更新时间。核心安全或合规能力不能被付费墙挡住。

**授权与可靠性门禁**：买家联系方式、贸易记录、AIS、港口、法规或海洋层必须拥有适用于商业移动产品的合同或开放许可；公开可见不等于可转售。Global Fishing Watch 公共 API 明确仅限非商业用途，不能作为上述收费权益的数据后端，除非另签商业许可。按次报告、导出或 AI 任务在无数据、数据过期、授权失效、失败、安全拒绝或幂等重放时不扣次数/credits；订阅页必须披露覆盖范围和典型新鲜度。

**推荐首发顺序**：先上线 `MKT-01`–`MKT-10` 与 `DAT-01`，因为它们最贴近当前真实价格数据能力；完成获授权贸易数据后上线 `TRD-*`；完成商业 AIS/港口合同与海洋产品级许可后上线 `OCN-*`、`VES-*`、`PRT-*`；生产 AI 后端与 Research Credit 账本全部通过门禁后才上线 `AI-*`。

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
