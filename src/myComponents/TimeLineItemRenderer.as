package myComponents
{
	public class TimeLineItemRenderer extends TrackingViewElementItemRenderer
	{
		public function TimeLineItemRenderer()
		{
			super();
		}
		
		/**
		 * Draw a red line
		 */
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			graphics.beginFill(0xFF0000, 1);
			graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
			graphics.endFill();
		}
		
		override public function getHeight(item:TrackingViewElement = null):Number {
			return 2;//height of such a red line
		}
		
		override protected function createChildren():void {
			//don't want to show anything
		}
	}
}