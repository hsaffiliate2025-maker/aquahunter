import XCTest

#if os(iOS)
@testable import AquaHunterIOS
#elseif os(macOS)
@testable import AquaHunterMac
#endif

final class CommerceLedgerTests: XCTestCase {
    func testCatalogContainsTwentyFourProductsAndTwelveLocales() throws {
        let catalog = try loadCatalog()
        XCTAssertEqual(catalog.products.count, 24)
        XCTAssertEqual(catalog.supportedLocales.count, 12)
        XCTAssertEqual(catalog.paidSourceIds, ["ssb-statbank-03024"])
    }

    func testConsumableGrantIsIdempotent() throws {
        let catalog = try loadCatalog()
        let product = try XCTUnwrap(
            catalog.definition(for: "aquahunter.snapshot.5")
        )
        var ledger = CommerceLedgerState()

        XCTAssertTrue(
            try ledger.grant(transactionID: "transaction-1", product: product)
        )
        XCTAssertFalse(
            try ledger.grant(transactionID: "transaction-1", product: product)
        )
        XCTAssertEqual(
            ledger.available(destination: .snapshot, catalog: catalog),
            5
        )
    }

    func testCreditIsOnlyConsumedAfterExplicitSuccess() throws {
        let catalog = try loadCatalog()
        let product = try XCTUnwrap(
            catalog.definition(for: "aquahunter.compare.5")
        )
        var ledger = CommerceLedgerState()
        _ = try ledger.grant(transactionID: "transaction-2", product: product)

        XCTAssertEqual(
            ledger.available(destination: .compare, catalog: catalog),
            5
        )
        XCTAssertTrue(
            ledger.consumeSuccessfulResult(
                destination: .compare,
                catalog: catalog
            )
        )
        XCTAssertEqual(
            ledger.available(destination: .compare, catalog: catalog),
            4
        )
    }

    func testSubscriptionMonthlyAllowanceIsFinite() throws {
        let catalog = try loadCatalog()
        let product = try XCTUnwrap(
            catalog.definition(for: "aquahunter.markets.plus.monthly")
        )
        var ledger = CommerceLedgerState()
        _ = try ledger.grant(transactionID: "subscription-1", product: product)
        ledger.replaceActiveSubscriptions(with: [product.id])
        let now = Date(timeIntervalSince1970: 1_782_864_000)

        XCTAssertEqual(ledger.historyWeeks(catalog: catalog), 156)
        XCTAssertEqual(
            ledger.available(
                destination: .snapshot,
                catalog: catalog,
                now: now
            ),
            5
        )
        for _ in 0 ..< 5 {
            XCTAssertTrue(
                ledger.consumeSuccessfulResult(
                    destination: .snapshot,
                    catalog: catalog,
                    now: now
                )
            )
        }
        XCTAssertFalse(
            ledger.consumeSuccessfulResult(
                destination: .snapshot,
                catalog: catalog,
                now: now
            )
        )
    }

    func testAllLocalizedProductsResolve() throws {
        let catalog = try loadCatalog()
        for locale in catalog.supportedLocales {
            let localized = catalog.locale(for: locale)
            let toolkit = localized.toolkit
            XCTAssertEqual(toolkit.count, 52)
            XCTAssertEqual(Set(toolkit.keys), expectedToolkitKeys)
            XCTAssertFalse(localized.store.privacyPolicy.isEmpty)
            XCTAssertFalse(localized.store.termsOfUse.isEmpty)
            for product in catalog.products {
                let text = try catalog.text(
                    for: product,
                    languageCode: locale
                )
                XCTAssertFalse(text.name.isEmpty)
                XCTAssertFalse(text.description.isEmpty)
                XCTAssertFalse(text.name.contains("{quantity}"))
            }
        }
    }

    func testStoreLegalLinksAreSecureAndReviewerAccessible() {
        XCTAssertEqual(CommerceLegalLinks.privacyPolicy.scheme, "https")
        XCTAssertEqual(
            CommerceLegalLinks.privacyPolicy.host,
            "hotseason.app"
        )
        XCTAssertEqual(CommerceLegalLinks.termsOfUse.scheme, "https")
        XCTAssertEqual(CommerceLegalLinks.termsOfUse.host, "www.apple.com")
    }

    func testEveryProductHasARealGrantAndLocalizedPostPurchaseRoute() throws {
        let catalog = try loadCatalog()

        XCTAssertEqual(
            Set(catalog.products.map(\.destination)),
            Set(CommerceDestination.allCases)
        )
        XCTAssertEqual(
            Set(catalog.featureContracts.keys),
            Set(CommerceDestination.allCases)
        )

        for product in catalog.products {
            if product.isSubscription {
                let grant = try XCTUnwrap(product.grant)
                XCTAssertGreaterThan(grant.historyWeeks, 52)
                XCTAssertTrue(
                    grant.monthlyAllowances.values.contains { $0 > 0 }
                )
            } else {
                XCTAssertGreaterThan(try XCTUnwrap(product.quantity), 0)
            }

            for languageCode in catalog.supportedLocales {
                let locale = catalog.locale(for: languageCode)
                let productText = try catalog.text(
                    for: product,
                    languageCode: languageCode
                )
                let destinationText = locale.destinations[product.destination]
                let thankYou = locale.replacing(
                    locale.thankYouMessage,
                    values: ["product": productText.name]
                )
                let openAction = locale.replacing(
                    locale.openDestination,
                    values: ["destination": destinationText]
                )

                XCTAssertFalse(locale.thankYouTitle.isEmpty)
                XCTAssertFalse(thankYou.isEmpty)
                XCTAssertFalse(openAction.isEmpty)
                XCTAssertFalse(thankYou.contains("{product}"))
                XCTAssertFalse(openAction.contains("{destination}"))
                XCTAssertTrue(thankYou.contains(productText.name))
                XCTAssertTrue(openAction.contains(destinationText))
            }
        }
    }

    private var expectedToolkitKeys: Set<String> {
        [
            "title", "eyebrow", "subtitle", "loading", "noData",
            "noResult", "noCredit", "creditPrompt", "viewPlans",
            "viewSubscriptions", "addCredits", "back",
            "historyLockedTitle", "historyLockedBody",
            "observationSummary", "exchangeRate", "freight", "tariff",
            "loss", "direction", "above", "below", "threshold",
            "assumptionNotice", "alertNotice", "reuseTitle", "reuseBody",
            "benchmarkLimit", "unavailable", "commodity.01",
            "commodity.02", "action.history", "action.export",
            "action.compare", "action.snapshot", "action.seasonality",
            "action.landedCost", "action.alerts",
            "result.exportDelivered", "result.exportFailed",
            "result.compare", "result.snapshot", "result.seasonality",
            "result.landedCost", "result.alertNoMatch",
            "result.alertDelivered", "body.export", "body.compare",
            "body.snapshot", "body.seasonality", "body.landedCost",
            "body.alert",
        ]
    }

    private func loadCatalog() throws -> CommerceCatalog {
        try CommerceCatalog.load(bundle: .main)
    }
}
