//
//  UIViewController+ext.swift
//  QuestBlitzArena
//
//  Created by jin fu on 2024/11/18.
//

import UIKit

extension UIViewController {
    @IBAction func BackBtnTapped (_ sender : Any) {
        navigationController?.popViewController(animated: true)
    }
}
