//
//  ProductInfoDelegate.swift
//  ExpirationDateMonitor
//
//  Created by Shachar Erez on 11/24/20.
//

import Foundation


protocol ProductInfoDelegate
{
    func setExpirationDate(date: Date)
    
    func setProductName(name: String)
    
    func onProductInfoReady()
}
