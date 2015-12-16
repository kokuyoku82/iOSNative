using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.Serialization.Formatters.Binary;
using System.IO;
using System;

public static class FaceTexture {

	public static Texture2D LoadTexure(int width, int height, string filePath)
	{
		Texture2D texture = new Texture2D(width, height);
		
		FileStream fs = new FileStream(filePath, FileMode.Open, FileAccess.Read);
		byte[] imageData = new byte[fs.Length];
		fs.Read(imageData, 0, (int)fs.Length);
		texture.LoadImage(imageData);
		fs.Close();

		return texture;
	}

	// If www got the texture from the filePath, the function successHandler is called.
	// If www has error or www.texture is null, the function errorHandler is called.
	public static IEnumerator LoadTextureFromFilePath( string filePath, Action<Texture2D> successHandler, Action<string> errorHandler )
	{
		using( WWW www = new WWW( filePath ) )
		{
			yield return www;
			
			if( !string.IsNullOrEmpty( www.error ) ){
				if( errorHandler != null ){
					errorHandler( www.error );
				}
			}
			
			Texture2D texture = www.texture;
			
			if( texture != null ){
				successHandler( texture );
			}
			else{
				errorHandler( "www.texture is null. Please check the type of file." );
			}
		}
	}

}
