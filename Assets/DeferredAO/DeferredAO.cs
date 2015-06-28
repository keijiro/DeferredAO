using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class DeferredAO : MonoBehaviour
{
    [SerializeField]
    float _radius = 1;

    [SerializeField]
    float _intensity = 1;

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

        //var occ = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.R8);
        //var rt1 = RenderTexture.GetTemporary(source.width / 4, source.height / 4, 0, RenderTextureFormat.R8);
        //var rt2 = RenderTexture.GetTemporary(source.width / 4, source.height / 4, 0, RenderTextureFormat.R8);

        var occ = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.R8);
        var rt1 = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.R8);
        var rt2 = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.R8);

        _material.SetFloat("_Radius", _radius);
        _material.SetFloat("_Intensity", _intensity);
        _material.SetFloat("_FallOff", _fallOff);

        var proj = GetComponent<Camera>().projectionMatrix;
        _material.SetMatrix("_Projection", proj);

        Graphics.Blit(source, occ, _material, 0);

        //Graphics.Blit(occ, rt1, _material, 1);
        //Graphics.Blit(rt1, rt2, _material, 2);
        //Graphics.Blit(rt2, rt1, _material, 3);
        //_material.SetTexture("_OccTex", rt1);
        _material.SetTexture("_OccTex", occ);

        //Graphics.Blit(occ, rt2, _material, 2);
        //Graphics.Blit(rt2, rt1, _material, 3);
        //_material.SetTexture("_OccTex", rt1);

        Graphics.Blit(source, destination, _material, 4);

        RenderTexture.ReleaseTemporary(occ);
        RenderTexture.ReleaseTemporary(rt1);
        RenderTexture.ReleaseTemporary(rt2);
    }
}
