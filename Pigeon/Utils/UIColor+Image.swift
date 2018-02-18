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

    convenience init?(hex: String, alpha: CGFloat) {
        if hex.count == 6 {
            let rawValue: Int = Int(hex, radix: 16) ?? 0
            let B255: Int = rawValue % 256
            let G255: Int = ((rawValue - B255) / 256) % 256
            let R255: Int = ((rawValue - B255) / 256 - G255) / 256

            self.init(red: CGFloat(R255) / 255, green: CGFloat(G255) / 255, blue: CGFloat(B255) / 255, alpha: alpha)
        } else {
            return nil
        }
    }

    convenience init?(hex: String) {
        self.init(hex: hex, alpha: 1.0)
    }
}
