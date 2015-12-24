using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;

public class iOSNativeCamera : MonoBehaviour {
	#if UNITY_IOS
	public delegate void OnTakePhoto (string imagePath);
	public static OnTakePhoto onTakePhotoDel = null;
	private static string objectName;

	void Start(){
		objectName = this.gameObject.name;
		print (objectName);
	}

	/**
     呼叫 _ShowCameraView 可把客製化layout的iOS原生相機喚醒
     同時要指定callback目標的gameObject名稱及method name
     callback只有一個參數，呼叫時間為使用者拍攝或選取完照片，取消拍攝則不會呼叫
     參數內容為拍照後圖檔的存放路徑，如果內容為空字串時，代表存檔失敗
     */

	// objectName is the same as the name of object added this component.
	[DllImport ("__Internal")]
	private static extern void _ShowCameraView (string objectName, string methodName, bool showHelp=false);
	
	public static void TakePhoto () {
		if (Application.platform == RuntimePlatform.IPhonePlayer) {
			print ("iOS");
			_ShowCameraView (objectName, "receiveFacePath");
		}
	}
	
	void receiveFacePath(string imagePath) {
		if (imagePath != null && imagePath.Length > 0) {
			print ("success, path: " + imagePath);
			if(onTakePhotoDel != null)
				onTakePhotoDel(imagePath);
		} else {
			print ("error");
		}
	}
	#endif
}