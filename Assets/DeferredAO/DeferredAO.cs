using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class DeferredAO : MonoBehaviour
{
    [SerializeField]
    float _radius = 1;

    [SerializeField]
    float _minimumDistance = 0.001f;

    [SerializeField]
    float _attenuation = 1;

    [SerializeField]
    float _intensity = 1;

    [SerializeField] Shader _shader;

    Material _material;

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_material == null) {
            _material = new Material(_shader);
            _material.hideFlags = HideFlags.DontSave;
        }

        _material.SetFloat("_Radius", _radius); 
        _material.SetVector("_Params", new Vector4(_radius, _minimumDistance, _attenuation, _intensity));

        Graphics.Blit(source, destination, _material);
    }

}
