//
//  BaseViewController.swift
//  Shawshank
//
//  Created by Harry Twan on 2018/8/21.
//  Copyright © 2018 Harry Twan. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import CocoaLumberjackSwift

class BaseViewController: UIViewController {
    
    // MARK: - Initializing
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }
    
    // MARK: - Rx
    var disposeBag = DisposeBag()
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        initialViews()
        initialBinds()
        initialLayouts()
    }
    
    // MARK: - Override
    open func initialViews() {}
    open func initialBinds() {}
    open func initialLayouts() {}
}
