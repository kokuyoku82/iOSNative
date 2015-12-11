using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.Serialization.Formatters.Binary;
using System.IO;
using System;

public static class FaceTexture {

	public static Texture2D LoadTexure(int width, int height, string filePath) {
		Texture2D texture = new Texture2D(width, height);
		
		FileStream fs = new FileStream(filePath, FileMode.Open, FileAccess.Read);
		byte[] imageData = new byte[fs.Length];
		fs.Read(imageData, 0, (int)fs.Length);
		texture.LoadImage(imageData);
		fs.Close();

		return texture;
	}

	public static IEnumerator LoadTextureFromFilePath( string filePath, Action<Texture2D> del, Action<string> errorDel )
	{
		using( WWW www = new WWW( filePath ) )
		{
			yield return www;
			
			if( !string.IsNullOrEmpty( www.error ) )
			{
				if( errorDel != null )
					errorDel( www.error );
			}
			
			Texture2D tex = www.texture;
			
			if( tex != null )
				del( tex );
			else
				errorDel( "www.texture is null." );
		}
	}

}
