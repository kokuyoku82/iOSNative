using UnityEngine;
using System.Collections;
using UnityEngine.UI;


public class iOSNativeEventListener_Example : MonoBehaviour
{
	private RawImage uiPhotoView;

	void Start(){
		uiPhotoView = GameObject.Find("PhotoView").GetComponent<RawImage>();
		uiPhotoView.rectTransform.sizeDelta = new Vector2(Screen.width, Screen.height);
	}
	
	#if UNITY_IOS
	void OnEnable()
	{
		iOSNativeCamera.onTakePhotoDel += GetImagePath;
	}
	
	void OnDisable()
	{
		iOSNativeCamera.onTakePhotoDel -= GetImagePath;
	}


	public void TakePhoto()
	{
		iOSNativeCamera.TakePhoto();
	}

	
	void GetImagePath( string imagePath )
	{
		Debug.Log( "Get image path: " + imagePath );
		StartCoroutine( FaceTexture.LoadTextureFromFilePath( "file://" + imagePath, LoadedTexture, LoadedTextureFailed ) );
	}

	public void LoadedTexture( Texture2D texture )
	{
		uiPhotoView.texture = texture;
	}
	
	public void LoadedTextureFailed( string error )
	{
		Debug.Log( "Loaded texture failed: " + error );
	}
	#endif
}
