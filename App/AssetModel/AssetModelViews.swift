import FinanceCore
import SwiftUI

struct AssetModelRootView: View {
    @Bindable var viewModel: FinancePortfolioViewModel

    var body: some View {
        NavigationStack {
            List {
                PortfolioHeaderSection(
                    totalValueInVND: viewModel.store.snapshot.totalValueInVND,
                    exchangeRateUSDToVND: viewModel.store.snapshot.exchangeRateUSDToVND,
                    onEditExchangeRate: { viewModel.showExchangeRate() }
                )

                Section("Assets") {
                    if viewModel.store.snapshot.assets.isEmpty {
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
                            Button("Add Asset") { viewModel.showAddAsset() }
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
                        ForEach(viewModel.store.snapshot.assets) { asset in
                            Button {
                                viewModel.toggleSelection(assetID: asset.id)
                            } label: {
                                AssetModelRow(
                                    asset: asset,
                                    isSelected: viewModel.selectedAssetID == asset.id
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityValue(
                                viewModel.selectedAssetID == asset.id ? "expanded" : "collapsed"
                            )
                            .accessibilityIdentifier("\(FinanceAccessibility.assetCard).\(asset.code)")

                            if viewModel.selectedAssetID == asset.id {
                                AssetModelQuickActions(
                                    asset: asset,
                                    onEditPrice: { viewModel.showEditPrice(assetID: asset.id) },
                                    onAddUnits: { viewModel.showAddUnits(assetID: asset.id) },
                                    onSubtractUnits: { viewModel.showSubtractUnits(assetID: asset.id) },
                                    onDelete: { viewModel.requestDelete(asset) }
                                )
                            }
                        }
                    }
                }

                if let asset = viewModel.selectedAsset {
                    AssetModelDetailSection(
                        asset: asset,
                        onEditPrice: { viewModel.showEditPrice(assetID: asset.id) },
                        onAddUnits: { viewModel.showAddUnits(assetID: asset.id) },
                        onSubtractUnits: { viewModel.showSubtractUnits(assetID: asset.id) },
                        onDelete: { viewModel.requestDelete(asset) }
                    )
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showAddAsset()
                    } label: {
                        Label("Add Asset", systemImage: "plus")
                    }
                    .accessibilityIdentifier(FinanceAccessibility.addAsset)
                }
            }
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

struct AssetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AssetEditorViewModel

    init(viewModel: AssetEditorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section("Asset") {
                    TextField("Code", text: $viewModel.code)
                        .textInputAutocapitalization(.characters)
                        .accessibilityIdentifier(FinanceAccessibility.codeField)
                    TextField("Name", text: $viewModel.name)
                        .accessibilityIdentifier(FinanceAccessibility.nameField)
                    Picker("Currency", selection: $viewModel.currency) {
                        ForEach(FinancialCurrency.allCases) { value in
                            Text(value.rawValue).tag(value)
                        }
                    }
                    .accessibilityIdentifier(FinanceAccessibility.currencyPicker)
                    TextField("Price", text: $viewModel.price)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier(FinanceAccessibility.priceField)
                }
                ValidationMessage(message: viewModel.errorMessage)
            }
            .navigationTitle("New Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: viewModel.save)
                        .accessibilityIdentifier(FinanceAccessibility.assetSave)
                }
            }
        }
    }
}

struct PriceEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PriceEditorViewModel

    init(viewModel: PriceEditorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section("Current Price") {
                    TextField("Price", text: $viewModel.price)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier(FinanceAccessibility.priceEditorField)
                }
                ValidationMessage(message: viewModel.errorMessage)
            }
            .navigationTitle("Edit Price")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: viewModel.save)
                        .accessibilityIdentifier(FinanceAccessibility.priceEditorSave)
                }
            }
        }
    }
}

struct UnitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: UnitEditorViewModel

    init(viewModel: UnitEditorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section(viewModel.operation == .add ? "Add Units" : "Subtract Units") {
                    TextField("Units", text: $viewModel.amount)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier(FinanceAccessibility.unitAmountField)
                    if viewModel.operation == .subtract, let available = viewModel.availableUnits {
                        Text("Available: \(available.unitsDisplay) units")
                            .foregroundStyle(.secondary)
                    }
                }
                ValidationMessage(message: viewModel.errorMessage)
            }
            .navigationTitle(viewModel.operation == .add ? "Add Units" : "Subtract Units")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: viewModel.save)
                        .accessibilityIdentifier(FinanceAccessibility.unitSave)
                }
            }
        }
    }
}

struct AssetModelExchangeRateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ExchangeRateEditorViewModel

    init(viewModel: ExchangeRateEditorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section("1 USD in VND") {
                    TextField("Exchange Rate", text: $viewModel.rate)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier(FinanceAccessibility.exchangeRateField)
                }
                ValidationMessage(message: viewModel.errorMessage)
            }
            .navigationTitle("Exchange Rate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: viewModel.save)
                        .accessibilityIdentifier(FinanceAccessibility.exchangeRateSave)
                }
            }
        }
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
