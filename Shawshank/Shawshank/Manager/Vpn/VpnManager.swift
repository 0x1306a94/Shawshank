//
//  VpnManager.swift
//  Shawshank
//
//  Created by Gua on 2018/8/13.
//  Copyright © 2018 Harry Twan. All rights reserved.
//

import UIKit
import Foundation
import NetworkExtension
import NEKit
import RxSwift
import RxCocoa
import CocoaLumberjackSwift

enum VPNStatus: String {
    case off = "OFF"
    case connecting = "CONNECTING"
    case on = "ON"
    case disconnecting = "DISCONNECTION"
}

class VpnManager {
    
    static let shared: VpnManager = VpnManager()
    
    var observerAdded: Bool = false

    private(set) var vpnStatus = VPNStatus.off {
        didSet {
            NotificationCenter.default.post(name: Notification.Name.NEVPNStatusDidChange, object: nil)
        }
    }
    
    init() {
        loadProviderManager{
            guard let manager = $0 else { return }
            self.updateVPNStatus(manager)
        }
        addVPNStatusObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func addVPNStatusObserver() {
        guard !observerAdded else { return }
        loadProviderManager { [unowned self] (manager) -> Void in
            if let manager = manager {
                self.observerAdded = true
                NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: manager.connection, queue: OperationQueue.main) { [unowned self] notification -> Void in
                    self.updateVPNStatus(manager)
                }
            }
        }
    }
    
    private func updateVPNStatus(_ manager: NEVPNManager) {
        let oldStatus = vpnStatus
        switch manager.connection.status {
        case .connected:
            vpnStatus = .on
        case .connecting, .reasserting:
            vpnStatus = .connecting
        case .disconnecting:
            vpnStatus = .disconnecting
        case .disconnected, .invalid:
            vpnStatus = .off
        }
        if vpnStatus != oldStatus {
            NotificationCenter.default.post(name: .SSKVpnStatusChanged, object: nil)
        }
        DDLogDebug(self.vpnStatus.rawValue)
    }
}

// MARK: - VPN Profiles
extension VpnManager {
    
    private func createProviderManager() -> NETunnelProviderManager {
        let manager = NETunnelProviderManager()
        let conf = NETunnelProviderProtocol()
        conf.serverAddress = "Shawshank"
        manager.protocolConfiguration = conf
        manager.localizedDescription = "Shawshank"
        return manager
    }

    private func loadAndCreatePrividerManager(_ complete: @escaping (NETunnelProviderManager?) -> Void ){
        NETunnelProviderManager.loadAllFromPreferences{ (managers, error) in
            guard let managers = managers else { return }
            let manager: NETunnelProviderManager
            if managers.count > 0 {
                manager = managers[0]
                self.delDupConfig(managers)
            }else{
                manager = self.createProviderManager()
            }
            
            self.setRulerConfig(manager)

            manager.saveToPreferences { error in
                if let error = error {
                    DDLogDebug(error.localizedDescription)
                    complete(nil)
                    return
                }
                manager.loadFromPreferences { error_2 in
                    if let error = error_2 {
                        DDLogDebug(error.localizedDescription)
                        complete(nil)
                        return
                    }
                    self.addVPNStatusObserver()
                    complete(manager)
                }
            }
        }
    }
    
    private func loadProviderManager(_ complete: @escaping (NETunnelProviderManager?) -> Void){
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            if let managers = managers, managers.count > 0 {
                let manager = managers[0]
                complete(manager)
                return
            }
            complete(nil)
        }
    }

    private func delDupConfig(_ arrays: [NETunnelProviderManager]) {
        if arrays.count > 1 {
            for i in 0 ..< arrays.count{
                print("Del DUP Profiles")
                arrays[i].removeFromPreferences { error in
                    if (error != nil) {
                        DDLogDebug(error.debugDescription)
                    }
                }
            }
        }
    }
}

// MARK: - Actions
extension VpnManager {

    /// 连接 Vpn
    public func connect() {
        self.loadAndCreatePrividerManager { (manager) in
            guard let manager = manager else{return}
            do {
                try manager.connection.startVPNTunnel(options: [:])
            } catch let err {
                DDLogDebug(err.localizedDescription)
            }
        }
    }

    /// 断开连接
    public func disconnect() {
        loadProviderManager { manager in
            manager?.connection.stopVPNTunnel()
        }
    }
}

// MARK: - Generate and Load ConfigFile
extension VpnManager {

    fileprivate func getRuleConf() -> String{
        guard let Path = Bundle.main.path(forResource: "NEKitRule", ofType: "conf") else { return "" }
        do {
            if let Data = try? Foundation.Data(contentsOf: URL(fileURLWithPath: Path)) {
                guard let str = String(data: Data, encoding: String.Encoding.utf8) else { return "" }
                return str
            }
            return ""
        }
    }
    
    fileprivate func setRulerConfig(_ manager:NETunnelProviderManager){
        var conf: [String: String] = [:]

        // 很多人联系我这里没有注释掉 ss 端口
        // 因为如果你们使用了, 我是能拿到你们 IP 和目的 IP 的
        // 慎用哦 :P
        conf["ss_address"] = "23.105.207.34"
        conf["ss_port"] = "11394"
        conf["ss_method"] = "AES256CFB"
        conf["ss_password"] = "dhy94113"
        conf["ymal_conf"] = getRuleConf()
        if let orignConf = manager.protocolConfiguration as? NETunnelProviderProtocol {
            orignConf.providerConfiguration = conf
            manager.protocolConfiguration = orignConf
            manager.isEnabled = true
        }
    }
}


