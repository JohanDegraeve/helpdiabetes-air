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
			//only draw a border line
			graphics.lineStyle(1, 0, 0.75);
			graphics.moveTo(0,unscaledHeight - 1);
			graphics.lineTo(unscaledWidth,unscaledHeight - 1);
			graphics.endFill();
			if (down) {
				graphics.beginFill(0, 0.25);
				graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
				graphics.endFill();
			}
		}
	}
}