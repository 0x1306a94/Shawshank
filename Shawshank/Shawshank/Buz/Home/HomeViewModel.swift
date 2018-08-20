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
    var header: String
    var items: [Item]
}

extension HomeViewSectionModel: AnimatableSectionModelType {
    typealias Item = String

    var identity: String {
        return header
    }

    init(original: HomeViewSectionModel, items: [HomeViewSectionModel.Item]) {
        self = original
        self.items = items
    }
}

class HomeViewModel {
    public var datas = Variable([HomeViewSectionModel]())
    
    init() {
        initialDatas()
    }
    
    private func initialDatas() {
        // 配置 data 初始值
        var value: [HomeViewSectionModel] = []
        value.append(HomeViewSectionModel(header: "代理", items: ["启动",]))
        value.append(HomeViewSectionModel(header: "高级设置", items: ["自定义 DNS", "智能路由",]))
        datas.value = value
        
        
    }
}
