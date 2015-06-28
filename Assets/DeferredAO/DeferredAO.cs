using UnityEngine;

[ImageEffectOpaque]
[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class DeferredAO : MonoBehaviour
{
    [SerializeField]
    float _intensity = 1;

    [SerializeField]
    float _sampleRadius = 1;

    [SerializeField]
    bool _rangeCheck = true;

    [SerializeField]
    float _fallOffDistance = 100;

    enum SampleCount { Low, Medium, High, Overkill }

    [SerializeField]
    SampleCount _sampleCount = SampleCount.Medium;

    [SerializeField]
    Shader _shader;

    Material _material;

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_material == null) {
            _material = new Material(_shader);
            _material.hideFlags = HideFlags.DontSave;
        }

        _material.SetFloat("_Radius", _sampleRadius);
        _material.SetFloat("_Intensity", _intensity);
        _material.SetFloat("_FallOff", _fallOffDistance);
        _material.SetMatrix("_Projection", GetComponent<Camera>().projectionMatrix);

        _material.shaderKeywords = null;

        if (_rangeCheck)
            _material.EnableKeyword("_RANGE_CHECK");

        if (_sampleCount == SampleCount.Medium)
            _material.EnableKeyword("_SAMPLE_MEDIUM");
        else if (_sampleCount == SampleCount.High)
            _material.EnableKeyword("_SAMPLE_HIGH");
        else if (_sampleCount == SampleCount.Overkill)
            _material.EnableKeyword("_SAMPLE_OVERKILL");

        Graphics.Blit(source, destination, _material, 0);
    }
}
