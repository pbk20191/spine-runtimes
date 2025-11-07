//
//  SpineAtlasBox.swift
//  spine-ios
//
//  Created by 박병관 on 4/6/25.
//
import Foundation
import SpineC
import spine_apple_extension

open class SpineAtlasBox: NSObject {


    @nonobjc internal let box: PointeeBox<spine_atlas_wrapper, Disposer>

    struct Disposer: BoxDisposerProtocol {
        static func dispose(_ pointer: spine_atlas) {
            spine_atlas_dispose(pointer)
        }
    }

//    nonisolated(unsafe)
//        static let loader: spine_texture_loader = {
//            var context = SpineTextureLoaderContext()
//            context.load = { page, path, context in
//                let prop = NSMutableDictionary()
//
//                spine_atlas_page_set_texture(page, Unmanaged.passRetained(prop).toOpaque())
//                prop["kSpineAtlasPageProperty"] = [
//                    "name": String(cString: spine_atlas_page_get_name(page)),
//                    "width": spine_atlas_page_get_width(page),
//                    "height": spine_atlas_page_get_height(page),
//                    "minFilter": spine_atlas_page_get_min_filter(page).rawValue,
//                    "magFilter": spine_atlas_page_get_mag_filter(page).rawValue,
//                    "uWrap": spine_atlas_page_get_u_wrap(page).rawValue,
//                    "vWrap": spine_atlas_page_get_v_wrap(page).rawValue,
//                    "pma": spine_atlas_page_get_pma(page),
//                    "texturePath": String(cString: path),
//                    "index": spine_atlas_page_get_index(page),
//                ]
//                prop["kSpineAtlasPagePointer"] = NSValue(pointer: page)
//
//            }
//            context.unload = { storage, _ in
//                Unmanaged<AnyObject>.fromOpaque(storage!).release()
//            }
//            return spine_texture_loader_create(&context)
//        }()

    @nonobjc
    public init(atlas: spine_atlas) {
        self.box = .init(atlas)
        super.init()
    }

    @objc public convenience init(
        txt: String,
        dirPath: String = ""
    ) {

        let atlas = txt.utf8CString.withUnsafeBufferPointer {
            spine_atlas_create_with_loader($0.baseAddress!, Int32($0.count), dirPath, spine_get_default_dictionary_texture_loader(), true)
        }
        self.init(atlas: atlas)
    }

    @nonobjc public convenience init(
        path: String
    ) {
        let atlas = spine_atlas_load_with_loader(path, spine_get_default_dictionary_texture_loader(), true)
        self.init(atlas: atlas)
    }

    // typed Throw cause compiler crash with objc interface when library evolution is enabled
    @available(swift, obsoleted: 1.0)
    @objc(initWithPath:)
    public convenience init(
        notForSwift path: String,
    ) {
        self.init(path: path)
    }

    @available(swift, obsoleted: 1.0)
    @objc(initWithAtlas:)
    public convenience init(notForSwift atlas: spine_atlas) {
        self.init(atlas: .init(atlas))
    }


    @available(swift, obsoleted: 1.0)
    @objc
    public final func accessAtlas(
        _ body: (spine_atlas) -> Void
    ) {
        withUnsafeMutablePointer(to: &self.box[]) {
            body($0)
        }
    }

    @inline(__always)
    @nonobjc
    public subscript() -> spine_atlas_wrapper {
        @inline(__always)
        borrowing _modify {
            yield &box[]
        }
        @inline(__always)
        borrowing _read {
            yield box[]
        }
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else {
            return false
        }
        return self.nativePointer == other.nativePointer
    }

    open override var hash: Int {
        return self.nativePointer.hashValue
    }

    @nonobjc private var nativePointer: spine_atlas {
        self.box._pointer
    }

}
