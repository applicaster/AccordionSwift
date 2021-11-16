//
//  TableViewDelegate.swift
//  AccordionSwift
//
//  Created by Victor Sigler Lopez on 7/5/18.
//  Copyright © 2018 Victor Sigler. All rights reserved.
//

import UIKit

typealias DidSelectRowAtIndexPathClosure = (UITableView, IndexPath) -> Void
typealias DidDeselectRowAtIndexPathClosure = (UITableView, IndexPath) -> Void
typealias ContextMenuConfigurationForRowAtClosure = (UITableView, IndexPath) -> NSObject?

typealias HeightForRowAtIndexPathClosure = (UITableView, IndexPath) -> CGFloat
public typealias ScrollViewDidScrollClosure = (UIScrollView) -> Void

@objc final class TableViewDelegate: NSObject {
    
    // MARK: - Properties
    
    var didSelectRowAtIndexPath: DidSelectRowAtIndexPathClosure?
    var didDeselectRowAtIndexPath: DidDeselectRowAtIndexPathClosure?
    var heightForRowAtIndexPath: HeightForRowAtIndexPathClosure?
    var contextMenuConfigurationForRowAt: ContextMenuConfigurationForRowAtClosure?

    var scrollViewDidScrollClosure: ScrollViewDidScrollClosure?

}

extension TableViewDelegate: UITableViewDelegate {
    
    @objc func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRowAtIndexPath?(tableView, indexPath)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        didDeselectRowAtIndexPath?(tableView, indexPath)
    }
    
    @objc func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightForRowAtIndexPath!(tableView, indexPath)
    }
    
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return contextMenuConfigurationForRowAt?(tableView, indexPath) as? UIContextMenuConfiguration
    }
}

extension TableViewDelegate: UIScrollViewDelegate {
    @objc func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDidScrollClosure?(scrollView)
    }
}
