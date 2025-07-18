//
//  File.swift
//  spine-ios
//
//  Created by pbk0619 on 7/16/25.
//

import Foundation
import Testing
import spine_c
import spine_c.block_support

struct SimpleTestCase {


    @Test
    func example() throws {
        //import spine_apple_extension
        spine_enable_debug_extension(true)
        do {
            var table = SpineTextureLoaderContext()
            class FOOO {

                deinit {
                    print("deinit")
                }
            }

            class BlockTrack {
                deinit {
                    print("block dispose", self)
                }
            }

            table.info = .init(bitPattern: 100)
            table.load = { (page, path, _) in
                let storage = NSMutableDictionary()
                let pointer = Unmanaged.passRetained(storage).toOpaque()
                spine_atlas_page_set_texture(page, pointer)

                let property =
                    [
                        "name": String(cString: spine_atlas_page_get_name(page)),
                        "width": spine_atlas_page_get_width(page),
                        "height": spine_atlas_page_get_height(page),
                        "minFilter": spine_atlas_page_get_min_filter(page).rawValue,
                        "magFilter": spine_atlas_page_get_mag_filter(page).rawValue,
                        "uWrap": spine_atlas_page_get_u_wrap(page).rawValue,
                        "vWrap": spine_atlas_page_get_v_wrap(page).rawValue,
                        "pma": spine_atlas_page_get_pma(page),
                        "texturePath": String(cString: path),
                        "index": spine_atlas_page_get_index(page),
                        "format": spine_atlas_page_get_format(page).rawValue,
                    ] as [String: Any]

                //    print(popo)
                storage["property"] = property
            }
            table.unload = { (storage, context) in
                Unmanaged<AnyObject>.fromOpaque(storage!).release()
            }
            table.initialize = { input in
                let value = Int.init(bitPattern: input)
                #expect(value == 100)
                return Unmanaged<AnyObject>.passRetained(FOOO()).toOpaque()
            }
            table.deinitialize = { context in
                if let context {
                    Unmanaged<AnyObject>.fromOpaque(context).release()
                }
            }
            let loader = spine_texture_loader_create(&table)
            defer {
                spine_texture_loader_dispose(loader)
            }

            let atlas = spine_atlas_load(Bundle.module.path(forResource: "spineboy", ofType: "atlas")!, loader, true)
            defer {
                spine_atlas_dispose(atlas)
            }
            let data = try {
                let jsonLoader = spine_skeleton_json_create(atlas)
                defer {
                    spine_skeleton_json_dispose(jsonLoader)
                }

                let data = spine_skeleton_json_read_skeleton_data_file(jsonLoader, Bundle.module.path(forResource: "spineboy-pro", ofType: "json"))
                if let data {
                    return data
                } else {
                    let message = String(cString: spine_skeleton_json_get_error(jsonLoader))
                    print(message)
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                }
            }()
            defer {
                spine_skeleton_data_dispose(data)
            }
            let animationData = spine_animation_state_data_create(data)
            defer {
                spine_animation_state_data_dispose(animationData)
            }
            let animationState = spine_animation_state_create(animationData)!
            defer {
                spine_animation_state_dispose(animationState)
            }
            let skeleton = spine_skeleton_create(data)!
            defer {
                spine_skeleton_dispose(skeleton)
            }
            var a = 0
            var flag = false
            let p = BlockTrack()
            var dispose_call_count = 0
            spine_animation_state_set_block(animationState) { state, type, entry, event in
                let _ = p
                a += 1
                if type == SPINE_EVENT_TYPE_DISPOSE {
                    dispose_call_count += 1
                }
            }
            let track = spine_animation_state_set_animation_1(animationState, 0, "death", false)!
            let p2 = BlockTrack()
            spine_track_entry_set_block(track) { state, type, entry, event in
                let _ = p2
                a += 1
                if type == SPINE_EVENT_TYPE_COMPLETE {
                    spine_animation_state_clear_tracks(animationState)
                    flag = true

                }
                if type == SPINE_EVENT_TYPE_DISPOSE {
                    dispose_call_count += 1
                }
            }
            for _ in 0..<100 {
                let delta = 1 as Float
                spine_animation_state_update(animationState, delta)
                spine_animation_state_apply(animationState, skeleton)
                spine_skeleton_update(skeleton, delta)
                spine_skeleton_update_world_transform(skeleton, SPINE_PHYSICS_UPDATE)
                if flag {
                    break
                }
            }
            #expect(a == 7)
            #expect(flag == true)
            #expect(dispose_call_count == 2)
        }
        spine_report_leaks()
    }
}
