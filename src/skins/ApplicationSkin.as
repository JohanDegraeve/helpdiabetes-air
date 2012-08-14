package skins
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	
	import mx.core.BitmapAsset;
	
	import spark.components.Image;
	import spark.skins.mobile.TabbedViewNavigatorApplicationSkin;
	
	public class ApplicationSkin extends TabbedViewNavigatorApplicationSkin
	{
		public function ApplicationSkin()
		{
			super();
		}
		
		private var image:Image;
		
		[Embed(source="assets/bg.png")]
		private var background:Class;
		
		
		override protected function drawBackground(unscaledWidth:Number,unscaledHeight:Number):void {
			  var imageasBitMap:Bitmap = new background();
			//Replace the right side below with your source (including URL)
			var bitmapData : BitmapData = imageasBitMap.bitmapData.clone();
			
			var matrix:Matrix ;
			if (unscaledWidth > imageasBitMap.width || unscaledHeight > imageasBitMap.height) {
				matrix = new Matrix();
				matrix.scale(unscaledWidth/imageasBitMap.width,unscaledHeight/imageasBitMap.height);
			}
			
			graphics.beginBitmapFill(bitmapData,matrix ? matrix:null);
			graphics.drawRect(0,0,unscaledWidth,unscaledHeight);
			graphics.endFill();
		}
	}
}