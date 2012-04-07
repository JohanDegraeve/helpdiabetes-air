package skins
{
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
		
		override protected function createChildren():void {
			image = new Image();
			//Replace the right side below with your source (including URL)
			image.source = (new background() as BitmapAsset);
			image.height = 500; //Set image size here
			image.width = 500;
			this.addChild(image);
			
			super.createChildren();
		}
	}
}