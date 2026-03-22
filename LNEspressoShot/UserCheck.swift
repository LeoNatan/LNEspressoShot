//
//  UserCheck.swift
//  LNEspressoShot
//
//  Created by Léo Natan on 22/03/2026.
//

import Foundation
import CoreServices

fileprivate
func currentUserIdentity() -> CSIdentity? {
    guard let query = CSIdentityQueryCreateForCurrentUser(nil) else { return nil }
    let queryRef = query.takeRetainedValue()
    defer { CSIdentityQueryStop(queryRef) }
    guard CSIdentityQueryExecute(queryRef, 0, nil) else { return nil }
    let users = CSIdentityQueryCopyResults(queryRef).takeRetainedValue() as! [CSIdentity]
    return users.first
}

fileprivate
func adminGroupIdentity() -> CSIdentity? {
    let authority = CSGetDefaultIdentityAuthority().takeUnretainedValue()
    guard let query = CSIdentityQueryCreateForName(nil, "admin" as CFString, kCSIdentityQueryStringEquals, kCSIdentityClassGroup, authority) else { return nil }
    let queryRef = query.takeRetainedValue()
    defer { CSIdentityQueryStop(queryRef) }
    guard CSIdentityQueryExecute(queryRef, 0, nil) else { return nil }
    let admins = CSIdentityQueryCopyResults(queryRef).takeRetainedValue() as! [CSIdentity]
    return admins.first
}

@objc(LNUserCheck) public
class UserCheck: NSObject {
    @objc public static
    var isUserAdmin: Bool {
        guard let user = currentUserIdentity(),
              let adminGroup = adminGroupIdentity() else {
            return false
        }

        return CSIdentityIsMemberOfGroup(user, adminGroup)
    }
}
