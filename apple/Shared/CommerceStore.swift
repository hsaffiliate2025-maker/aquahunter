import Combine
import Foundation
import StoreKit

enum CommerceLegalLinks {
    static let privacyPolicy = URL(
        string: "https://hotseason.app/en/policy#aquahunter"
    )!
    static let termsOfUse = URL(
        string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    )!
}

enum CommerceDestination: String, Codable, CaseIterable, Identifiable {
    case history
    case export
    case compare
    case snapshot
    case seasonality
    case landedCost
    case alerts

    var id: String { rawValue }
}

enum CommerceCatalogError: LocalizedError {
    case missingResource(String)
    case unknownProduct(String)
    case invalidProduct(String)

    var errorDescription: String? {
        switch self {
        case let .missingResource(name):
            "The required commerce resource \(name) is missing."
        case let .unknownProduct(productID):
            "The product \(productID) is not in the signed release catalog."
        case let .invalidProduct(productID):
            "The product \(productID) has an invalid entitlement definition."
        }
    }
}

private enum CommercePurchaseError: LocalizedError {
    case unverifiedTransaction

    var errorDescription: String? {
        "The store transaction could not be verified on this device."
    }
}

struct CommerceFeatureContract: Decodable, Equatable {
    let route: String
    let successEvidence: String
}

struct CommerceSubscriptionGrant: Decodable, Equatable {
    let historyWeeks: Int
    let watchlistSlots: Int
    let monthlyAllowances: [String: Int]
}

struct CommerceProductDefinition: Decodable, Identifiable, Equatable {
    let id: String
    let storeType: String
    let family: String
    let tier: String?
    let billingPeriod: String?
    let destination: CommerceDestination
    let quantity: Int?
    let grant: CommerceSubscriptionGrant?

    var isSubscription: Bool {
        storeType == "autoRenewableSubscription"
    }
}

struct CommerceProductText: Equatable {
    let name: String
    let description: String
}

struct CommerceLocaleText: Decodable, Equatable {
    struct StoreText: Decodable, Equatable {
        let title: String
        let plansTitle: String
        let optionsEyebrow: String
        let allowanceDisclosure: String
        let subscriptionsTitle: String
        let oneTimeTitle: String
        let unavailable: String
        let done: String
        let later: String
        let storeButton: String
        let legalDisclosure: String
        let privacyPolicy: String
        let termsOfUse: String
    }

    struct DestinationText: Decodable, Equatable {
        let history: String
        let export: String
        let compare: String
        let snapshot: String
        let seasonality: String
        let landedCost: String
        let alerts: String

        subscript(destination: CommerceDestination) -> String {
            switch destination {
            case .history: history
            case .export: export
            case .compare: compare
            case .snapshot: snapshot
            case .seasonality: seasonality
            case .landedCost: landedCost
            case .alerts: alerts
            }
        }
    }

    struct SubscriptionText: Decodable, Equatable {
        let name: String
        let description: String
    }

    struct FamilyText: Decodable, Equatable {
        let name: String
        let description: String
    }

    let thankYouTitle: String
    let thankYouMessage: String
    let openDestination: String
    let purchase: String
    let restore: String
    let restored: String
    let balance: String
    let pending: String
    let failed: String
    let noCharge: String
    let toolkit: [String: String]
    let store: StoreText
    let destinations: DestinationText
    let periods: [String: String]
    let subscriptions: [String: SubscriptionText]
    let families: [String: FamilyText]

    func replacing(_ template: String, values: [String: String]) -> String {
        values.reduce(template) { output, item in
            output.replacingOccurrences(
                of: "{\(item.key)}",
                with: item.value
            )
        }
    }

    func tool(_ key: String, fallback: String) -> String {
        toolkit[key] ?? fallback
    }
}

struct CommerceCatalog {
    private struct CatalogPayload: Decodable {
        let catalogVersion: String
        let supportedLocales: [String]
        let paidSourceIds: [String]
        let featureContracts: [String: CommerceFeatureContract]
        let products: [CommerceProductDefinition]
    }

    private struct LocalizationPayload: Decodable {
        let catalogVersion: String
        let locales: [String: CommerceLocaleText]
    }

    let catalogVersion: String
    let supportedLocales: [String]
    let paidSourceIds: [String]
    let featureContracts: [CommerceDestination: CommerceFeatureContract]
    let products: [CommerceProductDefinition]
    let localizations: [String: CommerceLocaleText]

    static func load(bundle: Bundle = .main) throws -> CommerceCatalog {
        let catalogURL = try resourceURL(
            name: "product-catalog",
            extension: "json",
            bundle: bundle
        )
        let localizationURL = try resourceURL(
            name: "localizations",
            extension: "json",
            bundle: bundle
        )
        return try decode(
            catalogData: Data(contentsOf: catalogURL),
            localizationData: Data(contentsOf: localizationURL)
        )
    }

