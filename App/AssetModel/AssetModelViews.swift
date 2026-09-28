import FinanceCore
import SwiftUI

private enum AssetModelSheet: Identifiable {
    case addAsset
    case editPrice(UUID)
    case units(UUID, UnitOperation)
    case exchangeRate

    var id: String {
        switch self {
        case .addAsset: "add-asset"
        case .editPrice(let id): "edit-price-\(id)"
        case let .units(id, operation): "units-\(id)-\(operation.rawValue)"
        case .exchangeRate: "exchange-rate"
        }
    }
}

private enum AssetModelAlert: Identifiable {
    case delete(FinancialAsset)
    case error(String)

    var id: String {
        switch self {
        case .delete(let asset): "delete-\(asset.id.uuidString)"
        case .error(let message): "error-\(message)"
        }
    }
}

struct AssetModelRootView: View {
    let store: FinanceStore

    @State private var selectedAssetID: UUID?
    @State private var sheet: AssetModelSheet?
    @State private var activeAlert: AssetModelAlert?

    private var selectedAsset: FinancialAsset? {
        guard let selectedAssetID else { return nil }
        return store.asset(id: selectedAssetID)
    }

    var body: some View {
        NavigationStack {
            List {
                PortfolioHeaderSection(
                    totalValueInVND: store.snapshot.totalValueInVND,
                    exchangeRateUSDToVND: store.snapshot.exchangeRateUSDToVND,
                    onEditExchangeRate: { sheet = .exchangeRate }
                )

                Section("Assets") {
                    if store.snapshot.assets.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.pie")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No Assets Yet")
                                .font(.headline)
                                .accessibilityIdentifier(FinanceAccessibility.emptyState)
                            Text("Add an asset, set its price, then record units.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Add Asset") { sheet = .addAsset }
                                .buttonStyle(.borderedProminent)
                                .accessibilityIdentifier(FinanceAccessibility.addAsset)

                            Text("Portfolio empty")
                                .font(.caption)
                                .foregroundStyle(.clear)
                                .frame(width: 1, height: 1)
                                .accessibilityIdentifier(FinanceAccessibility.legacyEmptyState)
                        }
                        .accessibilityIdentifier(FinanceAccessibility.emptyState)
                    } else {
                        ForEach(store.snapshot.assets) { asset in
                            Button {
                                selectedAssetID = asset.id
                            } label: {
                                AssetModelRow(
                                    asset: asset,
                                    isSelected: selectedAssetID == asset.id
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("\(FinanceAccessibility.assetCard).\(asset.code)")

                            if selectedAssetID == asset.id {
                                AssetModelQuickActions(
                                    asset: asset,
                                    onEditPrice: { sheet = .editPrice(asset.id) },
                                    onAddUnits: { sheet = .units(asset.id, .add) },
                                    onSubtractUnits: { sheet = .units(asset.id, .subtract) },
                                    onDelete: { requestDeleteConfirmation(for: asset) }
                                )
                            }
                        }
                    }
                }

                if let asset = selectedAsset {
                    AssetModelDetailSection(
                        asset: asset,
                        onEditPrice: { sheet = .editPrice(asset.id) },
                        onAddUnits: { sheet = .units(asset.id, .add) },
                        onSubtractUnits: { sheet = .units(asset.id, .subtract) },
                        onDelete: { requestDeleteConfirmation(for: asset) }
                    )
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        sheet = .addAsset
                    } label: {
                        Label("Add Asset", systemImage: "plus")
                    }
                    .accessibilityIdentifier(FinanceAccessibility.addAsset)
                }
            }
        }
        .sheet(item: $sheet) { destination in
            switch destination {
            case .addAsset:
                AssetEditorView(store: store)
            case .editPrice(let assetID):
                PriceEditorView(store: store, assetID: assetID)
            case let .units(assetID, operation):
                UnitEditorView(store: store, assetID: assetID, operation: operation)
            case .exchangeRate:
                AssetModelExchangeRateEditorView(store: store)
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .delete(let asset):
                return Alert(
                    title: Text("Delete asset?"),
                    message: Text("This removes \(asset.code) and its unit history."),
                    primaryButton: .destructive(Text("Delete Asset")) {
                        do {
                            try store.send(.deleteAsset(assetID: asset.id))
                            selectedAssetID = nil
                        } catch {
                            activeAlert = .error(error.financeMessage)
                        }
                    },
                    secondaryButton: .cancel(Text("Cancel"))
                )
            case .error(let message):
                return Alert(
                    title: Text("Could Not Save"),
                    message: Text(message),
                    dismissButton: .cancel(Text("OK"))
                )
            }
        }
    }

    private func requestDeleteConfirmation(for asset: FinancialAsset) {
        // Present after the initiating touch completes. This avoids the physical-device
        // touch-up being delivered to the newly presented alert and dismissing it.
        DispatchQueue.main.async {
            activeAlert = .delete(asset)
        }
    }
}

