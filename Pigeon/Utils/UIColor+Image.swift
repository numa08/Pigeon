//
//  UIColor+Image.swift
//  Pigeon
//
//  Created by numa08 on 2018/02/09.
//

import UIKit

extension UIColor {
    
    func image(forRect rect: CGRect) -> UIImage {
        UIGraphicsBeginImageContext(rect.size)
        guard let context = UIGraphicsGetCurrentContext() else { assertionFailure(); return UIImage() }
        // bitmapを塗りつぶし
        context.setFillColor(cgColor)
        context.fill(rect)
        // UIImageに変換
        guard let image: UIImage = UIGraphicsGetImageFromCurrentImageContext() else { assertionFailure(); return UIImage() }
        UIGraphicsEndImageContext()
        return image
    }
    
}

