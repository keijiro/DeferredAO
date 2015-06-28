using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class DeferredAO : MonoBehaviour
{
    [SerializeField]
    float _radius = 1;

    [SerializeField]
    float _fallOff = 100;

    [SerializeField]
    Shader _shader;

    Material _material;

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_material == null) {
            _material = new Material(_shader);
            _material.hideFlags = HideFlags.DontSave;
        }

        _material.SetFloat("_Radius", _radius);
        _material.SetFloat("_FallOff", _fallOff);

        var proj = GetComponent<Camera>().projectionMatrix;
        _material.SetMatrix("_Projection", proj);

        Graphics.Blit(source, destination, _material);
    }

}
