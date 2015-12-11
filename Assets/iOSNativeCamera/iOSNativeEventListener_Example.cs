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
		iOSNativeCamera.onTakePhotoDel += ImagePickerChoseImage;
	}
	
	void OnDisable()
	{
		iOSNativeCamera.onTakePhotoDel -= ImagePickerChoseImage;
	}


	public void TakePhoto()
	{
		iOSNativeCamera.TakePhoto();
	}

	
	void ImagePickerChoseImage( string imagePath )
	{
		Debug.Log( "image picker chose image: " + imagePath );
		StartCoroutine( FaceTexture.LoadTextureFromFilePath( "file://" + imagePath, TextureLoaded, TextureLoadFailed ) );
	}

	public void TextureLoaded( Texture2D texture )
	{
		uiPhotoView.texture = texture;
	}
	
	public void TextureLoadFailed( string error )
	{
		Debug.Log( "TextureLoadFailed: " + error );
	}
	#endif
}
