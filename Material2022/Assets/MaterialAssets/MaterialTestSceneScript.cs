using UnityEngine;
using UnityEngine.UI;

public class MaterialTestSceneScript : MonoBehaviour
{
    #region Dependencies

    public static MaterialTestSceneScript Instance { get; private set; }

    #endregion Dependencies

    public Camera ScreenshotCamera;

    public RawImage RawMinikinScreenshotImage;

    public RawImage FinalImage;

    public Material MinipicLayerBlenderMaterial;

    public Texture2D BottomLayerTexture;

    public Texture2D TopLayerTexture;

    private void Awake()
    {
        Instance = this;
    }

    public void TakeScreenshot()
    {
        RawMinikinScreenshotImage.texture = TakeMinikinScreenshot();
    }

    public void TakeMinipic()
    {
        var minikinScreenshot = TakeMinikinScreenshot();
        RenderTexture textureOutput = new(minikinScreenshot.height, minikinScreenshot.width, 16);

        MinipicLayerBlenderMaterial.SetTexture("_BgTex", BottomLayerTexture);
        MinipicLayerBlenderMaterial.SetTexture("_MainTex", minikinScreenshot);
        MinipicLayerBlenderMaterial.SetTexture("_FgTex", TopLayerTexture);

        Graphics.Blit(null, textureOutput, MinipicLayerBlenderMaterial);

        FinalImage.texture = textureOutput;
    }

    private Texture2D TakeMinikinScreenshot()
    {
        Texture2D rawMinikinScreenshot = new(ScreenshotCamera.activeTexture.width, ScreenshotCamera.activeTexture.height);
        RenderTexture.active = ScreenshotCamera.activeTexture;

        ScreenshotCamera.Render();

        rawMinikinScreenshot.ReadPixels(new Rect(0, 0, ScreenshotCamera.activeTexture.width, ScreenshotCamera.activeTexture.height), 0, 0);
        rawMinikinScreenshot.Apply();

        RawMinikinScreenshotImage.texture = rawMinikinScreenshot;

        return rawMinikinScreenshot;
    }
}
