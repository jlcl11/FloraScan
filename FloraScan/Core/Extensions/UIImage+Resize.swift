//
//  UIImage+Resize.swift
//  FloraScan
//
//  Created by José Luis Corral López on 29/4/26.
//

import UIKit

extension UIImage {
    /// Downscale to a maximum dimension while preserving aspect ratio.
    /// Returns self unchanged if already within bounds.
    func resizedForAPI(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
