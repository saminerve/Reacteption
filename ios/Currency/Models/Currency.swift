//
//  Currency.swift
//  Currency
//
//  Created by Nuno Coelho Santos on 05/03/2016.
//  Copyright © 2016 Nuno Coelho Santos. All rights reserved.
//

import Foundation
import CoreData


class Currency: NSManagedObject {
    
    @NSManaged dynamic var name_de: String!
    @NSManaged dynamic var name_el: String!
    @NSManaged dynamic var name_en: String!
    @NSManaged dynamic var name_es: String!
    @NSManaged dynamic var name_fr: String!
    @NSManaged dynamic var name_id: String!
    @NSManaged dynamic var name_ja: String!
    @NSManaged dynamic var name_ko: String!
    @NSManaged dynamic var name_pt_PT: String!
    @NSManaged dynamic var name_sv: String!
    @NSManaged dynamic var name_tr: String!
    @NSManaged dynamic var name_zh_Hans: String!
    @NSManaged dynamic var name_zh_Hant: String!
    @NSManaged dynamic var code: String!
    @NSManaged dynamic var rateFromUSD: NSNumber!
    @NSManaged dynamic var decimals: NSNumber!
    @NSManaged dynamic var symbol: String?
    @NSManaged dynamic var locale: String?
    @NSManaged dynamic var symbolPosition: String?
    @NSManaged dynamic var useLocalization: Bool
    @NSManaged dynamic var useSymbol: Bool
    @NSManaged dynamic var useCustomSymbol: Bool

}