    static func decode(
        catalogData: Data,
        localizationData: Data
    ) throws -> CommerceCatalog {
        let decoder = JSONDecoder()
        let payload = try decoder.decode(CatalogPayload.self, from: catalogData)
        let localizationPayload = try decoder.decode(
            LocalizationPayload.self,
            from: localizationData
        )
        guard payload.catalogVersion == localizationPayload.catalogVersion else {
            throw CommerceCatalogError.missingResource(
                "matching catalog/localization version"
            )
        }
        let contracts = Dictionary(
            uniqueKeysWithValues: payload.featureContracts.compactMap {
                key, value in
                CommerceDestination(rawValue: key).map { ($0, value) }
            }
        )
        return CommerceCatalog(
            catalogVersion: payload.catalogVersion,
            supportedLocales: payload.supportedLocales,
            paidSourceIds: payload.paidSourceIds,
            featureContracts: contracts,
            products: payload.products,
            localizations: localizationPayload.locales
        )
    }

    func definition(for productID: String) -> CommerceProductDefinition? {
        products.first { $0.id == productID }
    }

    func locale(for languageCode: String) -> CommerceLocaleText {
        localizations[languageCode]
            ?? localizations[String(languageCode.prefix(2))]
            ?? localizations["en"]!
    }

    func text(
        for product: CommerceProductDefinition,
        languageCode: String
    ) throws -> CommerceProductText {
        let locale = locale(for: languageCode)
        if product.isSubscription {
            guard
                let tier = product.tier,
                let period = product.billingPeriod,
                let block = locale.subscriptions[tier],
                let periodText = locale.periods[period]
            else {
                throw CommerceCatalogError.invalidProduct(product.id)
            }
            return CommerceProductText(
                name: "\(block.name) — \(periodText)",
                description: block.description
            )
        }
        guard
            let quantity = product.quantity,
            let block = locale.families[product.family]
        else {
            throw CommerceCatalogError.invalidProduct(product.id)
        }
        let values = ["quantity": String(quantity)]
        return CommerceProductText(
            name: locale.replacing(block.name, values: values),
            description: locale.replacing(block.description, values: values)
        )
    }

    private static func resourceURL(
        name: String,
        extension fileExtension: String,
        bundle: Bundle
    ) throws -> URL {
        if let url = bundle.url(forResource: name, withExtension: fileExtension) {
            return url
        }
        if let url = bundle.url(
            forResource: name,
            withExtension: fileExtension,
            subdirectory: "commerce"
        ) {
            return url
        }
        throw CommerceCatalogError.missingResource("\(name).\(fileExtension)")
    }
}

struct CommerceLedgerState: Codable, Equatable {
    var purchasedBalances: [String: Int] = [:]
    var processedTransactionIDs: Set<String> = []
    var activeSubscriptionProductIDs: Set<String> = []
    var monthlyUsage: [String: [String: Int]] = [:]

    mutating func grant(
        transactionID: String,
        product: CommerceProductDefinition
    ) throws -> Bool {
        guard !processedTransactionIDs.contains(transactionID) else {
            return false
        }
        processedTransactionIDs.insert(transactionID)
        if product.isSubscription {
            activeSubscriptionProductIDs.insert(product.id)
            return true
        }
        guard let quantity = product.quantity, quantity > 0 else {
            throw CommerceCatalogError.invalidProduct(product.id)
        }
        purchasedBalances[product.destination.rawValue, default: 0] += quantity
        return true
    }

    mutating func replaceActiveSubscriptions(with productIDs: Set<String>) {
        activeSubscriptionProductIDs = productIDs
    }

    func historyWeeks(catalog: CommerceCatalog) -> Int {
        activeSubscriptions(catalog: catalog)
            .compactMap { $0.grant?.historyWeeks }
            .max() ?? 52
    }

    func available(
        destination: CommerceDestination,
        catalog: CommerceCatalog,
        now: Date = Date()
    ) -> Int {
        let purchased = purchasedBalances[destination.rawValue, default: 0]
        let included = activeSubscriptions(catalog: catalog)
            .compactMap { $0.grant?.monthlyAllowances[destination.rawValue] }
            .max() ?? 0
        let used = monthlyUsage[Self.monthKey(now), default: [:]][
            destination.rawValue,
            default: 0
        ]
        return purchased + max(included - used, 0)
    }

    mutating func consumeSuccessfulResult(
        destination: CommerceDestination,
        catalog: CommerceCatalog,
        now: Date = Date()
    ) -> Bool {
        let key = destination.rawValue
        if purchasedBalances[key, default: 0] > 0 {
            purchasedBalances[key, default: 0] -= 1
            return true
        }
        let allowance = activeSubscriptions(catalog: catalog)
            .compactMap { $0.grant?.monthlyAllowances[key] }
            .max() ?? 0
        let period = Self.monthKey(now)
        let used = monthlyUsage[period, default: [:]][key, default: 0]
        guard used < allowance else { return false }
        monthlyUsage[period, default: [:]][key, default: 0] += 1
        return true
    }

    private func activeSubscriptions(
        catalog: CommerceCatalog
    ) -> [CommerceProductDefinition] {
        catalog.products.filter {
            $0.isSubscription
                && activeSubscriptionProductIDs.contains($0.id)
        }
    }

