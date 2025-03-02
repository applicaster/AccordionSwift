//
//  DataSourceProvider.swift
//  AccordionSwift
//
//  Created by Victor Sigler Lopez on 7/3/18.
//  Updated by Kyle Wood on 15/10/19.
//  Copyright © 2018 Victor Sigler. All rights reserved.
//

import UIKit

// Defines if there can be multiple cells expanded at once
public enum NumberOfExpandedParentCells {
    case single
    case multiple
}

// Define Configuration properties that can be passed on initialization
public struct ConfigurationProperties {
    let shouldScrollToBottomOfExpandedParent: Bool

    public init(shouldScrollToBottomOfExpandedParent: Bool = true) {
        self.shouldScrollToBottomOfExpandedParent = shouldScrollToBottomOfExpandedParent
    }
}

public final class DataSourceProvider<DataSource: DataSourceType,
    ParentCellConfig: CellViewConfigType,
    ChildCellConfig: CellViewConfigType>
    where ParentCellConfig.Item == DataSource.Item, ChildCellConfig.Item == DataSource.Item.ChildItem {
    // MARK: - Typealias

    public typealias DidSelectParentAtIndexPathClosure = (UITableView, IndexPath, DataSource.Item?) -> Void
    public typealias DidSelectChildAtIndexPathClosure = (UITableView, IndexPath, DataSource.Item.ChildItem?) -> Void

    public typealias DidDeselectParentAtIndexPathClosure = (UITableView, IndexPath, DataSource.Item?) -> Void
    public typealias DidDeselectChildAtIndexPathClosure = (UITableView, IndexPath, DataSource.Item.ChildItem?) -> Void

    public typealias HeightForChildAtIndexPathClosure = (UITableView, IndexPath, DataSource.Item.ChildItem?) -> CGFloat
    public typealias HeightForParentAtIndexPathClosure = (UITableView, IndexPath, DataSource.Item?) -> CGFloat

    public typealias ContextMenuConfigurationForParentCellAtIndexPathClosure = (UITableView, IndexPath, DataSource.Item?) -> NSObject?
    public typealias ContextMenuConfigurationForChildCellAtIndexPathClosure = (UITableView, IndexPath, DataSource.Item.ChildItem?) -> NSObject?

    public typealias HeaderViewForSectionAtIndexClosure = (String?, Int) -> UIView?
    public typealias FooterViewForSectionAtIndexClosure = (String?, Int) -> UIView?

    public typealias HeaderHeightForSectionAtIndexClosure = (Int) -> CGFloat
    public typealias FooterHeightForSectionAtIndexClosure = (Int) -> CGFloat

    private typealias ParentCell = IndexPath

    // MARK: - Properties

    /// The data source.
    public var dataSource: DataSource

    // The currently expanded parent
    private var expandedParent: ParentCell?

    // Defines if accordion can have more than one cell open at a time
    private var numberOfExpandedParentCells: NumberOfExpandedParentCells

    /// The parent cell configuration.
    private let parentCellConfig: ParentCellConfig

    /// The child cell configuration.
    private let childCellConfig: ChildCellConfig

    /// The UITableViewDataSource
    private var _tableViewDataSource: TableViewDataSource?

    /// The UITableViewDelegate
    private var _tableViewDelegate: TableViewDelegate?

    /// The closure to be called when a Parent cell is selected
    private let didSelectParentAtIndexPath: DidSelectParentAtIndexPathClosure?

    /// The closure to be called when a Parent cell is unselected
    private let didDeselectParentAtIndexPath: DidDeselectParentAtIndexPathClosure?

    /// The closure to be called when a Child cell is selected
    private let didSelectChildAtIndexPath: DidSelectChildAtIndexPathClosure?

    /// The closure to be called when a Child cell is unselected
    private let didDeselectChildAtIndexPath: DidDeselectChildAtIndexPathClosure?

    /// The closure to define the height of the Parent cell at the specified IndexPath
    private let heightForParentCellAtIndexPath: HeightForParentAtIndexPathClosure?

    /// The closure to define the height of the Child cell at the specified IndexPath
    private let heightForChildCellAtIndexPath: HeightForChildAtIndexPathClosure?

    /// The closure to define the height of the Parent cell at the specified IndexPath
    private let contextMenuConfigurationForParentCellAtIndexPath: ContextMenuConfigurationForParentCellAtIndexPathClosure?

    /// The closure to define the height of the Parent cell at the specified IndexPath
    private let contextMenuConfigurationForChildCellAtIndexPath: ContextMenuConfigurationForChildCellAtIndexPathClosure?

    /// The closure to define the custom header view for the section
    private let headerViewForSectionAtIndex: HeaderViewForSectionAtIndexClosure?

    /// The closure to define the custom footer view for the section
    private let footerViewForSectionAtIndex: FooterViewForSectionAtIndexClosure?

    /// The closure to define the header view height for the section
    private let headerHeightForSectionAtIndex: HeaderHeightForSectionAtIndexClosure?

    /// The closure to define the footer view height for the section
    private let footerHeightForSectionAtIndex: FooterHeightForSectionAtIndexClosure?

    /// The closure to be called when scrollView is scrolled
    private let scrollViewDidScroll: ScrollViewDidScrollClosure?

    /// The additional configuration properties.
    private let configurationProperties: ConfigurationProperties

    ///// - Parameter section: A section in the data source.
    ///// - Returns: The footer view for the specified section.
    // func headerView(inSection section: Int) -> UIView?
    //
    ///// - Parameter section: A section in the data source.
    ///// - Returns: The footer view for the specified section.
    // func footerView(inSection section: Int) -> UIView?

    // MARK: - Initialization

    /// Initializes a new data source provider.
    ///
    /// - Parameters:
    ///   - dataSource: The data source.
    ///   - cellConfig: The cell configuration.
    public init(dataSource: DataSource,
                parentCellConfig: ParentCellConfig,
                childCellConfig: ChildCellConfig,
                didSelectParentAtIndexPath: DidSelectParentAtIndexPathClosure? = nil,
                didDeselectParentAtIndexPath: DidDeselectParentAtIndexPathClosure? = nil,
                didSelectChildAtIndexPath: DidSelectChildAtIndexPathClosure? = nil,
                didDeselectChildAtIndexPath: DidDeselectChildAtIndexPathClosure? = nil,
                heightForParentCellAtIndexPath: HeightForParentAtIndexPathClosure? = nil,
                heightForChildCellAtIndexPath: HeightForChildAtIndexPathClosure? = nil,
                contextMenuConfigurationForParentCellAtIndexPath: ContextMenuConfigurationForParentCellAtIndexPathClosure? = nil,
                contextMenuConfigurationForChildCellAtIndexPath: ContextMenuConfigurationForChildCellAtIndexPathClosure? = nil,
                headerViewForSectionAtIndex: HeaderViewForSectionAtIndexClosure? = nil,
                footerViewForSectionAtIndex: FooterViewForSectionAtIndexClosure? = nil,
                headerHeightForSectionAtIndex: HeaderHeightForSectionAtIndexClosure? = nil,
                footerHeightForSectionAtIndex: FooterHeightForSectionAtIndexClosure? = nil,
                scrollViewDidScroll: ScrollViewDidScrollClosure? = nil,
                numberOfExpandedParentCells: NumberOfExpandedParentCells = .multiple,
                configurationProperties: ConfigurationProperties? = nil
    ) {
        expandedParent = nil
        self.parentCellConfig = parentCellConfig
        self.childCellConfig = childCellConfig
        self.didSelectParentAtIndexPath = didSelectParentAtIndexPath
        self.didDeselectParentAtIndexPath = didDeselectParentAtIndexPath
        self.didSelectChildAtIndexPath = didSelectChildAtIndexPath
        self.didDeselectChildAtIndexPath = didDeselectChildAtIndexPath
        self.heightForParentCellAtIndexPath = heightForParentCellAtIndexPath
        self.heightForChildCellAtIndexPath = heightForChildCellAtIndexPath
        self.contextMenuConfigurationForParentCellAtIndexPath = contextMenuConfigurationForParentCellAtIndexPath
        self.contextMenuConfigurationForChildCellAtIndexPath = contextMenuConfigurationForChildCellAtIndexPath
        self.headerViewForSectionAtIndex = headerViewForSectionAtIndex
        self.footerViewForSectionAtIndex = footerViewForSectionAtIndex
        self.headerHeightForSectionAtIndex = headerHeightForSectionAtIndex
        self.footerHeightForSectionAtIndex = footerHeightForSectionAtIndex
        self.scrollViewDidScroll = scrollViewDidScroll
        self.numberOfExpandedParentCells = numberOfExpandedParentCells
        self.dataSource = dataSource
        self.configurationProperties = configurationProperties ?? ConfigurationProperties()

        let numberOfParentCells = dataSource.numberOfParents()
        assert(numberOfParentCells > 0, file: "DataSource has no parent cells")

        if numberOfExpandedParentCells == .single {
            assert(dataSource.numberOfExpandedParents() <= 1, file: "More than one expanded parent cell in dataSource")
            expandedParent = dataSource.indexOfFirstExpandedParent()
        }
    }

    // MARK: - Private Methods

    // Update the cells of the table based on the selected parent cell
    //
    // - Parameters:
    //   - tableView: The UITableView to update
    //   - item: The DataSource item that was selected
    //   - currentPosition: The current position in the data source
    //   - indexPaths: The last IndexPath of the new cells expanded
    //   - parentIndex: The index of the parent item selected
    private func update(_ tableView: UITableView, _ item: DataSource.Item?, _ currentPosition: Int, _ indexPath: IndexPath, _ parentIndex: Int) {
        guard let item = item else {
            return
        }

        let numberOfChildren = item.children.count
        guard numberOfChildren > 0 else {
            return
        }

        let selectedParentCell: ParentCell = indexPath

        tableView.beginUpdates()
        toggle(selectedParentCell, withState: item.state, dataSourceIndex: parentIndex, tableView)
        tableView.endUpdates()

        // If the cells were expanded then we verify if they are inside the CGRect
        if item.state == .expanded {
            let lastCellIndexPath = IndexPath(item: indexPath.item + numberOfChildren, section: indexPath.section)
            // Scroll the new cells expanded in case of be outside the UITableView CGRect
            scrollCellIfNeeded(atIndexPath: lastCellIndexPath, tableView)
        }
    }

    // Toggle the state of the selected parent cell between expanded and collapsed
    //
    // - Parameters:
    //   - currentState: The current state of the selected parent
    //   - selectedParentCell: The actual cell selected
    private func toggle(_ selectedParentCell: ParentCell, withState currentState: State, dataSourceIndex: Int, _ tableView: UITableView) {
        switch (currentState, numberOfExpandedParentCells) {
        case (.expanded, _):
            // Collapse the parent and it's children
            collapse(parent: selectedParentCell, dataSourceIndex: dataSourceIndex, tableView)
            expandedParent = nil
        case (.collapsed, .single):
            // Expand the parent and it's children and collapse the expanded parent
            var mutableSelectedParent = selectedParentCell

            if let expandedParent = expandedParent {
                collapse(parent: expandedParent, dataSourceIndex: expandedParent.item, tableView)
                // Correct the selectedCell's index after collapsing expanded cell
                mutableSelectedParent = correctParentCellIndexAfterCollapse(collapsedCell: expandedParent, toBeExpandedParent: selectedParentCell)
            }

            expand(parent: mutableSelectedParent, dataSourceIndex: dataSourceIndex, tableView)
            expandedParent = mutableSelectedParent
        case (.collapsed, .multiple):
            // Expand the parent and it's children
            expand(parent: selectedParentCell, dataSourceIndex: dataSourceIndex, tableView)
        }
    }

    // Expand the parent cell and it's children
    //
    // - Parameters:
    //   - parent: The actual parent cell to be expanded
    //   - dataSourceIndex: The index of the parent in the dataSource
    //   - tableView: The tableView to insert the children cells into
    private func expand(parent: ParentCell, dataSourceIndex: Int, _ tableView: UITableView) {
        let numberOfChildren = getNumberOfChildren(parent: parent, dataSourceIndex: dataSourceIndex)

        guard numberOfChildren > 0 else {
            return
        }

        let indexPaths = getIndexes(parent, numberOfChildren)
        tableView.insertRows(at: indexPaths, with: .fade)
        dataSource.toggleParentCell(toState: .expanded, inSection: parent.section, atIndex: dataSourceIndex)
    }

    // Get the number of children a parent cell has
    //
    // - Parameters:
    //   - parent: The actual parent cell to be expanded
    //
    // - Returns:
    //   - The number of children the parent cell has
    private func getNumberOfChildren(parent: ParentCell, dataSourceIndex: Int) -> Int {
        return dataSource.item(atRow: dataSourceIndex, inSection: parent.section)?.children.count ?? 0
    }

    // Correct the toBeExpanded cell's index after collapsing the expanded cell
    //
    // - Parameters:
    //   - collapsedCell: The parent cell that has been collapsed
    //   - toBeExpandedParent: The parent cell that will be expanded
    //
    // - Returns:
    //   - The updated parent cell to be expanded
    private func correctParentCellIndexAfterCollapse(collapsedCell expandedParent: ParentCell, toBeExpandedParent: ParentCell) -> ParentCell {
        // If toBeExpandedParent index is larger than the currentlyExpandedParent index
        // then update the selected parent index to be correct due to the currentlyExpandedParent's children being removed
        if toBeExpandedParent.item > expandedParent.item {
            let numberChildrenOfExpandedParent = getNumberOfChildren(parent: expandedParent, dataSourceIndex: expandedParent.item)

            var item = toBeExpandedParent.item
            if toBeExpandedParent.item - numberChildrenOfExpandedParent > 0 {
                item = toBeExpandedParent.item - numberChildrenOfExpandedParent
            }
            return IndexPath(item: item, section: toBeExpandedParent.section)
        }
        return toBeExpandedParent
    }

    // Collapse the parent cell and it's children
    //
    // - Parameters:
    //   - parent: The actual parent cell to be expanded
    //   - dataSourceIndex: The index of the parent in the dataSource
    //   - tableView: The tableView to remove the children cells from
    private func collapse(parent: ParentCell, dataSourceIndex: Int, _ tableView: UITableView) {
        let numberOfChildren = getNumberOfChildren(parent: parent, dataSourceIndex: dataSourceIndex)

        guard numberOfChildren > 0 else {
            return
        }

        let indexPaths = getIndexes(parent, numberOfChildren)
        tableView.deleteRows(at: indexPaths, with: .fade)
        dataSource.toggleParentCell(toState: .collapsed, inSection: parent.section, atIndex: dataSourceIndex)
    }

    ///  Get a list of index paths of the children of the parent cell
    ///
    /// - Parameters:
    ///   - parent: The parent cell
    ///   - numberOfChildren: The number of children the parent has
    private func getIndexes(_ parent: ParentCell, _ numberOfChildren: Int) -> [IndexPath] {
        let startPosition: Int = parent.item
        return (1 ... numberOfChildren).map { offset -> IndexPath in
            IndexPath(item: startPosition + offset, section: parent.section)
        }
    }

    /// Scroll the new cells expanded in case of be outside the UITableView CGRect
    ///
    /// - Parameters:
    ///   - indexPaths: The last IndexPath of the new cells expanded
    ///   - tableView: The UITableView to update
    private func scrollCellIfNeeded(atIndexPath indexPath: IndexPath, _ tableView: UITableView) {
        guard configurationProperties.shouldScrollToBottomOfExpandedParent == true else {
            return
        }

        let cellRect = tableView.rectForRow(at: indexPath)

        // Scroll to the cell in case of not being visible
        if !tableView.bounds.contains(cellRect) {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
}

extension DataSourceProvider {
    // MARK: - UITableViewDataSource

    /// The UITableViewDataSource protocol handler
    public var tableViewDataSource: UITableViewDataSource {
        if _tableViewDataSource == nil {
            _tableViewDataSource = configTableViewDataSource()
        }

        return _tableViewDataSource!
    }

    /// Config the UITableViewDataSource methods
    ///
    /// - Returns: An instance of the `TableViewDataSource`
    private func configTableViewDataSource() -> TableViewDataSource {
        let dataSource = TableViewDataSource(
            numberOfSections: { [unowned self] () -> Int in
                self.dataSource.numberOfSections()
            },
            numberOfItemsInSection: { [unowned self] (section) -> Int in
                self.dataSource.numberOfItems(inSection: section)
            })

        dataSource.tableCellForRowAtIndexPath = { [unowned self] (tableView, indexPath) -> UITableViewCell in

            let (parentPosition, isParent, currentPos) = self.dataSource.findParentOfCell(atIndexPath: indexPath)

            guard isParent else {
                let item = self.dataSource.childItem(at: indexPath, parentIndex: parentPosition, currentPos: currentPos)
                return self.childCellConfig.tableCellFor(item: item!, tableView: tableView, indexPath: indexPath)
            }

            let item = self.dataSource.item(at: IndexPath(item: parentPosition, section: indexPath.section))!
            return self.parentCellConfig.tableCellFor(item: item, tableView: tableView, indexPath: indexPath)
        }

        dataSource.tableTitleForHeaderInSection = { [unowned self] (section) -> String? in
            self.dataSource.headerTitle(inSection: section)
        }

        dataSource.tableTitleForFooterInSection = { [unowned self] (section) -> String? in
            self.dataSource.footerTitle(inSection: section)
        }

        return dataSource
    }
}

extension DataSourceProvider {
    // MARK: - UITableViewDelegate

    /// The UITableViewDataSource protocol handler
    public var tableViewDelegate: UITableViewDelegate {
        if _tableViewDelegate == nil {
            _tableViewDelegate = configTableViewDelegate()
        }

        return _tableViewDelegate!
    }

    /// Config the UITableViewDelegate methods
    ///
    /// - Returns: An instance of the `TableViewDelegate`
    private func configTableViewDelegate() -> TableViewDelegate {
        let delegate = TableViewDelegate()

        delegate.didSelectRowAtIndexPath = { [unowned self] (tableView, indexPath) -> Void in
            let (parentIndex, isParent, currentPosition) = self.dataSource.findParentOfCell(atIndexPath: indexPath)
            let item = self.dataSource.item(atRow: parentIndex, inSection: indexPath.section)

            if isParent {
                self.update(tableView, item, currentPosition, indexPath, parentIndex)
                self.didSelectParentAtIndexPath?(tableView, indexPath, item)
            } else {
                let index = indexPath.row - currentPosition - 1
                let childItem = index >= 0 ? item?.children[index] : nil
                self.didSelectChildAtIndexPath?(tableView, indexPath, childItem)
            }
        }

        delegate.didDeselectRowAtIndexPath = { [unowned self] (tableView, indexPath) -> Void in
            let (parentIndex, isParent, currentPosition) = self.dataSource.findParentOfCell(atIndexPath: indexPath)
            let item = self.dataSource.item(atRow: parentIndex, inSection: indexPath.section)

            if isParent {
                self.didDeselectParentAtIndexPath?(tableView, indexPath, item)
            } else {
                let index = indexPath.row - currentPosition - 1
                let childItem = index >= 0 ? item?.children[index] : nil
                self.didDeselectChildAtIndexPath?(tableView, indexPath, childItem)
            }
        }

        delegate.contextMenuConfigurationForRowAt = { [unowned self] (tableView, indexPath) -> NSObject? in
            let (parentIndex, isParent, currentPosition) = self.dataSource.findParentOfCell(atIndexPath: indexPath)
            let item = self.dataSource.item(atRow: parentIndex, inSection: indexPath.section)

            if isParent {
                return self.contextMenuConfigurationForParentCellAtIndexPath?(tableView, indexPath, item)
            } else {
                let index = indexPath.row - currentPosition - 1
                let childItem = index >= 0 ? item?.children[index] : nil
                return self.contextMenuConfigurationForChildCellAtIndexPath?(tableView, indexPath, childItem)
            }
        }

        delegate.heightForRowAtIndexPath = { [unowned self] (tableView, indexPath) -> CGFloat in
            let (parentIndex, isParent, currentPosition) = self.dataSource.findParentOfCell(atIndexPath: indexPath)
            let item = self.dataSource.item(atRow: parentIndex, inSection: indexPath.section)

            if isParent {
                return self.heightForParentCellAtIndexPath?(tableView, indexPath, item) ?? 40
            }

            let index = indexPath.row - currentPosition - 1
            let childItem = index >= 0 ? item?.children[index] : nil
            return self.heightForChildCellAtIndexPath?(tableView, indexPath, childItem) ?? 35
        }

        delegate.scrollViewDidScrollClosure = { [unowned self] (scrollView) -> Void in
            self.scrollViewDidScroll?(scrollView)
        }

        delegate.tableViewForHeaderInSection = { [unowned self] (sectionIndex) -> UIView? in
            let sectionTitle = self.dataSource.headerTitle(inSection: sectionIndex)
            return self.headerViewForSectionAtIndex?(sectionTitle, sectionIndex)
        }

        delegate.tableViewForFooterInSection = { [unowned self] (sectionIndex) -> UIView? in
            let footerTitle = self.dataSource.footerTitle(inSection: sectionIndex)
            return self.footerViewForSectionAtIndex?(footerTitle, sectionIndex)
        }

        delegate.heightForHeaderInSection = { [unowned self] (sectionIndex) -> CGFloat in
            self.headerHeightForSectionAtIndex?(sectionIndex) ?? 35
        }

        delegate.heightForFooterInSection = { [unowned self] (sectionIndex) -> CGFloat in
            self.footerHeightForSectionAtIndex?(sectionIndex) ?? 5
        }

        return delegate
    }
}
