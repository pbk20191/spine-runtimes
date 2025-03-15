//
//  File 2.swift
//  spine-ios
//
//  Created by 박병관 on 3/14/25.
//

import Foundation
import spine_c



public final class SpineSharedSource: NSObject {
    
    
    internal let skeletonData: UnsafeMutablePointer<spSkeletonData>
    internal let animationStateData: UnsafeMutablePointer<spAnimationStateData>
    internal let atlas: UnsafeMutablePointer<spAtlas>
    
    // takes the ownership of the skeletonData and atlas
    init(
        skeletonData: UnsafeMutablePointer<spSkeletonData>,
        atlas: UnsafeMutablePointer<spAtlas>
    ) {
        
        self.skeletonData = skeletonData
        self.atlas = atlas
        self.animationStateData = spAnimationStateData_create(skeletonData)
    }
    
    deinit {
        spSkeletonData_dispose(skeletonData)
        spAtlas_dispose(atlas)
        spAnimationStateData_dispose(animationStateData)
    }
    
    
    
    
}
