/******************************************************************************
 * Spine Runtimes License Agreement
 * Last updated April 5, 2025. Replaces all prior versions.
 *
 * Copyright (c) 2013-2025, Esoteric Software LLC
 *
 * Integration of the Spine Runtimes into software or otherwise creating
 * derivative works of the Spine Runtimes is permitted under the terms and
 * conditions of Section 2 of the Spine Editor License Agreement:
 * http://esotericsoftware.com/spine-editor-license
 *
 * Otherwise, it is permitted to integrate the Spine Runtimes into software
 * or otherwise create derivative works of the Spine Runtimes (collectively,
 * "Products"), provided that each user of the Products must obtain their own
 * Spine Editor license and redistribution of the Products in any form must
 * include this license and copyright notice.
 *
 * THE SPINE RUNTIMES ARE PROVIDED BY ESOTERIC SOFTWARE LLC "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL ESOTERIC SOFTWARE LLC BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES,
 * BUSINESS INTERRUPTION, OR LOSS OF USE, DATA, OR PROFITS) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THE SPINE RUNTIMES, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

#if UNITY_2018_3 || UNITY_2019 || UNITY_2018_3_OR_NEWER
#define NEW_PREFAB_SYSTEM
#endif

#if UNITY_2018_2_OR_NEWER
#define HAS_CULL_TRANSPARENT_MESH
#endif

#if UNITY_2017_2_OR_NEWER
#define NEWPLAYMODECALLBACKS
#endif

using UnityEditor;
using UnityEngine;

namespace Spine.Unity.Editor {
	using Icons = SpineEditorUtilities.Icons;

	[CustomEditor(typeof(SkeletonGraphic))]
	[CanEditMultipleObjects]

	public class SkeletonGraphicInspector : ISkeletonRendererInspector {

		protected SerializedProperty material, color;
		protected SerializedProperty additiveMaterial, multiplyMaterial, screenMaterial;
		protected SerializedProperty freeze;
		protected SerializedProperty allowMultipleCanvasRenderers,
			updateSeparatorPartLocation, updateSeparatorPartScale;
		protected SerializedProperty raycastTarget, maskable;
		protected SerializedProperty layoutScaleMode, editReferenceRect;

		protected GUIContent allowMultipleCanvasRenderersLabel, updateSeparatorPartLocationLabel,
			updateSeparatorPartScaleLabel;

		protected SkeletonGraphic thisSkeletonGraphic;

		protected override void OnEnable () {
			base.OnEnable();

			// Labels
			allowMultipleCanvasRenderersLabel = new GUIContent("Multiple CanvasRenderers",
				"When set to true, SkeletonGraphic no longer uses a single CanvasRenderer" +
				"but automatically creates the required number of child CanvasRenderer" +
				"GameObjects for each required draw call (submesh).");
			updateSeparatorPartLocationLabel = new GUIContent("Update Part Location",
				"Update separator part GameObject location to match the position of the SkeletonGraphic. " +
				"This can be helpful when re-parenting parts to a different GameObject.");
			updateSeparatorPartScaleLabel = new GUIContent("Update Part Scale",
				"Update separator part GameObject scale to match the scale (lossyScale) of the SkeletonGraphic. " +
				"This can be helpful when re-parenting parts to a different GameObject.");

			// Properties
			thisSkeletonGraphic = target as SkeletonGraphic;

			// MaskableGraphic
			material = serializedObject.FindProperty("m_Material");
			color = serializedObject.FindProperty("m_SkeletonColor");
			raycastTarget = serializedObject.FindProperty("m_RaycastTarget");
			maskable = serializedObject.FindProperty("m_Maskable");

			// SkeletonGraphic
			additiveMaterial = serializedObject.FindProperty("additiveMaterial");
			multiplyMaterial = serializedObject.FindProperty("multiplyMaterial");
			screenMaterial = serializedObject.FindProperty("screenMaterial");
			freeze = serializedObject.FindProperty("freeze");
			allowMultipleCanvasRenderers = serializedObject.FindProperty("allowMultipleCanvasRenderers");
			updateSeparatorPartLocation = serializedObject.FindProperty("updateSeparatorPartLocation");
			updateSeparatorPartScale = serializedObject.FindProperty("updateSeparatorPartScale");
			layoutScaleMode = serializedObject.FindProperty("layoutScaleMode");
			editReferenceRect = serializedObject.FindProperty("editReferenceRect");

#if NEWPLAYMODECALLBACKS
			EditorApplication.playModeStateChanged += OnPlaymodeChanged;
#else
			EditorApplication.playmodeStateChanged += OnPlaymodeChanged;
#endif
		}

		void OnDisable () {
#if NEWPLAYMODECALLBACKS
			EditorApplication.playModeStateChanged -= OnPlaymodeChanged;
#else
			EditorApplication.playmodeStateChanged -= OnPlaymodeChanged;
#endif
			DisableEditReferenceRectMode();
		}

#if NEWPLAYMODECALLBACKS
		void OnPlaymodeChanged (PlayModeStateChange mode) {
#else
		void OnPlaymodeChanged () {
#endif
			DisableEditReferenceRectMode();
		}

		void DisableEditReferenceRectMode () {
			foreach (UnityEngine.Object c in targets) {
				SkeletonGraphic component = c as SkeletonGraphic;
				if (component == null) continue;
				component.EditReferenceRect = false;
			}
		}



		protected override void FirstPropertyFields () {
			using (new SpineInspectorUtility.LabelWidthScope(100)) {
				using (new EditorGUILayout.HorizontalScope()) {
					EditorGUILayout.PropertyField(material);
					if (GUILayout.Button("Detect", EditorStyles.miniButton, GUILayout.Width(67f))) {
						Undo.RecordObjects(targets, "Detect Material");
						foreach (UnityEngine.Object target in targets) {
							SkeletonGraphic skeletonGraphic = target as SkeletonGraphic;
							if (skeletonGraphic == null) continue;
							DetectMaterial(skeletonGraphic);
						}
					}
				}
				EditorGUILayout.PropertyField(color);
			}
		}

		protected override void MaterialWarningsBox () {
			string errorMessage = null;
			if (SpineEditorUtilities.Preferences.componentMaterialWarning &&
				MaterialChecks.IsMaterialSetupProblematic(thisSkeletonGraphic, ref errorMessage)) {
				EditorGUILayout.HelpBox(errorMessage, MessageType.Error, true);
			}
		}

		protected override void VertexDataProperties () {
			using (new EditorGUILayout.HorizontalScope()) {
				EditorGUILayout.PropertyField(tintBlack, TintBlackLabel);
				if (GUILayout.Button("Detect", EditorStyles.miniButton, GUILayout.Width(65f))) {
					Undo.RecordObjects(targets, "Detect Tint Black");
					foreach (UnityEngine.Object target in targets) {
						SkeletonGraphic skeletonGraphic = target as SkeletonGraphic;
						if (skeletonGraphic == null) continue;
						DetectTintBlack(skeletonGraphic);
					}
				}
			}
			using (new EditorGUILayout.HorizontalScope()) {
				EditorGUILayout.PropertyField(canvasGroupCompatible, CanvasGroupCompatibleLabel);
				if (GUILayout.Button("Detect", EditorStyles.miniButton, GUILayout.Width(65f))) {
					Undo.RecordObjects(targets, "Detect CanvasGroup Compatible");
					foreach (UnityEngine.Object target in targets) {
						SkeletonGraphic skeletonGraphic = target as SkeletonGraphic;
						if (skeletonGraphic == null) continue;
						DetectCanvasGroupCompatible(skeletonGraphic);
					}
				}
			}
			using (new EditorGUILayout.HorizontalScope()) {
				EditorGUILayout.PropertyField(pmaVertexColors, PMAVertexColorsLabel);
				if (GUILayout.Button("Detect", EditorStyles.miniButton, GUILayout.Width(65f))) {
					Undo.RecordObjects(targets, "Detect PMA Vertex Colors");
					foreach (UnityEngine.Object target in targets) {
						SkeletonGraphic skeletonGraphic = target as SkeletonGraphic;
						if (skeletonGraphic == null) continue;
						DetectPMAVertexColors(skeletonGraphic);
					}
				}
			}
			using (new EditorGUILayout.HorizontalScope()) {
				GUILayout.FlexibleSpace();
				if (GUILayout.Button("Detect Settings", EditorStyles.miniButton, GUILayout.Width(100f))) {
					Undo.RecordObjects(targets, "Detect Settings");
					foreach (UnityEngine.Object target in targets) {
						SkeletonGraphic skeletonGraphic = target as SkeletonGraphic;
						if (skeletonGraphic == null) continue;
						DetectTintBlack(skeletonGraphic);
						DetectCanvasGroupCompatible(skeletonGraphic);
						DetectPMAVertexColors(skeletonGraphic);
					}
				}
				if (GUILayout.Button("Detect Material", EditorStyles.miniButton, GUILayout.Width(100f))) {
					Undo.RecordObjects(targets, "Detect Material");
					foreach (UnityEngine.Object target in targets) {
						SkeletonGraphic skeletonGraphic = target as SkeletonGraphic;
						if (skeletonGraphic == null) continue;
						DetectMaterial(skeletonGraphic);
					}
				}
			}

			EditorGUILayout.PropertyField(addNormals, AddNormalsLabel);
			EditorGUILayout.PropertyField(calculateTangents, CalculateTangentsLabel);
			EditorGUILayout.PropertyField(immutableTriangles, ImmutableTrianglesLabel);
		}

		protected override void AdvancedPropertyFields () {

			bool isSingleRendererOnly = (!allowMultipleCanvasRenderers.hasMultipleDifferentValues && allowMultipleCanvasRenderers.boolValue == false);
			bool isSeparationEnabledButNotMultipleRenderers =
				 isSingleRendererOnly && (!enableSeparatorSlots.hasMultipleDifferentValues && enableSeparatorSlots.boolValue == true);
			bool meshRendersIncorrectlyWithSingleRenderer =
				isSingleRendererOnly && SkeletonHasMultipleSubmeshes();

			if (isSeparationEnabledButNotMultipleRenderers || meshRendersIncorrectlyWithSingleRenderer)
				advancedFoldout = true;

			base.AdvancedPropertyFields();

			if (advancedFoldout) {
				EditorGUILayout.Space();
				using (new SpineInspectorUtility.IndentScope()) {
					EditorGUILayout.BeginHorizontal();
					EditorGUILayout.PropertyField(allowMultipleCanvasRenderers, allowMultipleCanvasRenderersLabel);

					if (GUILayout.Button(new GUIContent("Trim Renderers", "Remove currently unused CanvasRenderer GameObjects. These will be regenerated whenever needed."),
						EditorStyles.miniButton, GUILayout.Width(100f))) {

						Undo.RecordObjects(targets, "Trim Renderers");
						foreach (UnityEngine.Object target in targets) {
							SkeletonGraphic skeletonGraphic = target as SkeletonGraphic;
							if (skeletonGraphic == null) continue;
							skeletonGraphic.TrimRenderers();
						}
					}
					EditorGUILayout.EndHorizontal();

					BlendModeMaterials blendModeMaterials = thisSkeletonGraphic.skeletonDataAsset.blendModeMaterials;
					if (allowMultipleCanvasRenderers.boolValue == true && blendModeMaterials.RequiresBlendModeMaterials) {
						using (new SpineInspectorUtility.IndentScope()) {
							EditorGUILayout.BeginHorizontal();
							EditorGUILayout.LabelField("Blend Mode Materials", EditorStyles.boldLabel);

							if (GUILayout.Button(new GUIContent("Detect", "Auto-Assign Blend Mode Materials according to Vertex Data and Texture settings."),
								EditorStyles.miniButton, GUILayout.Width(100f))) {

								Undo.RecordObjects(targets, "Detect Blend Mode Materials");
								foreach (UnityEngine.Object target in targets) {
									SkeletonGraphic skeletonGraphic = target as SkeletonGraphic;
									if (skeletonGraphic == null) continue;
									DetectBlendModeMaterials(skeletonGraphic);
								}
							}
							EditorGUILayout.EndHorizontal();

							bool usesAdditiveMaterial = blendModeMaterials.applyAdditiveMaterial;
							bool pmaVertexColors = thisSkeletonGraphic.MeshSettings.pmaVertexColors;
							if (pmaVertexColors)
								using (new EditorGUI.DisabledGroupScope(true)) {
									EditorGUILayout.LabelField("Additive Material - Unused with PMA Vertex Colors", EditorStyles.label);
								}
							else if (usesAdditiveMaterial)
								EditorGUILayout.PropertyField(additiveMaterial, SpineInspectorUtility.TempContent("Additive Material", null, "SkeletonGraphic Material for 'Additive' blend mode slots. Unused when 'PMA Vertex Colors' is enabled."));
							else
								using (new EditorGUI.DisabledGroupScope(true)) {
									EditorGUILayout.LabelField("No Additive Mat - 'Apply Additive Material' disabled at SkeletonDataAsset", EditorStyles.label);
								}
							EditorGUILayout.PropertyField(multiplyMaterial, SpineInspectorUtility.TempContent("Multiply Material", null, "SkeletonGraphic Material for 'Multiply' blend mode slots."));
							EditorGUILayout.PropertyField(screenMaterial, SpineInspectorUtility.TempContent("Screen Material", null, "SkeletonGraphic Material for 'Screen' blend mode slots."));
						}
					}


					// warning box
					if (isSeparationEnabledButNotMultipleRenderers) {
						using (new SpineInspectorUtility.BoxScope()) {
							meshSettings.isExpanded = true;
							EditorGUILayout.LabelField(SpineInspectorUtility.TempContent("'Multiple Canvas Renderers' must be enabled\nwhen 'Enable Separation' is enabled.", Icons.warning), GUILayout.Height(42), GUILayout.Width(340));
						}
					} else if (meshRendersIncorrectlyWithSingleRenderer) {
						using (new SpineInspectorUtility.BoxScope()) {
							meshSettings.isExpanded = true;
							EditorGUILayout.LabelField(SpineInspectorUtility.TempContent("This mesh uses multiple atlas pages or blend modes.\n" +
																						"You need to enable 'Multiple Canvas Renderers'\n" +
																						"for correct rendering. Consider packing\n" +
																						"attachments to a single atlas page if possible.", Icons.warning), GUILayout.Height(60), GUILayout.Width(340));
						}
					}
				}
			}
		}

		protected override void AfterAdvancedPropertyFields () {

			EditorGUILayout.Space();
			EditorGUILayout.PropertyField(freeze);
			EditorGUILayout.Space();
			EditorGUILayout.LabelField("UI", EditorStyles.boldLabel);
			EditorGUILayout.PropertyField(raycastTarget);
			if (maskable != null) EditorGUILayout.PropertyField(maskable);

			EditorGUILayout.PropertyField(layoutScaleMode);

			using (new EditorGUI.DisabledGroupScope(layoutScaleMode.intValue == 0)) {
				EditorGUILayout.BeginHorizontal(GUILayout.Height(EditorGUIUtility.singleLineHeight + 5));
				EditorGUILayout.PrefixLabel("Edit Layout Bounds");
				editReferenceRect.boolValue = GUILayout.Toggle(editReferenceRect.boolValue,
					EditorGUIUtility.IconContent("EditCollider"), EditorStyles.miniButton, GUILayout.Width(40f));
				EditorGUILayout.EndHorizontal();
			}
			if (layoutScaleMode.intValue == 0) {
				editReferenceRect.boolValue = false;
			}

			using (new EditorGUI.DisabledGroupScope(editReferenceRect.boolValue == false && layoutScaleMode.intValue != 0)) {
				EditorGUILayout.BeginHorizontal(GUILayout.Height(EditorGUIUtility.singleLineHeight + 5));
				EditorGUILayout.PrefixLabel("Match RectTransform with Mesh");
				if (GUILayout.Button("Match", EditorStyles.miniButton, GUILayout.Width(65f))) {
					foreach (UnityEngine.Object target in targets) {
						SkeletonGraphic skeletonGraphic = target as SkeletonGraphic;
						if (skeletonGraphic == null) continue;
						MatchRectTransformWithBounds(skeletonGraphic);
					}
				}
				EditorGUILayout.EndHorizontal();
			}
		}

		protected bool SkeletonHasMultipleSubmeshes () {
			foreach (UnityEngine.Object target in targets) {
				SkeletonGraphic skeletonGraphic = target as SkeletonGraphic;
				if (skeletonGraphic == null) continue;
				if (skeletonGraphic.HasMultipleSubmeshInstructions())
					return true;
			}
			return false;
		}

		protected override void AdditionalSeparatorSlotProperties () {
			EditorGUILayout.PropertyField(updateSeparatorPartLocation, updateSeparatorPartLocationLabel);
			EditorGUILayout.PropertyField(updateSeparatorPartScale, updateSeparatorPartScaleLabel);
		}

		public override void OnSceneGUI () {
			base.OnSceneGUI();

			SkeletonGraphic skeletonGraphic = (SkeletonGraphic)target;

			if (skeletonGraphic.layoutScaleMode != SkeletonGraphic.LayoutMode.None) {
				if (skeletonGraphic.EditReferenceRect) {
					SpineHandles.DrawRectTransformRect(skeletonGraphic, Color.gray);
					SpineHandles.DrawReferenceRect(skeletonGraphic, Color.green);
				} else {
					SpineHandles.DrawReferenceRect(skeletonGraphic, Color.blue);
				}
			}
			SpineHandles.DrawPivotOffsetHandle(skeletonGraphic, Color.green);
		}

		#region Auto Detect Setting
		static void DetectTintBlack (SkeletonGraphic skeletonGraphic) {
			bool requiresTintBlack = HasTintBlackSlot(skeletonGraphic);
			if (requiresTintBlack)
				Debug.Log(string.Format("Found Tint-Black slot at '{0}'", skeletonGraphic));
			else
				Debug.Log(string.Format("No Tint-Black slot found at '{0}'", skeletonGraphic));
			skeletonGraphic.MeshSettings.tintBlack = requiresTintBlack;
		}

		static bool HasTintBlackSlot (SkeletonGraphic skeletonGraphic) {
			SlotData[] slotsItems = skeletonGraphic.SkeletonData.Slots.Items;
			for (int i = 0, count = skeletonGraphic.SkeletonData.Slots.Count; i < count; ++i) {
				SlotData slotData = slotsItems[i];
				if (slotData.GetSetupPose().GetDarkColor().HasValue)
					return true;
			}
			return false;
		}

		static void DetectCanvasGroupCompatible (SkeletonGraphic skeletonGraphic) {
			bool requiresCanvasGroupCompatible = IsBelowCanvasGroup(skeletonGraphic);
			if (requiresCanvasGroupCompatible)
				Debug.Log(string.Format("Skeleton is a child of CanvasGroup: '{0}'", skeletonGraphic));
			else
				Debug.Log(string.Format("Skeleton is not a child of CanvasGroup: '{0}'", skeletonGraphic));
			skeletonGraphic.MeshSettings.canvasGroupCompatible = requiresCanvasGroupCompatible;
		}

		static bool IsBelowCanvasGroup (SkeletonGraphic skeletonGraphic) {
			return skeletonGraphic.gameObject.GetComponentInParent<CanvasGroup>() != null;
		}

		static void DetectPMAVertexColors (SkeletonGraphic skeletonGraphic) {
			MeshGenerator.Settings settings = skeletonGraphic.MeshSettings;
			bool usesSpineShader = MaterialChecks.UsesSpineShader(skeletonGraphic.material);
			if (!usesSpineShader) {
				Debug.Log(string.Format("Skeleton is not using a Spine shader, thus the shader is likely " +
					"not using PMA vertex color: '{0}'", skeletonGraphic));
				skeletonGraphic.MeshSettings.pmaVertexColors = false;
				return;
			}

			bool requiresPMAVertexColorsDisabled = settings.canvasGroupCompatible && !settings.tintBlack;
			if (requiresPMAVertexColorsDisabled) {
				Debug.Log(string.Format("Skeleton requires PMA Vertex Colors disabled: '{0}'", skeletonGraphic));
				skeletonGraphic.MeshSettings.pmaVertexColors = false;
			} else {
				Debug.Log(string.Format("Skeleton requires or permits PMA Vertex Colors enabled: '{0}'", skeletonGraphic));
				skeletonGraphic.MeshSettings.pmaVertexColors = true;
			}
		}

		static bool IsSkeletonTexturePMA (SkeletonGraphic skeletonGraphic, out bool detectionSucceeded) {
			Texture texture = skeletonGraphic.mainTexture;
			string texturePath = AssetDatabase.GetAssetPath(texture.GetInstanceID());
			TextureImporter importer = (TextureImporter)TextureImporter.GetAtPath(texturePath);
			if (importer.alphaIsTransparency != importer.sRGBTexture) {
				Debug.LogWarning(string.Format("Texture '{0}' at skeleton '{1}' is neither configured correctly for " +
					"PMA nor Straight Alpha.", texture, skeletonGraphic), texture);
				detectionSucceeded = false;
				return false;
			}
			detectionSucceeded = true;
			bool isPMATexture = !importer.alphaIsTransparency && !importer.sRGBTexture;
			return isPMATexture;
		}

		static void DetectMaterial (SkeletonGraphic skeletonGraphic) {
			MeshGenerator.Settings settings = skeletonGraphic.MeshSettings;

			bool detectionSucceeded;
			bool usesPMATexture = IsSkeletonTexturePMA(skeletonGraphic, out detectionSucceeded);
			if (!detectionSucceeded) {
				Debug.LogWarning(string.Format("Unable to assign Material for skeleton '{0}'.", skeletonGraphic), skeletonGraphic);
				return;
			}

			Material newMaterial = null;
			if (usesPMATexture) {
				if (settings.tintBlack) {
					if (settings.canvasGroupCompatible)
						newMaterial = MaterialWithName("SkeletonGraphicTintBlack-CanvasGroup");
					else
						newMaterial = MaterialWithName("SkeletonGraphicTintBlack");
				} else { // not tintBlack
					if (settings.canvasGroupCompatible)
						newMaterial = MaterialWithName("SkeletonGraphicDefault-CanvasGroup");
					else
						newMaterial = MaterialWithName("SkeletonGraphicDefault");
				}
			} else { // straight alpha texture
				if (settings.tintBlack) {
					if (settings.canvasGroupCompatible)
						newMaterial = MaterialWithName("SkeletonGraphicTintBlack-CanvasGroupStraight");
					else
						newMaterial = MaterialWithName("SkeletonGraphicTintBlack-Straight");
				} else { // not tintBlack
					if (settings.canvasGroupCompatible)
						newMaterial = MaterialWithName("SkeletonGraphicDefault-CanvasGroupStraight");
					else
						newMaterial = MaterialWithName("SkeletonGraphicDefault-Straight");
				}
			}
			if (newMaterial != null) {
				Debug.Log(string.Format("Assigning material '{0}' at skeleton '{1}'",
					newMaterial, skeletonGraphic), newMaterial);
				skeletonGraphic.material = newMaterial;
			}
		}

		static void DetectBlendModeMaterials (SkeletonGraphic skeletonGraphic) {
			bool detectionSucceeded;
			bool usesPMATexture = IsSkeletonTexturePMA(skeletonGraphic, out detectionSucceeded);
			if (!detectionSucceeded) {
				Debug.LogWarning(string.Format("Unable to assign Blend Mode materials for skeleton '{0}'.", skeletonGraphic), skeletonGraphic);
				return;
			}
			DetectBlendModeMaterial(skeletonGraphic, BlendMode.Additive, usesPMATexture);
			DetectBlendModeMaterial(skeletonGraphic, BlendMode.Multiply, usesPMATexture);
			DetectBlendModeMaterial(skeletonGraphic, BlendMode.Screen, usesPMATexture);
		}

		static void DetectBlendModeMaterial (SkeletonGraphic skeletonGraphic, BlendMode blendMode, bool usesPMATexture) {
			MeshGenerator.Settings settings = skeletonGraphic.MeshSettings;

			string optionalTintBlack = settings.tintBlack ? "TintBlack" : "";
			string blendModeString = blendMode.ToString();
			string optionalDash = settings.canvasGroupCompatible || !usesPMATexture ? "-" : "";
			string optionalCanvasGroup = settings.canvasGroupCompatible ? "CanvasGroup" : "";
			string optionalStraight = !usesPMATexture ? "Straight" : "";

			string materialName = string.Format("SkeletonGraphic{0}{1}{2}{3}{4}",
				optionalTintBlack, blendModeString, optionalDash, optionalCanvasGroup, optionalStraight);
			Material newMaterial = MaterialWithName(materialName);

			if (newMaterial != null) {
				switch (blendMode) {
				case BlendMode.Additive:
					skeletonGraphic.additiveMaterial = newMaterial;
					break;
				case BlendMode.Multiply:
					skeletonGraphic.multiplyMaterial = newMaterial;
					break;
				case BlendMode.Screen:
					skeletonGraphic.screenMaterial = newMaterial;
					break;
				}
			}
		}
		#endregion

		#region Menus
		[MenuItem("CONTEXT/SkeletonGraphic/Match RectTransform with Mesh Bounds")]
		static void MatchRectTransformWithBounds (MenuCommand command) {
			SkeletonGraphic skeletonGraphic = (SkeletonGraphic)command.context;
			MatchRectTransformWithBounds(skeletonGraphic);
		}

		static void MatchRectTransformWithBounds (SkeletonGraphic skeletonGraphic) {
			if (!skeletonGraphic.MatchRectTransformWithBounds())
				Debug.Log("Mesh was not previously generated.");
		}

		[MenuItem("GameObject/Spine/SkeletonGraphic (UnityUI)", false, 15)]
		static public void SkeletonGraphicCreateMenuItem () {
			GameObject parentGameObject = Selection.activeObject as GameObject;
			RectTransform parentTransform = parentGameObject == null ? null : parentGameObject.GetComponent<RectTransform>();

			if (parentTransform == null)
				Debug.LogWarning("Your new SkeletonGraphic will not be visible until it is placed under a Canvas");

			GameObject gameObject = NewSkeletonGraphicGameObject("New SkeletonGraphic", typeof(SkeletonAnimation));
			gameObject.transform.SetParent(parentTransform, false);
			EditorUtility.FocusProjectWindow();
			Selection.activeObject = gameObject;
			EditorGUIUtility.PingObject(Selection.activeObject);
		}

		// SpineEditorUtilities.InstantiateDelegate. Used by drag and drop.
		public static Component SpawnSkeletonGraphicFromDrop (SkeletonDataAsset data) {
			return InstantiateSkeletonGraphic(data);
		}

		public static SkeletonGraphic InstantiateSkeletonGraphic (SkeletonDataAsset skeletonDataAsset, string skinName) {
			return InstantiateSkeletonGraphic(skeletonDataAsset, skeletonDataAsset.GetSkeletonData(true).FindSkin(skinName));
		}

		public static SkeletonGraphic InstantiateSkeletonGraphic (SkeletonDataAsset skeletonDataAsset, Skin skin = null) {
			string spineGameObjectName = string.Format("SkeletonGraphic ({0})", skeletonDataAsset.name.Replace("_SkeletonData", ""));
			GameObject go = NewSkeletonGraphicGameObject(spineGameObjectName, typeof(SkeletonAnimation));
			SkeletonGraphic graphic = go.GetComponent<SkeletonGraphic>();
			SkeletonAnimation animation = go.GetComponent<SkeletonAnimation>();
			graphic.skeletonDataAsset = skeletonDataAsset;

			SkeletonData data = skeletonDataAsset.GetSkeletonData(true);

			if (data == null) {
				for (int i = 0; i < skeletonDataAsset.atlasAssets.Length; i++) {
					string reloadAtlasPath = AssetDatabase.GetAssetPath(skeletonDataAsset.atlasAssets[i]);
					skeletonDataAsset.atlasAssets[i] = (AtlasAssetBase)AssetDatabase.LoadAssetAtPath(reloadAtlasPath, typeof(AtlasAssetBase));
				}

				data = skeletonDataAsset.GetSkeletonData(true);
			}

			skin = skin ?? data.DefaultSkin ?? data.Skins.Items[0];
			graphic.MeshSettings.zSpacing = SpineEditorUtilities.Preferences.defaultZSpacing;

			animation.loop = SpineEditorUtilities.Preferences.defaultInstantiateLoop;
			graphic.Initialize(false);
			animation.Initialize(false);
			if (skin != null) graphic.Skeleton.SetSkin(skin);
			graphic.initialSkinName = skin.Name;
			graphic.Skeleton.UpdateWorldTransform(Physics.Update);
			graphic.UpdateMesh();
			return graphic;
		}

		static GameObject NewSkeletonGraphicGameObject (string gameObjectName, System.Type animationComponentType) {
			GameObject go = EditorInstantiation.NewGameObject(gameObjectName, true, typeof(RectTransform),
				typeof(CanvasRenderer), typeof(SkeletonGraphic));
			// Note: SkeletonAnimation component was already implicitly added by
			// SkeletonGraphic.Awake() above, calling UpgradeTo43Components().
			if (go.GetComponent(animationComponentType) == null)
				EditorInstantiation.AddComponent(go, true, animationComponentType);

			SkeletonGraphic graphic = go.GetComponent<SkeletonGraphic>();
			graphic.material = SkeletonGraphicInspector.DefaultSkeletonGraphicMaterial;
			graphic.additiveMaterial = SkeletonGraphicInspector.DefaultSkeletonGraphicAdditiveMaterial;
			graphic.multiplyMaterial = SkeletonGraphicInspector.DefaultSkeletonGraphicMultiplyMaterial;
			graphic.screenMaterial = SkeletonGraphicInspector.DefaultSkeletonGraphicScreenMaterial;

#if HAS_CULL_TRANSPARENT_MESH
			CanvasRenderer canvasRenderer = go.GetComponent<CanvasRenderer>();
			canvasRenderer.cullTransparentMesh = false;
#endif
			return go;
		}

		public static Material DefaultSkeletonGraphicMaterial {
			get {
				return MaterialWithName(SpineEditorUtilities.Preferences.UsesPMAWorkflow ?
					"SkeletonGraphicDefault" :
					"SkeletonGraphicDefault-Straight");
			}
		}

		public static Material DefaultSkeletonGraphicAdditiveMaterial {
			get {
				return MaterialWithName(SpineEditorUtilities.Preferences.UsesPMAWorkflow ?
					"SkeletonGraphicAdditive" :
					"SkeletonGraphicAdditive-Straight");
			}
		}

		public static Material DefaultSkeletonGraphicMultiplyMaterial {
			get {
				return MaterialWithName(SpineEditorUtilities.Preferences.UsesPMAWorkflow ?
					"SkeletonGraphicMultiply" :
					"SkeletonGraphicMultiply-Straight");
			}
		}

		public static Material DefaultSkeletonGraphicScreenMaterial {
			get {
				return MaterialWithName(SpineEditorUtilities.Preferences.UsesPMAWorkflow ?
					"SkeletonGraphicScreen" :
					"SkeletonGraphicScreen-Straight");
			}
		}

		protected static Material MaterialWithName (string name) {
			string[] guids = AssetDatabase.FindAssets(name + " t:material");
			if (guids.Length <= 0) return null;

			int closestNameDistance = int.MaxValue;
			int closestNameIndex = 0;
			for (int i = 0; i < guids.Length; ++i) {
				string assetPath = AssetDatabase.GUIDToAssetPath(guids[i]);
				string assetName = System.IO.Path.GetFileNameWithoutExtension(assetPath);
				int distance = string.CompareOrdinal(assetName, name);
				if (distance < closestNameDistance) {
					closestNameDistance = distance;
					closestNameIndex = i;
				}
			}

			string foundAssetPath = AssetDatabase.GUIDToAssetPath(guids[closestNameIndex]);
			if (string.IsNullOrEmpty(foundAssetPath)) return null;

			Material firstMaterial = AssetDatabase.LoadAssetAtPath<Material>(foundAssetPath);
			return firstMaterial;
		}

		#endregion
	}
}