private struct AssetModelQuickActions: View {
    let asset: FinancialAsset
    let onEditPrice: () -> Void
    let onAddUnits: () -> Void
    let onSubtractUnits: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Edit Price", action: onEditPrice)
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier(FinanceAccessibility.editPrice)

            Button("Add Units", action: onAddUnits)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier(FinanceAccessibility.addUnits)

            Button("Subtract Units", action: onSubtractUnits)
                .buttonStyle(.bordered)
                .disabled(asset.totalUnits <= 0)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier(FinanceAccessibility.subtractUnits)

            Button("Delete Asset", role: .destructive, action: onDelete)
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier(FinanceAccessibility.deleteAsset)

            if let transaction = asset.transactions.last {
                HStack {
                    Text(transaction.units.signedUnitsDisplay).font(.headline)
                    Spacer()
                    Text(transaction.occurredAt, format: .dateTime.month(.abbreviated).day().year())
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "\(transaction.units >= 0 ? "Added" : "Subtracted") " +
                    "\(abs(transaction.units).unitsDisplay) units"
                )
                .accessibilityIdentifier(FinanceAccessibility.transactionRow)
            }
        }
        .padding(.leading, 44)
        .padding(.bottom, 4)
    }
}

private struct PortfolioHeaderSection: View {
    let totalValueInVND: Double
    let exchangeRateUSDToVND: Double
    let onEditExchangeRate: () -> Void

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Total value")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(totalValueInVND.vndDisplay)
                    .font(.largeTitle.bold())
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier(FinanceAccessibility.summaryTotalVND)
                HStack {
                    Text("1 USD = \(exchangeRateUSDToVND.plainNumber) VND")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier(FinanceAccessibility.summaryExchangeRate)
                    Spacer()
                    Button("Edit Rate", action: onEditExchangeRate)
                        .accessibilityIdentifier(FinanceAccessibility.editExchangeRate)
                }
            }
            .padding(.vertical, 6)
        }
    }
}

private struct AssetModelRow: View {
    let asset: FinancialAsset
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "chart.pie.fill" : "chart.pie")
                .font(.title2)
                .foregroundStyle(isSelected ? .blue : .secondary)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(asset.code).font(.headline)
                Text(asset.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(asset.nativeValue.nativeDisplay(currency: asset.currency))
                    .font(.headline)
                Text("\(asset.totalUnits.unitsDisplay) units")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}

