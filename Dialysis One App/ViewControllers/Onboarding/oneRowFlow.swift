//
//  oneRowFlow.swift
//  Dialysis One App
//
//  Created by user@1 on 11/11/25.
//

import Foundation
import UIKit

final class OneRowFlowLayout: UICollectionViewFlowLayout {

    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }

        scrollDirection = .horizontal

        // Force exactly ONE row
        let height = collectionView.bounds.height
        itemSize = CGSize(width: itemSize.width, height: height)

        minimumInteritemSpacing = .greatestFiniteMagnitude
        minimumLineSpacing = (itemSize.width / 2)  // spacing between numbers
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