    private static func monthKey(_ date: Date) -> String {
        let components = Calendar(identifier: .gregorian)
            .dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)
        return String(format: "%04d-%02d", components.year!, components.month!)
    }
}

struct CommerceThankYou: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let actionTitle: String
    let destination: CommerceDestination
}

@MainActor
final class CommerceStore: ObservableObject {
    @Published private(set) var catalog: CommerceCatalog?
    @Published private(set) var storeProducts: [String: Product] = [:]
    @Published private(set) var ledger = CommerceLedgerState()
    @Published private(set) var isLoading = false
    @Published var statusMessage: String?
    @Published var thankYou: CommerceThankYou?

    private static let ledgerKey = "aquahunter.commerce.ledger.v1"
    private let defaults: UserDefaults
    private var updatesTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard, bundle: Bundle = .main) {
        self.defaults = defaults
        if
            let data = defaults.data(forKey: Self.ledgerKey),
            let restored = try? JSONDecoder().decode(
                CommerceLedgerState.self,
                from: data
            )
        {
            ledger = restored
        }
        do {
            catalog = try CommerceCatalog.load(bundle: bundle)
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func start() async {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                await self.process(update)
            }
        }
        await reloadProducts()
        await refreshSubscriptions()
    }

    func reloadProducts() async {
        guard let catalog else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let products = try await Product.products(
                for: catalog.products.map(\.id)
            )
            storeProducts = Dictionary(
                uniqueKeysWithValues: products.map { ($0.id, $0) }
            )
            let missing = Set(catalog.products.map(\.id))
                .subtracting(Set(storeProducts.keys))
            if missing.isEmpty {
                statusMessage = nil
            } else {
                statusMessage =
                    "Some store products are not available in this storefront."
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func purchase(
        productID: String,
        languageCode: String
    ) async {
        guard
            let catalog,
            let definition = catalog.definition(for: productID),
            let storeProduct = storeProducts[productID]
        else {
            statusMessage = CommerceCatalogError
                .unknownProduct(productID).localizedDescription
            return
        }
        do {
            switch try await storeProduct.purchase() {
            case let .success(result):
                let transaction = try verified(result)
                try grant(transaction: transaction, definition: definition)
                await transaction.finish()
                await refreshSubscriptions()
                let locale = catalog.locale(for: languageCode)
                let productText = try catalog.text(
                    for: definition,
                    languageCode: languageCode
                )
                let destination = locale.destinations[definition.destination]
                thankYou = CommerceThankYou(
                    title: locale.thankYouTitle,
                    message: locale.replacing(
                        locale.thankYouMessage,
                        values: ["product": productText.name]
                    ),
                    actionTitle: locale.replacing(
                        locale.openDestination,
                        values: ["destination": destination]
                    ),
                    destination: definition.destination
                )
                statusMessage = nil
            case .pending:
                statusMessage = catalog.locale(for: languageCode).pending
            case .userCancelled:
                statusMessage = nil
            @unknown default:
                statusMessage = catalog.locale(for: languageCode).failed
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func restore(languageCode: String) async {
        guard let catalog else { return }
        do {
            try await AppStore.sync()
            await refreshSubscriptions()
            statusMessage = catalog.locale(for: languageCode).restored
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func available(_ destination: CommerceDestination) -> Int {
        guard let catalog else { return 0 }
        return ledger.available(destination: destination, catalog: catalog)
    }

    func historyWeeks() -> Int {
        guard let catalog else { return 52 }
        return ledger.historyWeeks(catalog: catalog)
    }

    @discardableResult
    func consumeSuccessfulResult(_ destination: CommerceDestination) -> Bool {
        guard let catalog else { return false }
        let consumed = ledger.consumeSuccessfulResult(
            destination: destination,
            catalog: catalog
        )
        if consumed {
            persist()
        }
        return consumed
    }

    private func refreshSubscriptions() async {
        guard let catalog else { return }
        let subscriptionIDs = Set(
            catalog.products.filter(\.isSubscription).map(\.id)
        )
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }
            guard
                subscriptionIDs.contains(transaction.productID),
                transaction.revocationDate == nil,
                transaction.expirationDate.map({ $0 > Date() }) ?? true
            else { continue }
            active.insert(transaction.productID)
        }
        ledger.replaceActiveSubscriptions(with: active)
        persist()
    }

    private func process(_ result: VerificationResult<Transaction>) async {
        guard
            let catalog,
            case let .verified(transaction) = result,
            let definition = catalog.definition(for: transaction.productID)
        else { return }
        do {
            try grant(transaction: transaction, definition: definition)
            await transaction.finish()
            if definition.isSubscription {
                await refreshSubscriptions()
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func verified<T>(
        _ result: VerificationResult<T>
    ) throws -> T {
        switch result {
        case let .verified(value): value
        case .unverified:
            throw CommercePurchaseError.unverifiedTransaction
        }
    }

    private func grant(
        transaction: Transaction,
        definition: CommerceProductDefinition
    ) throws {
        _ = try ledger.grant(
            transactionID: String(transaction.id),
            product: definition
        )
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(ledger) else { return }
        defaults.set(data, forKey: Self.ledgerKey)
    }
}