private struct AssetModelDetailSection: View {
    let asset: FinancialAsset
    let onEditPrice: () -> Void
    let onAddUnits: () -> Void
    let onSubtractUnits: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Section("Asset Details") {
            LabeledContent("Code") {
                Text(asset.code).accessibilityIdentifier(FinanceAccessibility.assetCode)
            }
            LabeledContent("Name") {
                Text(asset.name).accessibilityIdentifier(FinanceAccessibility.assetName)
            }
            LabeledContent("Currency") {
                Text(asset.currency.rawValue)
                    .accessibilityIdentifier(FinanceAccessibility.assetCurrency)
            }
            LabeledContent("Price") {
                Text(asset.price.nativeDisplay(currency: asset.currency))
                    .accessibilityLabel(asset.price.plainNumber)
                    .accessibilityIdentifier(FinanceAccessibility.assetPrice)
            }
            LabeledContent("Units") {
                Text(asset.totalUnits.unitsDisplay)
                    .accessibilityIdentifier(FinanceAccessibility.assetUnits)
            }
            LabeledContent("Native total") {
                Text(asset.nativeValue.nativeDisplay(currency: asset.currency))
                    .accessibilityIdentifier(FinanceAccessibility.assetNativeTotal)
            }
            Button("Edit Price", action: onEditPrice)
                .accessibilityIdentifier(FinanceAccessibility.editPrice)
            HStack {
                Button("Add Units", action: onAddUnits)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier(FinanceAccessibility.addUnits)
                Button("Subtract Units", action: onSubtractUnits)
                    .buttonStyle(.bordered)
                    .disabled(asset.totalUnits <= 0)
                    .accessibilityIdentifier(FinanceAccessibility.subtractUnits)
            }
            .controlSize(.large)
            Button("Delete Asset", role: .destructive, action: onDelete)
                .accessibilityIdentifier(FinanceAccessibility.deleteAsset)
        }

        Section("Unit History") {
            if asset.transactions.isEmpty {
                Text("No unit transactions").foregroundStyle(.secondary)
            } else {
                ForEach(asset.transactions) { transaction in
                    HStack {
                        Text(transaction.units.signedUnitsDisplay).font(.headline)
                        Spacer()
                        Text(transaction.occurredAt, format: .dateTime.month(.abbreviated).day().year())
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "\(transaction.units >= 0 ? "Added" : "Subtracted") " +
                        "\(abs(transaction.units).unitsDisplay) units"
                    )
                    .accessibilityIdentifier(FinanceAccessibility.transactionRow)
                }
            }
        }
    }
}

private struct AssetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let store: FinanceStore
    @State private var code = ""
    @State private var name = ""
    @State private var currency = FinancialCurrency.usd
    @State private var price = "0"
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Asset") {
                    TextField("Code", text: $code)
                        .textInputAutocapitalization(.characters)
                        .accessibilityIdentifier(FinanceAccessibility.codeField)
                    TextField("Name", text: $name)
                        .accessibilityIdentifier(FinanceAccessibility.nameField)
                    Picker("Currency", selection: $currency) {
                        ForEach(FinancialCurrency.allCases) { value in
                            Text(value.rawValue).tag(value)
                        }
                    }
                    .accessibilityIdentifier(FinanceAccessibility.currencyPicker)
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier(FinanceAccessibility.priceField)
                }
                ValidationMessage(message: errorMessage)
            }
            .navigationTitle("New Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .accessibilityIdentifier(FinanceAccessibility.assetSave)
                }
            }
        }
    }

    private func save() {
        guard let parsedPrice = price.decimalInput else {
            errorMessage = FinanceStoreError.assetPriceInvalid.errorDescription
            return
        }
        do {
            try store.send(.createAsset(
                id: UUID(), code: code, name: name, currency: currency, price: parsedPrice
            ))
            dismiss()
        } catch { errorMessage = error.financeMessage }
    }
}

