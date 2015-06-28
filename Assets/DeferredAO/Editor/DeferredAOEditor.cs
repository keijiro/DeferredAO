using UnityEngine;
using UnityEditor;

[CanEditMultipleObjects]
[CustomEditor(typeof(DeferredAO))]
public class DeferredAOEditor : Editor
{
    SerializedProperty _intensity;
    SerializedProperty _sampleRadius;
    SerializedProperty _rangeCheck;
    SerializedProperty _fallOffDistance;
    SerializedProperty _sampleCount;

    void OnEnable()
    {
        _intensity = serializedObject.FindProperty("_intensity");
        _sampleRadius = serializedObject.FindProperty("_sampleRadius");
        _rangeCheck = serializedObject.FindProperty("_rangeCheck");
        _fallOffDistance = serializedObject.FindProperty("_fallOffDistance");
        _sampleCount = serializedObject.FindProperty("_sampleCount");
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        EditorGUILayout.PropertyField(_intensity);
        EditorGUILayout.PropertyField(_sampleRadius);
        EditorGUILayout.PropertyField(_rangeCheck);
        EditorGUILayout.PropertyField(_fallOffDistance);
        EditorGUILayout.PropertyField(_sampleCount);

        serializedObject.ApplyModifiedProperties();
    }
}
