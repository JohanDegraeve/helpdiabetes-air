package myComponents
{
	import spark.components.LabelItemRenderer;
	
	public class ListItemRenderer extends LabelItemRenderer
	{
		public function ListItemRenderer()
		{
			super();
		}
		
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			//don't draw anything, goal is that there's no background
		}
	}
}