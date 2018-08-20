//
//  HomeViewModel.swift
//  Shawshank
//
//  Created by Gua on 2018/8/13.
//  Copyright © 2018 Harry Twan. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import Differentiator

struct HomeViewSectionModel {
    enum Category {
        case proxy(Bool)
        case config(Bool)
    }

    var header: Category
    var items: [Item]
}

extension HomeViewSectionModel.Category {
    var title: String {
        get {
            switch self {
            case .proxy(_): return "代理"
            case .config(_): return "高级设置"
            }
        }
    }
}

extension HomeViewSectionModel: AnimatableSectionModelType {
    typealias Item = String

    var identity: String {
        return header.title
    }

    init(original: HomeViewSectionModel, items: [HomeViewSectionModel.Item]) {
        self = original
        self.items = items
    }
}

class HomeViewModel {

    private var disposeBag = DisposeBag()

    private(set) var datas = Variable([HomeViewSectionModel]())
    private(set) var vpnState = Variable(VpnManager.shared.vpnStatus)

    init() {
        initialDatas()
        initialBinds()
    }
    
    private func initialDatas() {
        // 配置 data 初始值
        updateDatas()
    }

    private func initialBinds() {
        NotificationCenter.default.rx
            .notification(.SSKVpnStatusChanged)
            .subscribe { _ in
                self.updateDatas()
            }
            .disposed(by: disposeBag)
    }

    private func updateDatas() {
        var value: [HomeViewSectionModel] = []
        switch VpnManager.shared.vpnStatus {
        case .connecting, .on:
            value.append(HomeViewSectionModel(header: .proxy(true), items: ["关闭",]))
        case .disconnecting, .off:
            value.append(HomeViewSectionModel(header: .proxy(true), items: ["启动",]))
        }
        value.append(HomeViewSectionModel(header: .config(true), items: ["自定义 DNS", "智能路由",]))
        datas.value = value
    }
}