private struct PriceEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let store: FinanceStore
    let assetID: UUID
    @State private var price = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Current Price") {
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier(FinanceAccessibility.priceEditorField)
                }
                ValidationMessage(message: errorMessage)
            }
            .navigationTitle("Edit Price")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .accessibilityIdentifier(FinanceAccessibility.priceEditorSave)
                }
            }
            .onAppear { price = store.asset(id: assetID)?.price.plainNumber ?? "" }
        }
    }

    private func save() {
        guard let asset = store.asset(id: assetID), let value = price.decimalInput else {
            errorMessage = FinanceStoreError.assetPriceInvalid.errorDescription
            return
        }
        do {
            try store.send(.updateAsset(
                assetID: asset.id,
                code: asset.code,
                name: asset.name,
                currency: asset.currency,
                price: value
            ))
            dismiss()
        } catch { errorMessage = error.financeMessage }
    }
}

private struct UnitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let store: FinanceStore
    let assetID: UUID
    let operation: UnitOperation
    @State private var amount = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(operation == .add ? "Add Units" : "Subtract Units") {
                    TextField("Units", text: $amount)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier(FinanceAccessibility.unitAmountField)
                    if operation == .subtract, let asset = store.asset(id: assetID) {
                        Text("Available: \(asset.totalUnits.unitsDisplay) units")
                            .foregroundStyle(.secondary)
                    }
                }
                ValidationMessage(message: errorMessage)
            }
            .navigationTitle(operation == .add ? "Add Units" : "Subtract Units")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .accessibilityIdentifier(FinanceAccessibility.unitSave)
                }
            }
        }
    }

    private func save() {
        guard let value = amount.decimalInput else {
            errorMessage = FinanceStoreError.unitsInvalid.errorDescription
            return
        }
        do {
            let transactionID = UUID()
            if operation == .add {
                try store.send(.addUnits(
                    assetID: assetID,
                    transactionID: transactionID,
                    occurredAt: .now,
                    units: value
                ))
            } else {
                try store.send(.subtractUnits(
                    assetID: assetID,
                    transactionID: transactionID,
                    occurredAt: .now,
                    units: value
                ))
            }
            dismiss()
        } catch { errorMessage = error.financeMessage }
    }
}

private struct AssetModelExchangeRateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let store: FinanceStore
    @State private var rate = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("1 USD in VND") {
                    TextField("Exchange Rate", text: $rate)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier(FinanceAccessibility.exchangeRateField)
                }
                ValidationMessage(message: errorMessage)
            }
            .navigationTitle("Exchange Rate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .accessibilityIdentifier(FinanceAccessibility.exchangeRateSave)
                }
            }
            .onAppear { rate = store.snapshot.exchangeRateUSDToVND.plainNumber }
        }
    }

    private func save() {
        guard let value = rate.decimalInput else {
            errorMessage = FinanceStoreError.exchangeRateInvalid.errorDescription
            return
        }
        do {
            try store.send(.updateExchangeRate(value))
            dismiss()
        } catch { errorMessage = error.financeMessage }
    }
}

@ViewBuilder
private func ValidationMessage(message: String?) -> some View {
    if let message {
        Section {
            Text(message)
                .foregroundStyle(XQPalette.destructive)
                .accessibilityIdentifier(FinanceAccessibility.validationError)
        }
    }
}

private extension Error {
    var financeMessage: String {
        (self as? LocalizedError)?.errorDescription ?? localizedDescription
    }
}

private extension String {
    var decimalInput: Double? {
        Double(
            trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")
        )
    }
}

private extension Double {
    var plainNumber: String {
        formatted(.number.grouping(.never).precision(.fractionLength(0...6)))
    }

    var unitsDisplay: String { plainNumber }

    var signedUnitsDisplay: String {
        "\(self >= 0 ? "+" : "−")\(abs(self).unitsDisplay)"
    }

    var vndDisplay: String {
        Self.vndFormatter.string(from: NSNumber(value: self)) ?? "₫0"
    }

    func nativeDisplay(currency: FinancialCurrency) -> String {
        switch currency {
        case .usd:
            Self.usdFormatter.string(from: NSNumber(value: self)) ?? "$0"
        case .vnd:
            vndDisplay
        }
    }

    private static let vndFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencySymbol = "₫"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private static let usdFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()
}
